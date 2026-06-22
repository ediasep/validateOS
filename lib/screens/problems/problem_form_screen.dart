import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/problem_provider.dart';
import '../../providers/user_settings_provider.dart';
import '../../services/gemini_service.dart';
import '../../theme.dart';
import '../../widgets/ai_review_card.dart';

class ProblemFormScreen extends ConsumerStatefulWidget {
  const ProblemFormScreen({super.key});

  @override
  ConsumerState<ProblemFormScreen> createState() => _ProblemFormScreenState();
}

class _ProblemFormScreenState extends ConsumerState<ProblemFormScreen> {
  final _statementController = TextEditingController();
  final _audienceController = TextEditingController();
  final _notesController = TextEditingController();
  String _source = 'Research';
  int _timeSpentScore = 3;
  int _complaintFrequencyScore = 3;
  int _willingnessToPayScore = 3;
  bool _paysForAlternative = false;
  bool _isReviewing = false;
  bool _isSaving = false;
  Map<String, dynamic>? _reviewResult;

  int get _computedPainScore =>
      _timeSpentScore +
      _complaintFrequencyScore +
      _willingnessToPayScore +
      (_paysForAlternative ? 5 : 0);

  Color get _painColor {
    final score = _computedPainScore;
    if (score >= 12) return AppColors.success;
    if (score >= 7) return AppColors.warning;
    return AppColors.error;
  }

  Future<void> _runReview() async {
    if (_statementController.text.trim().isEmpty ||
        _audienceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Statement and audience are required')),
      );
      return;
    }

    setState(() {
      _isReviewing = true;
      _reviewResult = null;
    });

    final settings = await ref.read(userSettingsProvider.future);
    final gemini = GeminiService();
    final result = await gemini.reviewProblem(
      statement: _statementController.text.trim(),
      targetAudience: _audienceController.text.trim(),
      source: _source,
      apiKey: settings?.geminiApiKey ?? '',
      preferredModel: settings?.preferredModel,
    );

    setState(() {
      _isReviewing = false;
      _reviewResult = result;
    });

    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Couldn't parse AI response. Try again.")),
        );
      }
    }
  }

  Future<void> _save() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);

    final repo = ref.read(problemRepositoryProvider);
    await repo.create({
      'user_id': userId,
      'statement': _statementController.text.trim(),
      'target_audience': _audienceController.text.trim(),
      'source': _source,
      'time_spent_score': _timeSpentScore,
      'complaint_frequency_score': _complaintFrequencyScore,
      'willingness_to_pay_score': _willingnessToPayScore,
      'pays_for_alternative': _paysForAlternative,
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      'status': 'Logged',
    });

    ref.invalidate(problemsProvider);
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _statementController.dispose();
    _audienceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isApproved = _reviewResult?['verdict'] == 'approved';

    return Scaffold(
      appBar: AppBar(title: const Text('Log a Problem')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _statementController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Problem Statement',
                hintText: 'What do they struggle with?',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _audienceController,
              decoration: const InputDecoration(
                labelText: 'Target Audience',
                hintText: 'Who has this problem?',
              ),
            ),
            const SizedBox(height: 16),
            Text('Source',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Interview', label: Text('Interview')),
                ButtonSegment(value: 'Observation', label: Text('Observe')),
                ButtonSegment(value: 'Research', label: Text('Research')),
                ButtonSegment(value: 'Assumption', label: Text('Assume')),
              ],
              selected: {_source},
              onSelectionChanged: (v) => setState(() => _source = v.first),
              style: ButtonStyle(
                textStyle: WidgetStatePropertyAll(
                  GoogleFonts.inter(fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Pain Assessment',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _ScoreSlider(
              label: 'Do they spend significant time on this?',
              value: _timeSpentScore,
              onChanged: (v) => setState(() => _timeSpentScore = v),
            ),
            _ScoreSlider(
              label: 'How often do they complain about it?',
              value: _complaintFrequencyScore,
              onChanged: (v) => setState(() => _complaintFrequencyScore = v),
            ),
            _ScoreSlider(
              label: 'How much would they pay to solve it?',
              value: _willingnessToPayScore,
              onChanged: (v) => setState(() => _willingnessToPayScore = v),
            ),
            SwitchListTile(
              title: Text(
                'Do they already pay for an existing solution?',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textPrimary),
              ),
              value: _paysForAlternative,
              onChanged: (v) => setState(() => _paysForAlternative = v),
              activeThumbColor: AppColors.accent,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text('Pain Score: ',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textSecondary)),
                  Text(
                    '$_computedPainScore/20',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _painColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _computedPainScore / 20,
                      backgroundColor: AppColors.surface,
                      valueColor: AlwaysStoppedAnimation(_painColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                label: Text(_reviewResult == null
                    ? 'Review with AI'
                    : 'Review Again'),
              ),
            if (isApproved) ...[
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Problem'),
              ),
            ],
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
