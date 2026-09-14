import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/providers/repository_providers.dart';
import '../../domain/models/recepcion_vehiculo.dart';

final recepcionesSearchQueryProvider = StateProvider<String>((ref) => '');
final recepcionesEstadoFilterProvider = StateProvider<RecepcionEstado?>((ref) => null);
final recepcionesClienteFilterProvider = StateProvider<String?>((ref) => null);
final recepcionesDateRangeFilterProvider = StateProvider<DateTimeRange?>((ref) => null);

final recepcionesProvider = AsyncNotifierProvider<RecepcionesNotifier, List<RecepcionVehiculo>>(() {
  return RecepcionesNotifier();
});

final recepcionesFiltradasProvider = Provider<List<RecepcionVehiculo>>((ref) {
  final recepciones = ref.watch(recepcionesProvider).valueOrNull ?? const <RecepcionVehiculo>[];
  final estado = ref.watch(recepcionesEstadoFilterProvider);
  final clienteId = ref.watch(recepcionesClienteFilterProvider);
  final dateRange = ref.watch(recepcionesDateRangeFilterProvider);

  return recepciones.where((recepcion) {
    final matchesEstado = estado == null || recepcion.estado == estado;
    final matchesCliente = clienteId == null || clienteId.isEmpty || recepcion.clienteId == clienteId;
    final matchesDate = dateRange == null ||
        (!recepcion.fechaIngreso.isBefore(_startOfDay(dateRange.start)) &&
            !recepcion.fechaIngreso.isAfter(_endOfDay(dateRange.end)));
    return matchesEstado && matchesCliente && matchesDate;
  }).toList(growable: false);
});

final recepcionByIdProvider = Provider.family<RecepcionVehiculo?, String>((ref, recepcionId) {
  final recepciones = ref.watch(recepcionesProvider).valueOrNull ?? const <RecepcionVehiculo>[];
  for (final recepcion in recepciones) {
    if (recepcion.id == recepcionId) {
      return recepcion;
    }
  }
  return null;
});

final recepcionFormProvider =
    NotifierProvider.autoDispose<RecepcionFormNotifier, RecepcionFormState>(RecepcionFormNotifier.new);

class RecepcionesNotifier extends AsyncNotifier<List<RecepcionVehiculo>> {
  @override
  Future<List<RecepcionVehiculo>> build() async {
    return ref.read(recepcionRepositoryProvider).getAll();
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(() => ref.read(recepcionRepositoryProvider).getAll());
  }

  Future<RecepcionVehiculo> crear(RecepcionVehiculo recepcion) async {
    final created = await ref.read(recepcionRepositoryProvider).create(recepcion);
    await reload();
    return created;
  }

  Future<RecepcionVehiculo> editar(RecepcionVehiculo recepcion) async {
    final updated = await ref.read(recepcionRepositoryProvider).update(recepcion);
    await reload();
    return updated;
  }

  Future<RecepcionVehiculo> cambiarEstado({
    required RecepcionVehiculo recepcion,
    required RecepcionEstado estado,
  }) async {
    return editar(recepcion.copyWith(estado: estado));
  }
}

class RecepcionFormNotifier extends AutoDisposeNotifier<RecepcionFormState> {
  @override
  RecepcionFormState build() => RecepcionFormState.initial();

  void initialize(RecepcionVehiculo? recepcion) {
    final nextState = recepcion == null ? RecepcionFormState.initial() : RecepcionFormState.fromRecepcion(recepcion);
    state = nextState;
  }

  void setCliente(String? clienteId) {
    state = state.copyWith(
      clienteId: clienteId,
      clearClienteId: clienteId == null,
      clearVehiculoId: true,
    );
  }

  void setVehiculo(String? vehiculoId, {String? kilometrajeSugerido}) {
    state = state.copyWith(
      vehiculoId: vehiculoId,
      clearVehiculoId: vehiculoId == null,
      kilometraje: state.kilometraje.trim().isNotEmpty ? state.kilometraje : (kilometrajeSugerido ?? ''),
    );
  }

