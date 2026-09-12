import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class SupabaseService {
  const SupabaseService();

  static bool _initialized = false;
  static Object? _initializationError;

  static bool get isInitialized => _initialized;
  static Object? get initializationError => _initializationError;

  Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      _initialized = false;
      _initializationError = StateError('SupabaseConfig no está configurado.');
      return;
    }
    try {
      await Supabase.initialize(url: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey);
      _initialized = true;
      _initializationError = null;
    } catch (error) {
      _initialized = false;
      _initializationError = error;
      rethrow;
    }
  }
}
