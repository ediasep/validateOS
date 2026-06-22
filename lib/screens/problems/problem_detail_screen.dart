import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/problem_provider.dart';
import '../../providers/problem_evidence_provider.dart';
import '../../providers/solution_provider.dart';
import '../../theme.dart';
import '../../widgets/pain_score_badge.dart';
import '../../widgets/evidence_card.dart';

class ProblemDetailScreen extends ConsumerStatefulWidget {
  final String problemId;
  const ProblemDetailScreen({super.key, required this.problemId});

  @override
  ConsumerState<ProblemDetailScreen> createState() =>
      _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends ConsumerState<ProblemDetailScreen> {
  final _evidenceSummaryController = TextEditingController();

  @override
  void dispose() {
    _evidenceSummaryController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String status) async {
    final evidenceAsync = ref.read(problemEvidenceProvider(widget.problemId));
    final evidence = evidenceAsync.valueOrNull ?? [];

    if (status == 'Worth Pursuing' && evidence.isEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('No evidence attached yet',
              style: GoogleFonts.spaceGrotesk(color: AppColors.textPrimary)),
          content: Text(
            'Pain score alone is your opinion — evidence makes it real. Continue anyway?',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Continue')),
          ],
        ),
      );
      if (proceed != true) return;
    }

    final repo = ref.read(problemRepositoryProvider);
    await repo.updateStatus(widget.problemId, status);
    ref.invalidate(problemDetailProvider(widget.problemId));
    ref.invalidate(problemsProvider);
  }

  void _showAddEvidenceSheet() {
    final platformController = TextEditingController();
    final quoteController = TextEditingController();
    final urlController = TextEditingController();
    String selectedPlatform = 'Reddit';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add Evidence',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedPlatform,
                decoration: const InputDecoration(labelText: 'Platform'),
                items: const [
                  DropdownMenuItem(value: 'Trustpilot', child: Text('Trustpilot')),
                  DropdownMenuItem(value: 'G2', child: Text('G2')),
                  DropdownMenuItem(value: 'Reddit', child: Text('Reddit')),
                  DropdownMenuItem(value: 'Twitter/X', child: Text('Twitter/X')),
                  DropdownMenuItem(
                      value: 'App Store Review',
                      child: Text('App Store Review')),
                  DropdownMenuItem(
                      value: 'Google Play Review',
                      child: Text('Google Play Review')),
                  DropdownMenuItem(value: 'Forum', child: Text('Forum')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) =>
                    setSheetState(() => selectedPlatform = v ?? 'Reddit'),
                dropdownColor: AppColors.surfaceHigh,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: quoteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Quote (required)',
                  hintText: 'Paste the actual complaint text',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'URL (optional)',
                  hintText: 'https://',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (quoteController.text.trim().isEmpty) return;
                  final userId = ref.read(currentUserProvider)?.id;
                  if (userId == null) return;
                  final repo = ref.read(problemEvidenceRepositoryProvider);
                  await repo.create({
                    'user_id': userId,
                    'problem_id': widget.problemId,
                    'platform': selectedPlatform,
                    'quote': quoteController.text.trim(),
                    'url': urlController.text.trim().isEmpty
                        ? null
                        : urlController.text.trim(),
                    'found_via': 'Manual',
                  });
                  ref.invalidate(problemEvidenceProvider(widget.problemId));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save Evidence'),
              ),
            ],
          ),
        ),
      ),
    );
    platformController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final problemAsync = ref.watch(problemDetailProvider(widget.problemId));
    final evidenceAsync = ref.watch(problemEvidenceProvider(widget.problemId));
    final solutionsAsync =
        ref.watch(solutionsByProblemProvider(widget.problemId));

    return Scaffold(
      appBar: AppBar(title: const Text('Problem')),
      body: problemAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (problem) {
          if (_evidenceSummaryController.text.isEmpty &&
              problem.evidenceSummary != null) {
            _evidenceSummaryController.text = problem.evidenceSummary!;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(problem.statement,
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.people_outline,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(problem.targetAudience,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(problem.source,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 8),
                    PainScoreBadge(score: problem.painScore),
                  ],
                ),
                const SizedBox(height: 20),

                // Pain breakdown
                Text('Pain Breakdown',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                _PainBreakdownRow(
                    label: 'Time spent', score: problem.timeSpentScore),
                _PainBreakdownRow(
                    label: 'Complaint frequency',
                    score: problem.complaintFrequencyScore),
                _PainBreakdownRow(
                    label: 'Willingness to pay',
                    score: problem.willingnessToPayScore),
                _PainBreakdownRow(
                    label: 'Pays for alternative',
                    score: problem.paysForAlternative ? 5 : 0,
                    maxScore: 5),
                const SizedBox(height: 20),

                // Status selector
                Text('Status',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    'Logged',
                    'Worth Pursuing',
                    'Not Worth It',
                    'Archived'
                  ]
                      .map((s) => ChoiceChip(
                            label: Text(s),
                            selected: problem.status == s,
                            onSelected: (_) => _updateStatus(s),
                            selectedColor: AppColors.accentDim,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),

                // Evidence section
                Row(
                  children: [
                    Text('Evidence',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _showAddEvidenceSheet,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _evidenceSummaryController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Evidence summary...',
                    isDense: true,
                  ),
                  onFieldSubmitted: (v) {
                    final repo = ref.read(problemRepositoryProvider);
                    repo.updateEvidenceSummary(widget.problemId, v);
                  },
                ),
                const SizedBox(height: 12),
                evidenceAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (evidence) {
                    if (evidence.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'No evidence yet. Search review sites or forums to confirm this is a real problem.',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: _showAddEvidenceSheet,
                                  child: const Text('Add Manually'),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    ref
                                        .read(chatProvider.notifier)
                                        .setInitialPrompt(
                                          'Search for evidence that this problem is real: "${problem.statement}" (target audience: ${problem.targetAudience}). Look for real complaints, reviews, or forum posts from people experiencing this problem.',
                                        );
                                    context.go('/chat');
                                  },
                                  child: const Text('Ask AI to Search'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: evidence
                          .map((e) => EvidenceCard(evidence: e))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Solutions section
                Row(
                  children: [
                    Text('Solutions',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () =>
                          context.push('/solutions/new?problem_id=${widget.problemId}'),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                solutionsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (solutions) {
                    if (solutions.isEmpty) {
                      return Text(
                        'No solutions yet.',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary),
                      );
                    }
                    return Column(
                      children: [
                        if (solutions.length < 2)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Consider generating at least one more solution before committing — don't lock in on the first idea.",
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.warning),
                            ),
                          ),
                        ...solutions.map((s) => GestureDetector(
                              onTap: () =>
                                  context.push('/solutions/${s.id}'),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHigh,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(s.statement,
                                          style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color:
                                                  AppColors.textPrimary),
                                          maxLines: 2,
                                          overflow:
                                              TextOverflow.ellipsis),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(s.status,
                                          style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: AppColors.accent)),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    );
                  },
                ),

                if (problem.notes != null && problem.notes!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Notes',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(problem.notes!,
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

class _PainBreakdownRow extends StatelessWidget {
  final String label;
  final int score;
  final int maxScore;

  const _PainBreakdownRow({
    required this.label,
    required this.score,
    this.maxScore = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: List.generate(
                maxScore,
                (i) => Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    color: i < score
                        ? AppColors.accent
                        : AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          Text('$score/$maxScore',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
