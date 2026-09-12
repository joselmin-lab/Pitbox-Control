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
    state = const AsyncValue.loading();
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
    // Se borra en cascada en memoria para mantener consistente la relación 1:N.
    await ref.read(vehiculosProvider.notifier).deleteByClienteId(clienteId);
    await ref.read(clienteRepositoryProvider).delete(clienteId);
    await reload();
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
