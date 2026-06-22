import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/problem_evidence.dart';
import '../repositories/problem_evidence_repo.dart';
import 'auth_provider.dart';

final problemEvidenceRepositoryProvider =
    Provider<ProblemEvidenceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProblemEvidenceRepository(client);
});

final problemEvidenceProvider = FutureProvider.family<List<ProblemEvidence>, String>(
    (ref, problemId) async {
  final repo = ref.watch(problemEvidenceRepositoryProvider);
  return repo.fetchByProblemId(problemId);
});

final allEvidenceProvider =
    FutureProvider<List<ProblemEvidence>>((ref) async {
  final repo = ref.watch(problemEvidenceRepositoryProvider);
  return repo.fetchAll();
});
