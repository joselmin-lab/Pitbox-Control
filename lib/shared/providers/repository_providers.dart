import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/clientes/data/repositories/in_memory_cliente_repository.dart';
import '../../features/clientes/domain/repositories/cliente_repository.dart';
import '../../features/vehiculos/data/repositories/in_memory_vehiculo_repository.dart';
import '../../features/vehiculos/domain/repositories/vehiculo_repository.dart';

final clienteRepositoryProvider = Provider<ClienteRepository>((ref) {
  return InMemoryClienteRepository();
});

final vehiculoRepositoryProvider = Provider<VehiculoRepository>((ref) {
  return InMemoryVehiculoRepository();
});
