import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitbox_control/features/clientes/domain/models/cliente.dart';
import 'package:pitbox_control/features/clientes/domain/repositories/cliente_repository.dart';
import 'package:pitbox_control/features/clientes/presentation/providers/clientes_provider.dart';
import 'package:pitbox_control/features/vehiculos/domain/models/vehiculo.dart';
import 'package:pitbox_control/features/vehiculos/domain/repositories/vehiculo_repository.dart';
import 'package:pitbox_control/features/vehiculos/presentation/providers/vehiculos_provider.dart';
import 'package:pitbox_control/shared/providers/repository_providers.dart';

void main() {
  test('carga datos semilla de clientes y vehículos', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final clientes = await container.read(clientesProvider.future);
    final vehiculos = await container.read(vehiculosProvider.future);

    expect(clientes.length, 4);
    expect(vehiculos.length, 5);
  });

  test('al eliminar cliente se eliminan sus vehículos asociados', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(clientesProvider.future);
    await container.read(vehiculosProvider.future);

    final clienteId = container.read(clientesProvider).value!.first.id;
    final vehiculosAntes = container.read(vehiculosByClienteIdProvider(clienteId));
    expect(vehiculosAntes, isNotEmpty);

    await container.read(clientesProvider.notifier).delete(clienteId);

    final clienteEliminado = container.read(clienteByIdProvider(clienteId));
    final vehiculosDespues = container.read(vehiculosByClienteIdProvider(clienteId));

    expect(clienteEliminado, isNull);
    expect(vehiculosDespues, isEmpty);
  });

  test('restaura cliente y vehículos si falla la eliminación del cliente', () async {
    final cliente = Cliente(
      id: 'cli-test',
      nombre: 'Prueba',
      apellido: 'Rollback',
      telefono: '70000000',
      fechaRegistro: DateTime(2026, 1, 1),
    );
    final vehiculo = Vehiculo(
      id: 'veh-test',
      clienteId: 'cli-test',
      placa: 'TEST-001',
      marca: 'Mazda',
      modelo: '3',
      anio: 2020,
      fechaRegistro: DateTime(2026, 1, 1),
    );

    final failingClienteRepository = _FailingDeleteClienteRepository(seed: [cliente]);
    final vehiculoRepository = _MemoryVehiculoRepository(seed: [vehiculo]);

    final container = ProviderContainer(
      overrides: [
        clienteRepositoryProvider.overrideWithValue(failingClienteRepository),
        vehiculoRepositoryProvider.overrideWithValue(vehiculoRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(clientesProvider.future);
    await container.read(vehiculosProvider.future);

    await expectLater(
      container.read(clientesProvider.notifier).delete(cliente.id),
      throwsA(isA<StateError>()),
    );

    expect(container.read(clienteByIdProvider(cliente.id)), isNotNull);
    expect(container.read(vehiculosByClienteIdProvider(cliente.id)), isNotEmpty);
  });

  test('repone vehículos faltantes si la eliminación falla de forma parcial', () async {
    final cliente = Cliente(
      id: 'cli-partial',
      nombre: 'Prueba',
      apellido: 'Parcial',
      telefono: '75555555',
      fechaRegistro: DateTime(2026, 1, 1),
    );
    final vehiculoA = Vehiculo(
      id: 'veh-partial-a',
      clienteId: 'cli-partial',
      placa: 'PART-001',
      marca: 'Toyota',
      modelo: 'Yaris',
      anio: 2019,
      fechaRegistro: DateTime(2026, 1, 1),
    );
    final vehiculoB = Vehiculo(
      id: 'veh-partial-b',
      clienteId: 'cli-partial',
      placa: 'PART-002',
      marca: 'Kia',
      modelo: 'Picanto',
      anio: 2021,
      fechaRegistro: DateTime(2026, 1, 1),
    );

    final clienteRepository = _MemoryClienteRepository(seed: [cliente]);
    final vehiculoRepository = _PartialFailVehiculoRepository(seed: [vehiculoA, vehiculoB]);

    final container = ProviderContainer(
      overrides: [
        clienteRepositoryProvider.overrideWithValue(clienteRepository),
        vehiculoRepositoryProvider.overrideWithValue(vehiculoRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(clientesProvider.future);
    await container.read(vehiculosProvider.future);

    await expectLater(
      container.read(clientesProvider.notifier).delete(cliente.id),
      throwsA(isA<StateError>()),
    );

    final clienteActual = container.read(clienteByIdProvider(cliente.id));
    final vehiculosActuales = container.read(vehiculosByClienteIdProvider(cliente.id));

    expect(clienteActual, isNotNull);
    expect(
      vehiculosActuales.map((item) => item.id).toList(growable: false),
      ['veh-partial-a', 'veh-partial-b'],
    );
  });

  test('eliminar un cliente inexistente no altera los vehículos', () async {
    final cliente = Cliente(
      id: 'cli-noop',
      nombre: 'Cliente',
      apellido: 'Noop',
      telefono: '76666666',
      fechaRegistro: DateTime(2026, 1, 1),
    );
    final vehiculo = Vehiculo(
      id: 'veh-noop',
      clienteId: 'cli-noop',
      placa: 'NOOP-001',
      marca: 'Nissan',
      modelo: 'Versa',
      anio: 2022,
      fechaRegistro: DateTime(2026, 1, 1),
    );

    final clienteRepository = _MemoryClienteRepository(seed: []);
    final vehiculoRepository = _MemoryVehiculoRepository(seed: [vehiculo]);

    final container = ProviderContainer(
      overrides: [
        clienteRepositoryProvider.overrideWithValue(clienteRepository),
        vehiculoRepositoryProvider.overrideWithValue(vehiculoRepository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(clientesProvider.future);
    await container.read(vehiculosProvider.future);

    await container.read(clientesProvider.notifier).delete(cliente.id);

    expect(container.read(vehiculosByClienteIdProvider(cliente.id)), isNotEmpty);
  });
}

class _FailingDeleteClienteRepository implements ClienteRepository {
  _FailingDeleteClienteRepository({required List<Cliente> seed}) : _clientes = [...seed];

  final List<Cliente> _clientes;

  @override
  Future<Cliente> create(Cliente cliente) async {
    _clientes.removeWhere((item) => item.id == cliente.id);
    _clientes.add(cliente);
    return cliente;
  }

  @override
  Future<void> delete(String id) async {
    _clientes.removeWhere((item) => item.id == id);
    throw StateError('Fallo controlado');
  }

  @override
  Future<List<Cliente>> getAll() async => List.unmodifiable(_clientes);

  @override
  Future<Cliente?> getById(String id) async {
    for (final cliente in _clientes) {
      if (cliente.id == id) {
        return cliente;
      }
    }
    return null;
  }

  @override
  Future<Cliente> update(Cliente cliente) async {
    final index = _clientes.indexWhere((item) => item.id == cliente.id);
    _clientes[index] = cliente;
    return cliente;
  }
}

class _MemoryClienteRepository implements ClienteRepository {
  _MemoryClienteRepository({required List<Cliente> seed}) : _clientes = [...seed];

  final List<Cliente> _clientes;

  @override
  Future<Cliente> create(Cliente cliente) async {
    _clientes.removeWhere((item) => item.id == cliente.id);
    _clientes.add(cliente);
    return cliente;
  }

  @override
  Future<void> delete(String id) async {
    _clientes.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<Cliente>> getAll() async => List.unmodifiable(_clientes);

  @override
  Future<Cliente?> getById(String id) async {
    for (final cliente in _clientes) {
      if (cliente.id == id) {
        return cliente;
      }
    }
    return null;
  }

  @override
  Future<Cliente> update(Cliente cliente) async {
    final index = _clientes.indexWhere((item) => item.id == cliente.id);
    _clientes[index] = cliente;
    return cliente;
  }
}

class _MemoryVehiculoRepository implements VehiculoRepository {
  _MemoryVehiculoRepository({required List<Vehiculo> seed}) : _vehiculos = [...seed];

  final List<Vehiculo> _vehiculos;

  @override
  Future<Vehiculo> create(Vehiculo vehiculo) async {
    _vehiculos.removeWhere((item) => item.id == vehiculo.id);
    _vehiculos.add(vehiculo);
    return vehiculo;
  }

  @override
  Future<void> delete(String id) async {
    _vehiculos.removeWhere((vehiculo) => vehiculo.id == id);
  }

  @override
  Future<void> deleteByClienteId(String clienteId) async {
    _vehiculos.removeWhere((vehiculo) => vehiculo.clienteId == clienteId);
  }

  @override
  Future<List<Vehiculo>> getAll() async => List.unmodifiable(_vehiculos);

  @override
  Future<List<Vehiculo>> getByClienteId(String clienteId) async {
    return _vehiculos.where((vehiculo) => vehiculo.clienteId == clienteId).toList(growable: false);
  }

  @override
  Future<Vehiculo?> getById(String id) async {
    for (final vehiculo in _vehiculos) {
      if (vehiculo.id == id) {
        return vehiculo;
      }
    }
    return null;
  }

  @override
  Future<Vehiculo> update(Vehiculo vehiculo) async {
    final index = _vehiculos.indexWhere((item) => item.id == vehiculo.id);
    _vehiculos[index] = vehiculo;
    return vehiculo;
  }
}

class _PartialFailVehiculoRepository extends _MemoryVehiculoRepository {
  _PartialFailVehiculoRepository({required List<Vehiculo> seed}) : super(seed: seed);

  @override
  Future<void> deleteByClienteId(String clienteId) async {
    final ids = (await getByClienteId(clienteId)).map((vehiculo) => vehiculo.id).toList(growable: false);
    if (ids.isNotEmpty) {
      await delete(ids.first);
    }
    throw StateError('Fallo parcial controlado');
  }
}
