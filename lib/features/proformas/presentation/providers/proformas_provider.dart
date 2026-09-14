import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/repository_providers.dart';
import '../../domain/models/proforma.dart';

final proformasSearchQueryProvider = StateProvider<String>((ref) => '');
final proformasEstadoFilterProvider = StateProvider<ProformaEstado?>((ref) => null);
final proformasClienteFilterProvider = StateProvider<String?>((ref) => null);
final proformasDateRangeFilterProvider = StateProvider<DateTimeRange?>((ref) => null);

final proformasProvider = AsyncNotifierProvider<ProformasNotifier, List<Proforma>>(() {
  return ProformasNotifier();
});

final proformasFiltradasProvider = Provider<List<Proforma>>((ref) {
  final proformas = ref.watch(proformasProvider).valueOrNull ?? const <Proforma>[];
  final query = ref.watch(proformasSearchQueryProvider).trim().toLowerCase();
  final estado = ref.watch(proformasEstadoFilterProvider);
  final clienteId = ref.watch(proformasClienteFilterProvider);
  final dateRange = ref.watch(proformasDateRangeFilterProvider);

  return proformas.where((proforma) {
    final matchesQuery = query.isEmpty || proforma.numero.toLowerCase().contains(query);
    final matchesEstado = estado == null || proforma.estado == estado;
    final matchesCliente = clienteId == null || clienteId.isEmpty || proforma.clienteId == clienteId;
    final matchesDate = dateRange == null ||
        (!proforma.fecha.isBefore(_startOfDay(dateRange.start)) &&
            !proforma.fecha.isAfter(_endOfDay(dateRange.end)));
    return matchesQuery && matchesEstado && matchesCliente && matchesDate;
  }).toList(growable: false);
});

final proformaByIdProvider = Provider.family<Proforma?, String>((ref, proformaId) {
  final proformas = ref.watch(proformasProvider).valueOrNull ?? const <Proforma>[];
  for (final proforma in proformas) {
    if (proforma.id == proformaId) {
      return proforma;
    }
  }
  return null;
});

final proformaEditorProvider = StateProvider<Proforma?>((ref) => null);

final proformaEditorTotalProvider = Provider<double>((ref) {
  final draft = ref.watch(proformaEditorProvider);
  return draft?.totalFinal ?? 0;
});

class ProformasNotifier extends AsyncNotifier<List<Proforma>> {
  @override
  Future<List<Proforma>> build() async {
    return ref.read(proformaRepositoryProvider).getAll();
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(() => ref.read(proformaRepositoryProvider).getAll());
  }

  Future<String> generarNumero(DateTime fecha) {
    return ref.read(proformaRepositoryProvider).generarSiguienteNumero(anio: fecha.year);
  }

  Future<Proforma> crearProforma(Proforma proforma) async {
    final created = await ref.read(proformaRepositoryProvider).create(proforma);
    await reload();
    return created;
  }

  Future<Proforma> editarProforma(Proforma proforma) async {
    final updated = await ref.read(proformaRepositoryProvider).update(proforma);
    await reload();
    return updated;
  }

  Future<void> eliminarProforma(String id) async {
    await ref.read(proformaRepositoryProvider).delete(id);
    await reload();
  }

  Future<void> cambiarEstado({
    required Proforma proforma,
    required ProformaEstado estado,
  }) async {
    await editarProforma(proforma.copyWith(estado: estado));
  }
}

DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _endOfDay(DateTime date) => DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
