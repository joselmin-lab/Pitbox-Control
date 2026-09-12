class SupabaseConfig {
  const SupabaseConfig._();

  /// Credenciales del proyecto Supabase activo de Pitbox Control (usuario).
  ///
  /// En producción real se recomienda moverlas a variables de entorno con
  /// `--dart-define` (o `.env`) para no hardcodearlas en el código.
  /// En esta fase se dejan como constantes por simplicidad; la anon key está
  /// limitada por Row Level Security (RLS).
  static const String url = 'https://vypbdwngfnjfzrwaumtt.supabase.co';
  static const String anonKey =
      'eyJ'
      'hbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ5cGJkd25nZm5qZnpyd2F1bXR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkyMTU2NjgsImV4cCI6MjEwNDc5MTY2OH0.'
      '7IrOi7CScAi3M6ZjB-6qWAw5sZrUPJX3JdvzlIZtfG8';

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
