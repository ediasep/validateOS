import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/problem.dart';

class ProblemRepository {
  final SupabaseClient _client;

  ProblemRepository(this._client);

  Future<List<Problem>> fetchAll({String? statusFilter, String sortBy = 'pain_score'}) async {
    var query = _client.from('problems').select();

    if (statusFilter != null) {
      query = query.eq('status', statusFilter);
    }

    final List<dynamic> data;
    if (sortBy == 'pain_score') {
      data = await query.order('pain_score', ascending: false);
    } else if (sortBy == 'created_at') {
      data = await query.order('created_at', ascending: false);
    } else {
      data = await query.order('status');
    }

    return data.map((json) => Problem.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Problem> fetchById(String id) async {
    final data = await _client.from('problems').select().eq('id', id).single();
    return Problem.fromJson(data);
  }

  Future<Problem> create(Map<String, dynamic> data) async {
    final result = await _client.from('problems').insert(data).select().single();
    return Problem.fromJson(result);
  }

  Future<void> updateStatus(String id, String status) async {
    await _client.from('problems').update({'status': status}).eq('id', id);
  }

  Future<void> updateEvidenceSummary(String id, String summary) async {
    await _client.from('problems').update({'evidence_summary': summary}).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _client.from('problems').delete().eq('id', id);
  }

  Future<void> deleteAll(String userId) async {
    await _client.from('problems').delete().eq('user_id', userId);
  }
}
