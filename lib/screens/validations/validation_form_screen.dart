import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/validation_provider.dart';
import '../../theme.dart';

class ValidationFormScreen extends ConsumerStatefulWidget {
  final String solutionId;
  const ValidationFormScreen({super.key, required this.solutionId});

  @override
  ConsumerState<ValidationFormScreen> createState() =>
      _ValidationFormScreenState();
}

class _ValidationFormScreenState extends ConsumerState<ValidationFormScreen> {
  final _hypothesisController = TextEditingController();
  final _successSignalController = TextEditingController();
  final _evidenceController = TextEditingController();
  String _method = 'Customer Interview';
  String _result = 'Not Run Yet';
  DateTime? _dateRun;
  bool _isSaving = false;

  Future<void> _save() async {
    if (_hypothesisController.text.trim().isEmpty ||
        _successSignalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hypothesis and success signal are required')),
      );
      return;
    }

    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);

    final repo = ref.read(validationRepositoryProvider);
    await repo.create({
      'user_id': userId,
      'solution_id': widget.solutionId,
      'method': _method,
      'hypothesis': _hypothesisController.text.trim(),
      'success_signal': _successSignalController.text.trim(),
      'result': _result,
      'evidence': _evidenceController.text.trim().isEmpty
          ? null
          : _evidenceController.text.trim(),
      'date_run': _dateRun?.toIso8601String().split('T').first,
    });

    ref.invalidate(validationsBySolutionProvider(widget.solutionId));
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _hypothesisController.dispose();
    _successSignalController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Validation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Method',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(),
              items: const [
                DropdownMenuItem(
                    value: 'Customer Interview',
                    child: Text('Customer Interview')),
                DropdownMenuItem(value: 'Fake Door', child: Text('Fake Door')),
                DropdownMenuItem(value: 'Prototype', child: Text('Prototype')),
                DropdownMenuItem(value: 'Survey', child: Text('Survey')),
                DropdownMenuItem(value: 'Concierge', child: Text('Concierge')),
                DropdownMenuItem(value: 'Pre-sale', child: Text('Pre-sale')),
              ],
              onChanged: (v) => setState(() => _method = v ?? _method),
              dropdownColor: AppColors.surfaceHigh,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hypothesisController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Hypothesis',
                hintText: 'What are you assuming is true?',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _successSignalController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Success Signal',
                hintText: 'What result would prove this?',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _result,
              decoration: const InputDecoration(labelText: 'Result'),
              items: const [
                DropdownMenuItem(
                    value: 'Not Run Yet', child: Text('Not Run Yet')),
                DropdownMenuItem(value: 'Passed', child: Text('Passed')),
                DropdownMenuItem(value: 'Failed', child: Text('Failed')),
                DropdownMenuItem(
                    value: 'Inconclusive', child: Text('Inconclusive')),
              ],
              onChanged: (v) => setState(() => _result = v ?? _result),
              dropdownColor: AppColors.surfaceHigh,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _evidenceController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Evidence (optional)',
                hintText: 'e.g. "12 of 15 signed up"',
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _dateRun == null
                    ? 'Date run (optional)'
                    : 'Date: ${_dateRun!.toIso8601String().split('T').first}',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textPrimary),
              ),
              trailing: const Icon(Icons.calendar_today, size: 20),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _dateRun = picked);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Validation'),
            ),
          ],
        ),
      ),
    );
  }
}
