import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/clientes/data/repositories/supabase_cliente_repository.dart';
import '../../features/clientes/domain/repositories/cliente_repository.dart';
import '../../features/vehiculos/data/repositories/supabase_vehiculo_repository.dart';
import '../../features/vehiculos/domain/repositories/vehiculo_repository.dart';

final _supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final clienteRepositoryProvider = Provider<ClienteRepository>((ref) {
  return SupabaseClienteRepository(ref.watch(_supabaseClientProvider));
});

final vehiculoRepositoryProvider = Provider<VehiculoRepository>((ref) {
  return SupabaseVehiculoRepository(ref.watch(_supabaseClientProvider));
});
