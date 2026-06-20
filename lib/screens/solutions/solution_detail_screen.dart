import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/solution_provider.dart';
import '../../providers/validation_provider.dart';
import '../../theme.dart';

class SolutionDetailScreen extends ConsumerWidget {
  final String solutionId;
  const SolutionDetailScreen({super.key, required this.solutionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solutionAsync = ref.watch(solutionDetailProvider(solutionId));
    final validationsAsync =
        ref.watch(validationsBySolutionProvider(solutionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Solution')),
      body: solutionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (solution) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(solution.statement,
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _ScoreDisplay(
                        label: 'Feasibility', score: solution.feasibilityScore),
                    const SizedBox(width: 16),
                    _ScoreDisplay(
                        label: 'Excitement', score: solution.excitementScore),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    solution.status,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent),
                  ),
                ),
                const SizedBox(height: 20),

                // Mark as chosen
                if (!solution.isChosen)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final repo = ref.read(solutionRepositoryProvider);
                      await repo.markChosen(solutionId);
                      ref.invalidate(solutionDetailProvider(solutionId));
                      ref.invalidate(solutionsProvider);
                    },
                    icon: const Icon(Icons.star_outline, size: 18),
                    label: const Text('Mark as Chosen'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star,
                            size: 16, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text('Chosen',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.accent)),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // Status dropdown
                Text('Change Status',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Idea',
                    'Chosen',
                    'Validating',
                    'Validated',
                    'Killed',
                    'Building'
                  ]
                      .map((s) => ChoiceChip(
                            label: Text(s),
                            selected: solution.status == s,
                            onSelected: (_) async {
                              if (s == 'Building') {
                                final validations =
                                    validationsAsync.valueOrNull ?? [];
                                final hasPassed = validations
                                    .any((v) => v.result == 'Passed');
                                if (!hasPassed) {
                                  final proceed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: AppColors.surface,
                                      title: Text(
                                        'No passed validations',
                                        style: GoogleFonts.spaceGrotesk(
                                            color: AppColors.textPrimary),
                                      ),
                                      content: Text(
                                        "You haven't validated this yet. Building without validation defeats the purpose of this app. Are you sure?",
                                        style: GoogleFonts.inter(
                                            color: AppColors.textSecondary),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.warning,
                                          ),
                                          child: const Text(
                                              'Yes, skip validation'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (proceed != true) return;
                                }
                              }
                              final repo =
                                  ref.read(solutionRepositoryProvider);
                              await repo.updateStatus(solutionId, s);
                              ref.invalidate(
                                  solutionDetailProvider(solutionId));
                              ref.invalidate(solutionsProvider);
                            },
                            selectedColor: AppColors.accentDim,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),

                // Validations
                Row(
                  children: [
                    Text('Validations',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => context
                          .push('/solutions/$solutionId/validation/new'),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                validationsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (validations) {
                    if (validations.isEmpty) {
                      return Text(
                        'No validations yet. Test your assumption before building.',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary),
                      );
                    }
                    return Column(
                      children: validations
                          .map((v) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHigh,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(v.method,
                                            style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    AppColors.textPrimary)),
                                        const Spacer(),
                                        _ResultChip(result: v.result),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                        'Hypothesis: ${v.hypothesis}',
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color:
                                                AppColors.textSecondary)),
                                    Text(
                                        'Signal: ${v.successSignal}',
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color:
                                                AppColors.textSecondary)),
                                    if (v.evidence != null &&
                                        v.evidence!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('Evidence: ${v.evidence}',
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppColors.accent)),
                                    ],
                                  ],
                                ),
                              ))
                          .toList(),
                    );
                  },
                ),

                if (solution.notes != null && solution.notes!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Notes',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(solution.notes!,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScoreDisplay extends StatelessWidget {
  final String label;
  final int score;

  const _ScoreDisplay({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text('$score/5',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.accent)),
      ],
    );
  }
}

class _ResultChip extends StatelessWidget {
  final String result;

  const _ResultChip({required this.result});

  Color get _color {
    switch (result) {
      case 'Passed':
        return AppColors.success;
      case 'Failed':
        return AppColors.error;
      case 'Inconclusive':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
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
        result,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}
