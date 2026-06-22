import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/solution.dart';

class SolutionRepository {
  final SupabaseClient _client;

  SolutionRepository(this._client);

  Future<List<Solution>> fetchAll({String? statusFilter}) async {
    var query = _client.from('solutions').select();

    if (statusFilter != null) {
      query = query.eq('status', statusFilter);
    }

    final data = await query.order('created_at', ascending: false);
    final solutions = (data as List)
        .map((json) => Solution.fromJson(json as Map<String, dynamic>))
        .toList();

    solutions.sort((a, b) => b.combinedScore.compareTo(a.combinedScore));
    return solutions;
  }

  Future<List<Solution>> fetchByProblemId(String problemId) async {
    final data = await _client
        .from('solutions')
        .select()
        .eq('problem_id', problemId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((json) => Solution.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Solution> fetchById(String id) async {
    final data = await _client.from('solutions').select().eq('id', id).single();
    return Solution.fromJson(data);
  }

  Future<Solution> create(Map<String, dynamic> data) async {
    final result = await _client.from('solutions').insert(data).select().single();
    return Solution.fromJson(result);
  }

  Future<void> updateStatus(String id, String status) async {
    await _client.from('solutions').update({'status': status}).eq('id', id);
  }

  Future<void> markChosen(String id) async {
    await _client.from('solutions').update({'is_chosen': true}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('solutions').delete().eq('id', id);
  }

  Future<void> deleteAll(String userId) async {
    await _client.from('solutions').delete().eq('user_id', userId);
  }
}