  void setFechaIngreso(DateTime value) {
    state = state.copyWith(fechaIngreso: value);
  }

  void setFechaSalidaEstimada(DateTime? value) {
    state = state.copyWith(
      fechaSalidaEstimada: value,
      clearFechaSalidaEstimada: value == null,
    );
  }

  void setKilometraje(String value) {
    state = state.copyWith(kilometraje: value);
  }

  void setIngresoEnGrua(bool value) {
    state = state.copyWith(ingresoEnGrua: value);
  }

  void setTrabajoARealizar(String value) {
    state = state.copyWith(trabajoARealizar: value);
  }

  void setObservaciones(String value) {
    state = state.copyWith(observaciones: value);
  }

  void toggleSistema(String clave) {
    final updated = [
      for (final item in state.checklistSistemas)
        if (item.clave == clave) item.copyWith(marcado: !item.marcado) else item,
    ];
    state = state.copyWith(checklistSistemas: updated);
  }

  void toggleInventario(String itemNombre) {
    final updated = [
      for (final item in state.inventario)
        if (item.item == itemNombre) item.copyWith(marcado: !item.marcado) else item,
    ];
    state = state.copyWith(inventario: updated);
  }

  void setNivelCombustible(double value) {
    state = state.copyWith(nivelCombustible: value.clamp(0.0, 1.0).toDouble());
  }

  void addDano({
    required RecepcionVistaVehiculo vista,
    required Offset puntoRelativo,
  }) {
    final nuevos = [
      ...state.danosPreexistentes,
      DanoVehiculoMarcado(
        vista: vista,
        x: puntoRelativo.dx.clamp(0.0, 1.0).toDouble(),
        y: puntoRelativo.dy.clamp(0.0, 1.0).toDouble(),
      ),
    ];
    state = state.copyWith(danosPreexistentes: nuevos);
  }

  void clearDanosVista(RecepcionVistaVehiculo vista) {
    state = state.copyWith(
      danosPreexistentes: state.danosPreexistentes.where((item) => item.vista != vista).toList(growable: false),
    );
  }

  void undoDanoVista(RecepcionVistaVehiculo vista) {
    final current = state.danosPreexistentes.where((item) => item.vista == vista).toList(growable: false);
    if (current.isEmpty) {
      return;
    }
    final updated = state.danosPreexistentes.toList(growable: true);
    updated.removeLastWhere((item) => item.vista == vista);
    state = state.copyWith(danosPreexistentes: updated);
  }

  void addFotografiasPendientes(List<RecepcionArchivoLocal> fotos) {
    state = state.copyWith(
      fotografiasPendientes: [...state.fotografiasPendientes, ...fotos],
    );
  }

  void removeFotografiaPendiente(String id) {
    state = state.copyWith(
      fotografiasPendientes: state.fotografiasPendientes.where((item) => item.id != id).toList(growable: false),
    );
  }

  void removeFotografiaExistente(String url) {
    state = state.copyWith(
      fotografiasExistentes: state.fotografiasExistentes.where((item) => item != url).toList(growable: false),
    );
  }

  void setFirmaPrestador(List<List<Offset>> trazos) {
    state = state.copyWith(firmaPrestadorTrazos: _copyTrazos(trazos));
  }

  void setFirmaCliente(List<List<Offset>> trazos) {
    state = state.copyWith(firmaClienteTrazos: _copyTrazos(trazos));
  }

  static List<List<Offset>> _copyTrazos(List<List<Offset>> source) {
    return source.map((stroke) => stroke.toList(growable: false)).toList(growable: false);
  }
}

class RecepcionArchivoLocal {
  const RecepcionArchivoLocal({
    required this.id,
    required this.nombreArchivo,
    required this.bytes,
  });

  final String id;
  final String nombreArchivo;
  final Uint8List bytes;
}

