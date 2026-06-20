import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/validation.dart';

class ValidationRepository {
  final SupabaseClient _client;

  ValidationRepository(this._client);

  Future<List<Validation>> fetchBySolutionId(String solutionId) async {
    final data = await _client
        .from('validations')
        .select()
        .eq('solution_id', solutionId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((json) => Validation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Validation>> fetchAll() async {
    final data = await _client
        .from('validations')
        .select()
        .order('created_at', ascending: false);
    return (data as List)
        .map((json) => Validation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Validation> create(Map<String, dynamic> data) async {
    final result =
        await _client.from('validations').insert(data).select().single();
    return Validation.fromJson(result);
  }

  Future<void> updateResult(String id, String result, String? evidence, String? dateRun) async {
    final updates = <String, dynamic>{'result': result};
    if (evidence != null) updates['evidence'] = evidence;
    if (dateRun != null) updates['date_run'] = dateRun;
    await _client.from('validations').update(updates).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('validations').delete().eq('id', id);
  }

  Future<void> deleteAll(String userId) async {
    await _client.from('validations').delete().eq('user_id', userId);
  }
}
