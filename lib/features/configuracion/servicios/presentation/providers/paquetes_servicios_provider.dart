import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/providers/repository_providers.dart';
import '../../domain/models/paquete_servicio.dart';

final paquetesServiciosSearchQueryProvider = StateProvider<String>((ref) => '');

final paquetesServiciosProvider = AsyncNotifierProvider<PaquetesServiciosNotifier, List<PaqueteServicio>>(() {
  return PaquetesServiciosNotifier();
});

final paquetesServiciosFiltradosProvider = Provider<List<PaqueteServicio>>((ref) {
  final query = ref.watch(paquetesServiciosSearchQueryProvider).trim().toLowerCase();
  final paquetes = ref.watch(paquetesServiciosProvider).valueOrNull ?? const <PaqueteServicio>[];

  if (query.isEmpty) {
    return paquetes;
  }
  return paquetes
      .where((paquete) => paquete.nombre.toLowerCase().contains(query))
      .toList(growable: false);
});

final paqueteServicioByIdProvider = Provider.family<PaqueteServicio?, String>((ref, paqueteId) {
  final paquetes = ref.watch(paquetesServiciosProvider).valueOrNull ?? const <PaqueteServicio>[];
  for (final paquete in paquetes) {
    if (paquete.id == paqueteId) {
      return paquete;
    }
  }
  return null;
});

final precioTotalPaqueteProvider = Provider.family<double, String>((ref, paqueteId) {
  final paquete = ref.watch(paqueteServicioByIdProvider(paqueteId));
  if (paquete == null) {
    return 0;
  }
  return paquete.precioTotalCalculado;
});

class PaquetesServiciosNotifier extends AsyncNotifier<List<PaqueteServicio>> {
  @override
  Future<List<PaqueteServicio>> build() async {
    return ref.read(paqueteServicioRepositoryProvider).getAll();
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(() => ref.read(paqueteServicioRepositoryProvider).getAll());
  }

  Future<void> create({
    required String nombre,
    String? descripcion,
    double? precioManual,
    bool activo = true,
    required Map<String, int> servicioCantidad,
  }) async {
    final repository = ref.read(paqueteServicioRepositoryProvider);
    final paquete = await repository.create(
      PaqueteServicio(
        id: '',
        nombre: nombre,
        descripcion: _optional(descripcion),
        precioManual: precioManual,
        activo: activo,
        fechaCreacion: DateTime.now(),
      ),
    );

    for (final entry in servicioCantidad.entries) {
      await repository.addServicioToPaquete(
        paqueteId: paquete.id,
        servicioId: entry.key,
        cantidad: entry.value,
      );
    }

    await reload();
  }

  Future<void> editarPaquete({
    required String id,
    required DateTime fechaCreacion,
    required String nombre,
    String? descripcion,
    double? precioManual,
    required bool activo,
    required Map<String, int> servicioCantidad,
  }) async {
    final repository = ref.read(paqueteServicioRepositoryProvider);
    await repository.update(
      PaqueteServicio(
        id: id,
        nombre: nombre,
        descripcion: _optional(descripcion),
        precioManual: precioManual,
        activo: activo,
        fechaCreacion: fechaCreacion,
      ),
    );

    await repository.clearServiciosDePaquete(id);
    for (final entry in servicioCantidad.entries) {
      await repository.addServicioToPaquete(
        paqueteId: id,
        servicioId: entry.key,
        cantidad: entry.value,
      );
    }

    await reload();
  }

  Future<void> delete(String paqueteId) async {
    await ref.read(paqueteServicioRepositoryProvider).delete(paqueteId);
    await reload();
  }

  Future<void> asociarServicio({
    required String paqueteId,
    required String servicioId,
    int cantidad = 1,
  }) async {
    await ref.read(paqueteServicioRepositoryProvider).addServicioToPaquete(
          paqueteId: paqueteId,
          servicioId: servicioId,
          cantidad: cantidad,
        );
    await reload();
  }

  Future<void> desasociarServicio({
    required String paqueteId,
    required String servicioId,
  }) async {
    await ref.read(paqueteServicioRepositoryProvider).removeServicioDePaquete(
          paqueteId: paqueteId,
          servicioId: servicioId,
        );
    await reload();
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