class RecepcionFormState {
  const RecepcionFormState({
    this.recepcionId,
    required this.numero,
    this.clienteId,
    this.vehiculoId,
    required this.fechaIngreso,
    required this.fechaSalidaEstimada,
    required this.kilometraje,
    required this.ingresoEnGrua,
    required this.trabajoARealizar,
    required this.observaciones,
    required this.checklistSistemas,
    required this.inventario,
    required this.nivelCombustible,
    required this.danosPreexistentes,
    required this.fotografiasExistentes,
    required this.fotografiasPendientes,
    required this.firmaPrestadorTrazos,
    required this.firmaClienteTrazos,
    this.firmaPrestadorUrl,
    this.firmaClienteUrl,
    required this.estado,
    required this.fechaCreacion,
  });

  final String? recepcionId;
  final String numero;
  final String? clienteId;
  final String? vehiculoId;
  final DateTime fechaIngreso;
  final DateTime? fechaSalidaEstimada;
  final String kilometraje;
  final bool ingresoEnGrua;
  final String trabajoARealizar;
  final String observaciones;
  final List<RecepcionChecklistItem> checklistSistemas;
  final List<RecepcionInventarioItem> inventario;
  final double nivelCombustible;
  final List<DanoVehiculoMarcado> danosPreexistentes;
  final List<String> fotografiasExistentes;
  final List<RecepcionArchivoLocal> fotografiasPendientes;
  final List<List<Offset>> firmaPrestadorTrazos;
  final List<List<Offset>> firmaClienteTrazos;
  final String? firmaPrestadorUrl;
  final String? firmaClienteUrl;
  final RecepcionEstado estado;
  final DateTime fechaCreacion;

  bool get tieneFirmaPrestador =>
      firmaPrestadorTrazos.any((stroke) => stroke.isNotEmpty) || (firmaPrestadorUrl?.trim().isNotEmpty ?? false);

  bool get tieneFirmaCliente =>
      firmaClienteTrazos.any((stroke) => stroke.isNotEmpty) || (firmaClienteUrl?.trim().isNotEmpty ?? false);

  factory RecepcionFormState.initial() {
    return RecepcionFormState(
      numero: '',
      fechaIngreso: DateTime.now(),
      fechaSalidaEstimada: DateTime.now().add(const Duration(days: 1)),
      kilometraje: '',
      ingresoEnGrua: false,
      trabajoARealizar: '',
      observaciones: '',
      checklistSistemas: recepcionChecklistBase,
      inventario: recepcionInventarioBase,
      nivelCombustible: 0.25,
      danosPreexistentes: const <DanoVehiculoMarcado>[],
      fotografiasExistentes: const <String>[],
      fotografiasPendientes: const <RecepcionArchivoLocal>[],
      firmaPrestadorTrazos: const <List<Offset>>[],
      firmaClienteTrazos: const <List<Offset>>[],
      estado: RecepcionEstado.abierta,
      fechaCreacion: DateTime.now(),
    );
  }

  factory RecepcionFormState.fromRecepcion(RecepcionVehiculo recepcion) {
    return RecepcionFormState(
      recepcionId: recepcion.id,
      numero: recepcion.numero,
      clienteId: recepcion.clienteId,
      vehiculoId: recepcion.vehiculoId,
      fechaIngreso: recepcion.fechaIngreso,
      fechaSalidaEstimada: recepcion.fechaSalidaEstimada,
      kilometraje: recepcion.kilometraje ?? '',
      ingresoEnGrua: recepcion.ingresoEnGrua,
      trabajoARealizar: recepcion.trabajoARealizar ?? '',
      observaciones: recepcion.observaciones ?? '',
      checklistSistemas: recepcion.checklistSistemas,
      inventario: recepcion.inventario,
      nivelCombustible: recepcion.nivelCombustible,
      danosPreexistentes: recepcion.danosPreexistentes,
      fotografiasExistentes: recepcion.fotografias,
      fotografiasPendientes: const <RecepcionArchivoLocal>[],
      firmaPrestadorTrazos: const <List<Offset>>[],
      firmaClienteTrazos: const <List<Offset>>[],
      firmaPrestadorUrl: recepcion.firmaPrestadorUrl,
      firmaClienteUrl: recepcion.firmaClienteUrl,
      estado: recepcion.estado,
      fechaCreacion: recepcion.fechaCreacion,
    );
  }

