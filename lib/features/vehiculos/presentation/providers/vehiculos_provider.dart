import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/repository_providers.dart';
import '../../domain/models/vehiculo.dart';

final vehiculosSearchQueryProvider = StateProvider<String>((ref) => '');

final vehiculosProvider = AsyncNotifierProvider<VehiculosNotifier, List<Vehiculo>>(() {
  return VehiculosNotifier();
});

final vehiculosFiltradosProvider = Provider<List<Vehiculo>>((ref) {
  final query = ref.watch(vehiculosSearchQueryProvider).trim().toLowerCase();
  final vehiculos = ref.watch(vehiculosProvider).valueOrNull ?? const <Vehiculo>[];

  if (query.isEmpty) {
    return vehiculos;
  }

  return vehiculos.where((vehiculo) {
    return vehiculo.placa.toLowerCase().contains(query) ||
        vehiculo.marca.toLowerCase().contains(query) ||
        vehiculo.modelo.toLowerCase().contains(query);
  }).toList(growable: false);
});

final vehiculoByIdProvider = Provider.family<Vehiculo?, String>((ref, vehiculoId) {
  final vehiculos = ref.watch(vehiculosProvider).valueOrNull ?? const <Vehiculo>[];
  for (final vehiculo in vehiculos) {
    if (vehiculo.id == vehiculoId) {
      return vehiculo;
    }
  }
  return null;
});

final vehiculosByClienteIdProvider = Provider.family<List<Vehiculo>, String>((ref, clienteId) {
  final vehiculos = ref.watch(vehiculosProvider).valueOrNull ?? const <Vehiculo>[];
  final result = vehiculos.where((vehiculo) => vehiculo.clienteId == clienteId).toList();
  result.sort((a, b) {
    final byFecha = a.fechaRegistro.compareTo(b.fechaRegistro);
    if (byFecha != 0) {
      return byFecha;
    }
    return a.id.compareTo(b.id);
  });
  return result;
});

class VehiculosNotifier extends AsyncNotifier<List<Vehiculo>> {
  @override
  Future<List<Vehiculo>> build() async {
    return ref.read(vehiculoRepositoryProvider).getAll();
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(() => ref.read(vehiculoRepositoryProvider).getAll());
  }

  Future<void> create({
    required String clienteId,
    required String placa,
    required String marca,
    required String modelo,
    required int anio,
    String? color,
    int? kilometraje,
  }) async {
    await ref.read(vehiculoRepositoryProvider).create(
          Vehiculo(
            id: '',
            clienteId: clienteId,
            placa: placa,
            marca: marca,
            modelo: modelo,
            anio: anio,
            color: _optional(color),
            kilometraje: kilometraje,
            fechaRegistro: DateTime.now(),
          ),
        );
    await reload();
  }

  Future<void> editarVehiculo({
    required String id,
    required DateTime fechaRegistro,
    required String clienteId,
    required String placa,
    required String marca,
    required String modelo,
    required int anio,
    String? color,
    int? kilometraje,
  }) async {
    await ref.read(vehiculoRepositoryProvider).update(
          Vehiculo(
            id: id,
            clienteId: clienteId,
            placa: placa,
            marca: marca,
            modelo: modelo,
            anio: anio,
            color: _optional(color),
            kilometraje: kilometraje,
            fechaRegistro: fechaRegistro,
          ),
        );
    await reload();
  }

  Future<void> delete(String vehiculoId) async {
    await ref.read(vehiculoRepositoryProvider).delete(vehiculoId);
    await reload();
  }

  Future<void> deleteByClienteId(String clienteId) async {
    await ref.read(vehiculoRepositoryProvider).deleteByClienteId(clienteId);
    await reload();
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
