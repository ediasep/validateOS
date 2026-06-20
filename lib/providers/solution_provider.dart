import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/solution.dart';
import '../repositories/solution_repo.dart';
import 'auth_provider.dart';

final solutionRepositoryProvider = Provider<SolutionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SolutionRepository(client);
});

final solutionsProvider =
    AsyncNotifierProvider<SolutionsNotifier, List<Solution>>(
        SolutionsNotifier.new);

class SolutionsNotifier extends AsyncNotifier<List<Solution>> {
  String? _statusFilter;

  @override
  Future<List<Solution>> build() async {
    final repo = ref.watch(solutionRepositoryProvider);
    return repo.fetchAll(statusFilter: _statusFilter);
  }

  Future<void> setFilter(String? status) async {
    _statusFilter = status;
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final solutionsByProblemProvider =
    FutureProvider.family<List<Solution>, String>((ref, problemId) async {
  final repo = ref.watch(solutionRepositoryProvider);
  return repo.fetchByProblemId(problemId);
});

final solutionDetailProvider =
    FutureProvider.family<Solution, String>((ref, id) async {
  final repo = ref.watch(solutionRepositoryProvider);
  return repo.fetchById(id);
});
