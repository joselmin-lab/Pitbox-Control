import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class SupabaseService {
  const SupabaseService();

  Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      return;
    }
    await Supabase.initialize(url: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey);
  }
}
