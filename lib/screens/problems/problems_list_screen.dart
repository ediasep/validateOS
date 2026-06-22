import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/problem_provider.dart';
import '../../theme.dart';
import '../../widgets/pain_score_badge.dart';

class ProblemsListScreen extends ConsumerStatefulWidget {
  const ProblemsListScreen({super.key});

  @override
  ConsumerState<ProblemsListScreen> createState() => _ProblemsListScreenState();
}

class _ProblemsListScreenState extends ConsumerState<ProblemsListScreen> {
  String? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final problemsAsync = ref.watch(problemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Problems'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              ref.read(problemsProvider.notifier).setSortBy(value);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'pain_score', child: Text('Pain Score')),
              const PopupMenuItem(value: 'created_at', child: Text('Created Date')),
              const PopupMenuItem(value: 'status', child: Text('Status')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _selectedFilter == null,
                  onTap: () {
                    setState(() => _selectedFilter = null);
                    ref.read(problemsProvider.notifier).setFilter(null);
                  },
                ),
                _FilterChip(
                  label: 'Logged',
                  selected: _selectedFilter == 'Logged',
                  onTap: () {
                    setState(() => _selectedFilter = 'Logged');
                    ref.read(problemsProvider.notifier).setFilter('Logged');
                  },
                ),
                _FilterChip(
                  label: 'Worth Pursuing',
                  selected: _selectedFilter == 'Worth Pursuing',
                  onTap: () {
                    setState(() => _selectedFilter = 'Worth Pursuing');
                    ref.read(problemsProvider.notifier).setFilter('Worth Pursuing');
                  },
                ),
                _FilterChip(
                  label: 'Not Worth It',
                  selected: _selectedFilter == 'Not Worth It',
                  onTap: () {
                    setState(() => _selectedFilter = 'Not Worth It');
                    ref.read(problemsProvider.notifier).setFilter('Not Worth It');
                  },
                ),
                _FilterChip(
                  label: 'Archived',
                  selected: _selectedFilter == 'Archived',
                  onTap: () {
                    setState(() => _selectedFilter = 'Archived');
                    ref.read(problemsProvider.notifier).setFilter('Archived');
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: problemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: GoogleFonts.inter(color: AppColors.error)),
              ),
              data: (problems) {
                if (problems.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lightbulb_outline,
                              size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 16),
                          Text(
                            'No problems logged yet.',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Who are you building for, and what do they struggle with?',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => context.push('/problems/new'),
                            child: const Text('Log a Problem'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(problemsProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: problems.length,
                    itemBuilder: (context, index) {
                      final problem = problems[index];
                      return GestureDetector(
                        onTap: () => context.push('/problems/${problem.id}'),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      problem.statement,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PainScoreBadge(
                                    score: problem.painScore,
                                    showLabel: false,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.people_outline,
                                      size: 14,
                                      color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      problem.targetAudience,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  _StatusChip(status: problem.status),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/problems/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentDim : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
      case 'Worth Pursuing':
        return AppColors.success;
      case 'Not Worth It':
        return AppColors.error;
      case 'Archived':
        return AppColors.textSecondary;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}
