import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/clientes/data/repositories/in_memory_cliente_repository.dart';
import '../../features/clientes/domain/repositories/cliente_repository.dart';
import '../../features/vehiculos/data/repositories/in_memory_vehiculo_repository.dart';
import '../../features/vehiculos/domain/repositories/vehiculo_repository.dart';

final InMemoryClienteRepository _clienteRepository = InMemoryClienteRepository();
final InMemoryVehiculoRepository _vehiculoRepository = InMemoryVehiculoRepository();

final clienteRepositoryProvider = Provider<ClienteRepository>((ref) {
  return _clienteRepository;
});

final vehiculoRepositoryProvider = Provider<VehiculoRepository>((ref) {
  return _vehiculoRepository;
});
