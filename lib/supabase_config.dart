import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Replace these with your actual Supabase project credentials
  static const String supabaseUrl = 'https://xhfhtasgnsnymjhglrkp.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_2caBrJAhlPO-CCvNRwMKiw_ZHyNuBVX';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
