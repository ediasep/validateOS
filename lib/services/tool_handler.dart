import 'package:supabase_flutter/supabase_flutter.dart';

class ToolHandler {
  final SupabaseClient _client;

  ToolHandler(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<String> executeToolCall(String toolName, Map<String, dynamic> input) async {
    switch (toolName) {
      case 'create_problem':
        final result = await _client.from('problems').insert({
          'user_id': _userId,
          'statement': input['statement'],
          'target_audience': input['target_audience'],
          'source': input['source'],
          'time_spent_score': input['time_spent_score'],
          'complaint_frequency_score': input['complaint_frequency_score'],
          'pays_for_alternative': input['pays_for_alternative'],
          'willingness_to_pay_score': input['willingness_to_pay_score'],
          'notes': input['notes'],
          'status': 'Logged',
        }).select().single();
        return 'Problem created with id: ${result['id']}, pain score: ${result['pain_score']}';

      case 'create_problem_evidence':
        final result = await _client.from('problem_evidence').insert({
          'user_id': _userId,
          'problem_id': input['problem_id'],
          'platform': input['platform'],
          'quote': input['quote'],
          'url': input['url'],
          'found_via': input['found_via'],
        }).select().single();
        return 'Evidence saved with id: ${result['id']}';

      case 'create_solution':
        final result = await _client.from('solutions').insert({
          'user_id': _userId,
          'problem_id': input['problem_id'],
          'statement': input['statement'],
          'feasibility_score': input['feasibility_score'],
          'excitement_score': input['excitement_score'],
          'notes': input['notes'],
          'status': 'Idea',
        }).select().single();
        return 'Solution created with id: ${result['id']}';

      case 'create_validation':
        final result = await _client.from('validations').insert({
          'user_id': _userId,
          'solution_id': input['solution_id'],
          'method': input['method'],
          'hypothesis': input['hypothesis'],
          'success_signal': input['success_signal'],
          'result': input['result'] ?? 'Not Run Yet',
          'evidence': input['evidence'],
        }).select().single();
        return 'Validation logged with id: ${result['id']}';

      case 'update_problem_status':
        await _client
            .from('problems')
            .update({'status': input['status']})
            .eq('id', input['problem_id']);
        return 'Problem status updated to ${input['status']}';

      case 'update_solution_status':
        if (input['status'] == 'Building') {
          final validations = await _client
              .from('validations')
              .select()
              .eq('solution_id', input['solution_id'])
              .eq('result', 'Passed');
          if ((validations as List).isEmpty) {
            return 'ERROR: Cannot set status to Building — no passed validations for this solution.';
          }
        }
        await _client
            .from('solutions')
            .update({'status': input['status']})
            .eq('id', input['solution_id']);
        return 'Solution status updated to ${input['status']}';

      default:
        return 'ERROR: Unknown tool $toolName';
    }
  }
}
