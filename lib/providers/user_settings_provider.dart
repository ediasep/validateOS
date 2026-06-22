import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_settings.dart';
import '../repositories/user_settings_repo.dart';
import 'auth_provider.dart';

final userSettingsRepositoryProvider = Provider<UserSettingsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return UserSettingsRepository(client);
});

final userSettingsProvider =
    AsyncNotifierProvider<UserSettingsNotifier, UserSettings?>(
        UserSettingsNotifier.new);

class UserSettingsNotifier extends AsyncNotifier<UserSettings?> {
  @override
  Future<UserSettings?> build() async {
    final repo = ref.watch(userSettingsRepositoryProvider);
    return repo.fetch();
  }

  Future<void> saveSettings({String? apiKey, String? preferredModel}) async {
    final repo = ref.read(userSettingsRepositoryProvider);
    final updated = await repo.upsert(
      apiKey: apiKey,
      preferredModel: preferredModel,
    );
    state = AsyncValue.data(updated);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
