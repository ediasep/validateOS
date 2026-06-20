import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/problem_provider.dart';
import '../../providers/solution_provider.dart';
import '../../services/gemini_service.dart';
import '../../theme.dart';
import '../../widgets/ai_review_card.dart';

class SolutionFormScreen extends ConsumerStatefulWidget {
  final String? problemId;
  const SolutionFormScreen({super.key, this.problemId});

  @override
  ConsumerState<SolutionFormScreen> createState() => _SolutionFormScreenState();
}

class _SolutionFormScreenState extends ConsumerState<SolutionFormScreen> {
  final _statementController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedProblemId;
  int _feasibilityScore = 3;
  int _excitementScore = 3;
  bool _isReviewing = false;
  bool _isSaving = false;
  Map<String, dynamic>? _reviewResult;

  @override
  void initState() {
    super.initState();
    _selectedProblemId = widget.problemId;
  }

  Future<void> _runReview() async {
    if (_statementController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solution statement is required')),
      );
      return;
    }
    if (_selectedProblemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a problem first')),
      );
      return;
    }

    setState(() {
      _isReviewing = true;
      _reviewResult = null;
    });

    final repo = ref.read(problemRepositoryProvider);
    final problem = await repo.fetchById(_selectedProblemId!);

    final gemini = GeminiService();
    final result = await gemini.reviewSolution(
      statement: _statementController.text.trim(),
      problemStatement: problem.statement,
    );

    setState(() {
      _isReviewing = false;
      _reviewResult = result;
    });

    if (result == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't parse AI response. Try again.")),
      );
    }
  }

  Future<void> _save() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null || _selectedProblemId == null) return;

    setState(() => _isSaving = true);

    final repo = ref.read(solutionRepositoryProvider);
    await repo.create({
      'user_id': userId,
      'problem_id': _selectedProblemId,
      'statement': _statementController.text.trim(),
      'feasibility_score': _feasibilityScore,
      'excitement_score': _excitementScore,
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      'status': 'Idea',
      'is_chosen': false,
    });

    ref.invalidate(solutionsProvider);
    ref.invalidate(solutionsByProblemProvider(_selectedProblemId!));
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _statementController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final problemsAsync = ref.watch(problemsProvider);
    final isApproved = _reviewResult?['verdict'] == 'approved';

    return Scaffold(
      appBar: AppBar(title: const Text('New Solution')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Linked Problem',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            problemsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (problems) {
                final sorted = [...problems];
                sorted.sort((a, b) {
                  if (a.status == 'Worth Pursuing' &&
                      b.status != 'Worth Pursuing') {
                    return -1;
                  }
                  if (b.status == 'Worth Pursuing' &&
                      a.status != 'Worth Pursuing') {
                    return 1;
                  }
                  return 0;
                });
                return DropdownButtonFormField<String>(
                  initialValue: _selectedProblemId,
                  decoration: const InputDecoration(
                    hintText: 'Select a problem',
                  ),
                  items: sorted
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              p.statement,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedProblemId = v),
                  dropdownColor: AppColors.surfaceHigh,
                  isExpanded: true,
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _statementController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Solution Statement',
                hintText: 'How would you solve this problem?',
              ),
            ),
            const SizedBox(height: 16),
            _ScoreSlider(
              label: 'How hard is this to build? (Feasibility)',
              value: _feasibilityScore,
              onChanged: (v) => setState(() => _feasibilityScore = v),
            ),
            _ScoreSlider(
              label: 'How excited are you to build this? (Excitement)',
              value: _excitementScore,
              onChanged: (v) => setState(() => _excitementScore = v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
              ),
            ),
            const SizedBox(height: 24),
            if (_reviewResult != null) AiReviewCard(review: _reviewResult!),
            const SizedBox(height: 16),
            if (!isApproved)
              ElevatedButton.icon(
                onPressed: _isReviewing ? null : _runReview,
                icon: _isReviewing
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.smart_toy_outlined),
                label: Text(
                    _reviewResult == null ? 'Review with AI' : 'Review Again'),
              ),
            if (isApproved)
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Solution'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScoreSlider extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _ScoreSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary)),
          Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: value.toString(),
            activeColor: AppColors.accent,
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}
