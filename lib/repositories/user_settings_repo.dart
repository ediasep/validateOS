import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_settings.dart';

class UserSettingsRepository {
  final SupabaseClient _client;

  UserSettingsRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<UserSettings?> fetch() async {
    final data = await _client
        .from('user_settings')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();
    if (data == null) return null;
    return UserSettings.fromJson(data);
  }

  Future<UserSettings> upsert({String? apiKey, String? preferredModel}) async {
    final existing = await fetch();
    if (existing == null) {
      final result = await _client
          .from('user_settings')
          .insert({
            'user_id': _userId,
            'gemini_api_key': apiKey,
            'preferred_model': preferredModel ?? 'gemini-3.5-flash',
          })
          .select()
          .single();
      return UserSettings.fromJson(result);
    } else {
      final updates = <String, dynamic>{};
      if (apiKey != null) updates['gemini_api_key'] = apiKey;
      if (preferredModel != null) updates['preferred_model'] = preferredModel;

      final result = await _client
          .from('user_settings')
          .update(updates)
          .eq('user_id', _userId)
          .select()
          .single();
      return UserSettings.fromJson(result);
    }
  }
}
