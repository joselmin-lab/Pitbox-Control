import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/repository_providers.dart';
import '../../../vehiculos/presentation/providers/vehiculos_provider.dart';
import '../../domain/models/cliente.dart';

final clientesSearchQueryProvider = StateProvider<String>((ref) => '');

final clientesProvider = AsyncNotifierProvider<ClientesNotifier, List<Cliente>>(() {
  return ClientesNotifier();
});

final clientesFiltradosProvider = Provider<List<Cliente>>((ref) {
  final query = ref.watch(clientesSearchQueryProvider).trim().toLowerCase();
  final clientes = ref.watch(clientesProvider).valueOrNull ?? const <Cliente>[];

  if (query.isEmpty) {
    return clientes;
  }

  return clientes.where((cliente) {
    return cliente.nombreCompleto.toLowerCase().contains(query) || cliente.telefono.toLowerCase().contains(query);
  }).toList(growable: false);
});

final clienteByIdProvider = Provider.family<Cliente?, String>((ref, clienteId) {
  final clientes = ref.watch(clientesProvider).valueOrNull ?? const <Cliente>[];
  for (final cliente in clientes) {
    if (cliente.id == clienteId) {
      return cliente;
    }
  }
  return null;
});

class ClientesNotifier extends AsyncNotifier<List<Cliente>> {
  @override
  Future<List<Cliente>> build() async {
    return ref.read(clienteRepositoryProvider).getAll();
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(() => ref.read(clienteRepositoryProvider).getAll());
  }

  Future<void> create({
    required String nombre,
    required String apellido,
    required String telefono,
    String? email,
    String? direccion,
  }) async {
    await ref.read(clienteRepositoryProvider).create(
          Cliente(
            id: '',
            nombre: nombre,
            apellido: apellido,
            telefono: telefono,
            email: _optional(email),
            direccion: _optional(direccion),
            fechaRegistro: DateTime.now(),
          ),
        );
    await reload();
  }

  Future<void> update({
    required String id,
    required DateTime fechaRegistro,
    required String nombre,
    required String apellido,
    required String telefono,
    String? email,
    String? direccion,
  }) async {
    await ref.read(clienteRepositoryProvider).update(
          Cliente(
            id: id,
            nombre: nombre,
            apellido: apellido,
            telefono: telefono,
            email: _optional(email),
            direccion: _optional(direccion),
            fechaRegistro: fechaRegistro,
          ),
        );
    await reload();
  }

  Future<void> delete(String clienteId) async {
    final clienteRepository = ref.read(clienteRepositoryProvider);
    final vehiculoRepository = ref.read(vehiculoRepositoryProvider);

    final clienteSnapshot = await clienteRepository.getById(clienteId);
    if (clienteSnapshot == null) {
      return;
    }
    final vehiculosSnapshot = await vehiculoRepository.getByClienteId(clienteId);

    try {
      // Se eliminan vehículos primero para evitar dejar huérfanos si falla el segundo paso.
      await vehiculoRepository.deleteByClienteId(clienteId);
      await clienteRepository.delete(clienteId);
    } catch (_) {
      // En caso de error, se restaura el estado previo en memoria.
      if (await clienteRepository.getById(clienteId) == null) {
        await clienteRepository.create(clienteSnapshot);
      }
      final remainingVehiculos = await vehiculoRepository.getByClienteId(clienteId);
      final remainingIds = remainingVehiculos.map((vehiculo) => vehiculo.id).toList(growable: false);
      final snapshotIds = vehiculosSnapshot.map((vehiculo) => vehiculo.id).toList(growable: false);
      final sameOrder =
          remainingIds.length == snapshotIds.length &&
          List.generate(remainingIds.length, (index) => remainingIds[index] == snapshotIds[index]).every(
            (isEqual) => isEqual,
          );
      if (!sameOrder) {
        for (final vehiculo in remainingVehiculos) {
          await vehiculoRepository.delete(vehiculo.id);
        }
        for (final vehiculo in vehiculosSnapshot) {
          await vehiculoRepository.create(vehiculo);
        }
      }
      rethrow;
    } finally {
      await ref.read(vehiculosProvider.notifier).reload();
      await reload();
    }
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
