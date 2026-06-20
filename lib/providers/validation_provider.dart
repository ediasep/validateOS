import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/validation.dart';
import '../repositories/validation_repo.dart';
import 'auth_provider.dart';

final validationRepositoryProvider = Provider<ValidationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ValidationRepository(client);
});

final validationsBySolutionProvider =
    FutureProvider.family<List<Validation>, String>((ref, solutionId) async {
  final repo = ref.watch(validationRepositoryProvider);
  return repo.fetchBySolutionId(solutionId);
});

final allValidationsProvider =
    FutureProvider<List<Validation>>((ref) async {
  final repo = ref.watch(validationRepositoryProvider);
  return repo.fetchAll();
});
