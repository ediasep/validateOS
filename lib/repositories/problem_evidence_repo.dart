import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/problem_evidence.dart';

class ProblemEvidenceRepository {
  final SupabaseClient _client;

  ProblemEvidenceRepository(this._client);

  Future<List<ProblemEvidence>> fetchByProblemId(String problemId) async {
    final data = await _client
        .from('problem_evidence')
        .select()
        .eq('problem_id', problemId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((json) => ProblemEvidence.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProblemEvidence>> fetchAll() async {
    final data = await _client
        .from('problem_evidence')
        .select()
        .order('created_at', ascending: false);
    return (data as List)
        .map((json) => ProblemEvidence.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ProblemEvidence> create(Map<String, dynamic> data) async {
    final result =
        await _client.from('problem_evidence').insert(data).select().single();
    return ProblemEvidence.fromJson(result);
  }

  Future<void> delete(String id) async {
    await _client.from('problem_evidence').delete().eq('id', id);
  }
}