  RecepcionVehiculo toRecepcion({
    required List<String> fotografias,
    required String? firmaPrestadorUrl,
    required String? firmaClienteUrl,
  }) {
    return RecepcionVehiculo(
      id: recepcionId ?? '',
      numero: numero,
      clienteId: clienteId ?? '',
      vehiculoId: vehiculoId ?? '',
      fechaIngreso: fechaIngreso,
      fechaSalidaEstimada: fechaSalidaEstimada,
      kilometraje: _optional(kilometraje),
      ingresoEnGrua: ingresoEnGrua,
      trabajoARealizar: _optional(trabajoARealizar),
      observaciones: _optional(observaciones),
      checklistSistemas: checklistSistemas,
      inventario: inventario,
      nivelCombustible: nivelCombustible,
      danosPreexistentes: danosPreexistentes,
      fotografias: fotografias,
      firmaPrestadorUrl: firmaPrestadorUrl,
      firmaClienteUrl: firmaClienteUrl,
      estado: estado,
      fechaCreacion: fechaCreacion,
    );
  }

  RecepcionFormState copyWith({
    String? recepcionId,
    String? numero,
    String? clienteId,
    bool clearClienteId = false,
    String? vehiculoId,
    bool clearVehiculoId = false,
    DateTime? fechaIngreso,
    DateTime? fechaSalidaEstimada,
    bool clearFechaSalidaEstimada = false,
    String? kilometraje,
    bool? ingresoEnGrua,
    String? trabajoARealizar,
    String? observaciones,
    List<RecepcionChecklistItem>? checklistSistemas,
    List<RecepcionInventarioItem>? inventario,
    double? nivelCombustible,
    List<DanoVehiculoMarcado>? danosPreexistentes,
    List<String>? fotografiasExistentes,
    List<RecepcionArchivoLocal>? fotografiasPendientes,
    List<List<Offset>>? firmaPrestadorTrazos,
    List<List<Offset>>? firmaClienteTrazos,
    String? firmaPrestadorUrl,
    String? firmaClienteUrl,
    RecepcionEstado? estado,
    DateTime? fechaCreacion,
  }) {
    return RecepcionFormState(
      recepcionId: recepcionId ?? this.recepcionId,
      numero: numero ?? this.numero,
      clienteId: clearClienteId ? null : (clienteId ?? this.clienteId),
      vehiculoId: clearVehiculoId ? null : (vehiculoId ?? this.vehiculoId),
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      fechaSalidaEstimada: clearFechaSalidaEstimada
          ? null
          : (fechaSalidaEstimada ?? this.fechaSalidaEstimada),
      kilometraje: kilometraje ?? this.kilometraje,
      ingresoEnGrua: ingresoEnGrua ?? this.ingresoEnGrua,
      trabajoARealizar: trabajoARealizar ?? this.trabajoARealizar,
      observaciones: observaciones ?? this.observaciones,
      checklistSistemas: checklistSistemas ?? this.checklistSistemas,
      inventario: inventario ?? this.inventario,
      nivelCombustible: nivelCombustible ?? this.nivelCombustible,
      danosPreexistentes: danosPreexistentes ?? this.danosPreexistentes,
      fotografiasExistentes: fotografiasExistentes ?? this.fotografiasExistentes,
      fotografiasPendientes: fotografiasPendientes ?? this.fotografiasPendientes,
      firmaPrestadorTrazos: firmaPrestadorTrazos ?? this.firmaPrestadorTrazos,
      firmaClienteTrazos: firmaClienteTrazos ?? this.firmaClienteTrazos,
      firmaPrestadorUrl: firmaPrestadorUrl ?? this.firmaPrestadorUrl,
      firmaClienteUrl: firmaClienteUrl ?? this.firmaClienteUrl,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _endOfDay(DateTime date) => DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

extension<T> on List<T> {
  void removeLastWhere(bool Function(T item) test) {
    for (var index = length - 1; index >= 0; index--) {
      if (test(this[index])) {
        removeAt(index);
        return;
      }
    }
  }
}
