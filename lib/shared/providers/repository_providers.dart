import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';
import '../../features/clientes/data/repositories/supabase_cliente_repository.dart';
import '../../features/clientes/domain/repositories/cliente_repository.dart';
import '../../features/vehiculos/data/repositories/supabase_vehiculo_repository.dart';
import '../../features/vehiculos/domain/repositories/vehiculo_repository.dart';

final _supabaseClientProvider = Provider<SupabaseClient>((ref) {
  if (!SupabaseService.isInitialized) {
    throw StateError(
      'Supabase no está inicializado. Verifica la configuración en '
      'core/config/supabase_config.dart y ejecuta el script supabase/schema.sql. '
      'Detalle: ${SupabaseService.initializationError ?? 'inicialización pendiente'}',
    );
  }
  return Supabase.instance.client;
});

final clienteRepositoryProvider = Provider<ClienteRepository>((ref) {
  return SupabaseClienteRepository(ref.watch(_supabaseClientProvider));
});

final vehiculoRepositoryProvider = Provider<VehiculoRepository>((ref) {
  return SupabaseVehiculoRepository(ref.watch(_supabaseClientProvider));
});
