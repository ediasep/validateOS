import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/problem.dart';
import '../repositories/problem_repo.dart';
import 'auth_provider.dart';

final problemRepositoryProvider = Provider<ProblemRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProblemRepository(client);
});

final problemsProvider =
    AsyncNotifierProvider<ProblemsNotifier, List<Problem>>(ProblemsNotifier.new);

class ProblemsNotifier extends AsyncNotifier<List<Problem>> {
  String? _statusFilter;
  String _sortBy = 'pain_score';

  @override
  Future<List<Problem>> build() async {
    final repo = ref.watch(problemRepositoryProvider);
    return repo.fetchAll(statusFilter: _statusFilter, sortBy: _sortBy);
  }

  Future<void> setFilter(String? status) async {
    _statusFilter = status;
    ref.invalidateSelf();
  }

  Future<void> setSortBy(String sortBy) async {
    _sortBy = sortBy;
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final problemDetailProvider =
    FutureProvider.family<Problem, String>((ref, id) async {
  final repo = ref.watch(problemRepositoryProvider);
  return repo.fetchById(id);
});
