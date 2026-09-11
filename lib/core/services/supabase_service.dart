import '../config/supabase_config.dart';

class SupabaseService {
  const SupabaseService();

  /// Servicio base reservado para la Fase 2.
  ///
  /// Aquí se centralizará la inicialización del cliente de Supabase y los
  /// repositorios compartidos cuando se habiliten autenticación y CRUD reales.
  Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      return;
    }

    // Implementación pendiente para una fase futura.
    // Ejemplo esperado:
    // await Supabase.initialize(url: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey);
  }
}
