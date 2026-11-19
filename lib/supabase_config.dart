import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://oaqcioychodxtuniipib.supabase.co';
  static const String anonKey = 'sb_publishable_TZundwJNbiWVVD2OtQdHyQ_kOXsPajF';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: anonKey,
        debug: kDebugMode,
      );
      debugPrint('Supabase initialized successfully.');
    } catch (e) {
      debugPrint('Supabase initialization warning: $e');
    }
  }
}
