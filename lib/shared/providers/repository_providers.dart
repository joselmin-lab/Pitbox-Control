import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/clientes/data/repositories/in_memory_cliente_repository.dart';
import '../../features/clientes/domain/repositories/cliente_repository.dart';
import '../../features/vehiculos/data/repositories/in_memory_vehiculo_repository.dart';
import '../../features/vehiculos/domain/repositories/vehiculo_repository.dart';
import '../data/in_memory_pitbox_store.dart';

final inMemoryPitboxStoreProvider = Provider<InMemoryPitboxStore>((ref) {
  return InMemoryPitboxStore.seeded();
});

final _inMemoryClienteRepositoryProvider = Provider<InMemoryClienteRepository>((ref) {
  return InMemoryClienteRepository(ref.watch(inMemoryPitboxStoreProvider));
});

final _inMemoryVehiculoRepositoryProvider = Provider<InMemoryVehiculoRepository>((ref) {
  return InMemoryVehiculoRepository(ref.watch(inMemoryPitboxStoreProvider));
});

final clienteRepositoryProvider = Provider<ClienteRepository>((ref) {
  return ref.watch(_inMemoryClienteRepositoryProvider);
});

final vehiculoRepositoryProvider = Provider<VehiculoRepository>((ref) {
  return ref.watch(_inMemoryVehiculoRepositoryProvider);
});
