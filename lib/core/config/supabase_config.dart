class SupabaseConfig {
  const SupabaseConfig._();

  /// Placeholders para la futura integración con Supabase.
  /// Reemplazar por variables seguras de entorno en la siguiente fase.
  static const String url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
