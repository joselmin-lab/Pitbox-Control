import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/clientes/data/repositories/in_memory_cliente_repository.dart';
import '../../features/clientes/domain/repositories/cliente_repository.dart';
import '../../features/vehiculos/data/repositories/in_memory_vehiculo_repository.dart';
import '../../features/vehiculos/domain/repositories/vehiculo_repository.dart';

final _inMemoryClienteRepositoryProvider = Provider<InMemoryClienteRepository>((ref) {
  return InMemoryClienteRepository();
});

final _inMemoryVehiculoRepositoryProvider = Provider<InMemoryVehiculoRepository>((ref) {
  return InMemoryVehiculoRepository();
});

final clienteRepositoryProvider = Provider<ClienteRepository>((ref) {
  return ref.watch(_inMemoryClienteRepositoryProvider);
});

final vehiculoRepositoryProvider = Provider<VehiculoRepository>((ref) {
  return ref.watch(_inMemoryVehiculoRepositoryProvider);
});
