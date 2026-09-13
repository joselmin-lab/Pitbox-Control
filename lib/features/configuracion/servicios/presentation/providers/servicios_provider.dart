import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/servicio.dart';
import 'paquetes_servicios_provider.dart';
import '../../../../../shared/providers/repository_providers.dart';

final serviciosSearchQueryProvider = StateProvider<String>((ref) => '');
final serviciosCategoriaFilterProvider = StateProvider<String?>((ref) => null);

final serviciosProvider = AsyncNotifierProvider<ServiciosNotifier, List<Servicio>>(() {
  return ServiciosNotifier();
});

final serviciosFiltradosProvider = Provider<List<Servicio>>((ref) {
  final query = ref.watch(serviciosSearchQueryProvider).trim().toLowerCase();
  final categoria = ref.watch(serviciosCategoriaFilterProvider)?.trim().toLowerCase();
  final servicios = ref.watch(serviciosProvider).valueOrNull ?? const <Servicio>[];

  return servicios.where((servicio) {
    final matchesQuery = query.isEmpty ||
        servicio.nombre.toLowerCase().contains(query) ||
        (servicio.categoria ?? '').toLowerCase().contains(query);
    final matchesCategoria =
        categoria == null || categoria.isEmpty || (servicio.categoria ?? '').toLowerCase() == categoria;
    return matchesQuery && matchesCategoria;
  }).toList(growable: false);
});

final servicioByIdProvider = Provider.family<Servicio?, String>((ref, servicioId) {
  final servicios = ref.watch(serviciosProvider).valueOrNull ?? const <Servicio>[];
  for (final servicio in servicios) {
    if (servicio.id == servicioId) {
      return servicio;
    }
  }
  return null;
});

class ServiciosCsvImportResult {
  const ServiciosCsvImportResult({
    required this.created,
    required this.updated,
    required this.skipped,
    required this.errors,
  });

  final int created;
  final int updated;
  final int skipped;
  final List<String> errors;
}

class ServiciosNotifier extends AsyncNotifier<List<Servicio>> {
  @override
  Future<List<Servicio>> build() async {
    return ref.read(servicioRepositoryProvider).getAll();
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(() => ref.read(servicioRepositoryProvider).getAll());
  }

  Future<void> create({
    required String nombre,
    String? descripcion,
    required double precio,
    String? categoria,
    bool activo = true,
  }) async {
    await ref.read(servicioRepositoryProvider).create(
          Servicio(
            id: '',
            nombre: nombre,
            descripcion: _optional(descripcion),
            precio: precio,
            categoria: _optional(categoria),
            activo: activo,
            fechaCreacion: DateTime.now(),
          ),
        );
    await reload();
  }

  Future<void> editarServicio({
    required String id,
    required DateTime fechaCreacion,
    required String nombre,
    String? descripcion,
    required double precio,
    String? categoria,
    required bool activo,
  }) async {
    await ref.read(servicioRepositoryProvider).update(
          Servicio(
            id: id,
            nombre: nombre,
            descripcion: _optional(descripcion),
            precio: precio,
            categoria: _optional(categoria),
            activo: activo,
            fechaCreacion: fechaCreacion,
          ),
        );
    await reload();
  }

  Future<void> delete(String servicioId) async {
    await ref.read(servicioRepositoryProvider).delete(servicioId);
    await reload();
    await ref.read(paquetesServiciosProvider.notifier).reload();
  }

  Future<void> exportarCsv() async {
    final servicios = state.valueOrNull ?? await ref.read(serviciosProvider.future);
    final serviciosParaExportar = servicios ?? const <Servicio>[];

    final rows = <List<dynamic>>[
      const ['nombre', 'descripcion', 'precio', 'categoria', 'activo'],
      ...serviciosParaExportar.map(
        (servicio) => [
          servicio.nombre,
          servicio.descripcion ?? '',
          servicio.precio.toStringAsFixed(2),
          servicio.categoria ?? '',
          servicio.activo ? 'true' : 'false',
        ],
      ),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final bytes = Uint8List.fromList(utf8.encode(csv));

    await FileSaver.instance.saveFile(
      name: 'servicios_${DateTime.now().millisecondsSinceEpoch}',
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
  }

  Future<ServiciosCsvImportResult?> importarCsvDesdeArchivo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final fileBytes = result.files.single.bytes;
    if (fileBytes == null || fileBytes.isEmpty) {
      return const ServiciosCsvImportResult(
        created: 0,
        updated: 0,
        skipped: 0,
        errors: ['El archivo seleccionado está vacío o no pudo leerse.'],
      );
    }

    final text = utf8.decode(fileBytes, allowMalformed: true);
    return importarCsv(text);
  }

  Future<ServiciosCsvImportResult> importarCsv(String csvContent) async {
    List<List<dynamic>> parsed;
    try {
      parsed = const CsvToListConverter(shouldParseNumbers: false).convert(csvContent);
    } catch (error) {
      return ServiciosCsvImportResult(
        created: 0,
        updated: 0,
        skipped: 0,
        errors: ['CSV inválido: $error'],
      );
    }

    if (parsed.isEmpty) {
      return const ServiciosCsvImportResult(
        created: 0,
        updated: 0,
        skipped: 0,
        errors: ['El CSV no contiene filas.'],
      );
    }

    final headers = parsed.first.map((item) => item.toString().trim().toLowerCase()).toList(growable: false);
    const expected = ['nombre', 'descripcion', 'precio', 'categoria', 'activo'];
    if (headers.length != expected.length ||
        headers[0] != expected[0] ||
        headers[1] != expected[1] ||
        headers[2] != expected[2] ||
        headers[3] != expected[3] ||
        headers[4] != expected[4]) {
      return const ServiciosCsvImportResult(
        created: 0,
        updated: 0,
        skipped: 0,
        errors: ['Encabezado inválido. Formato esperado: nombre,descripcion,precio,categoria,activo'],
      );
    }

    var created = 0;
    var updated = 0;
    var skipped = 0;
    final errors = <String>[];

    final repository = ref.read(servicioRepositoryProvider);
    final existentes = await repository.getAll();
    final byKey = {
      for (final servicio in existentes)
        _buildCsvLookupKey(servicio.nombre, servicio.categoria): servicio,
    };
    final seenCsvKeys = <String>{};

    for (var i = 1; i < parsed.length; i++) {
      final row = parsed[i];
      if (row.isEmpty || row.every((value) => value.toString().trim().isEmpty)) {
        skipped++;
        continue;
      }

      try {
        final nombre = _cellAt(row, 0).trim();
        final descripcion = _emptyToNull(_cellAt(row, 1));
        final precioValue = _cellAt(row, 2).replaceAll(',', '.').trim();
        final categoria = _emptyToNull(_cellAt(row, 3));
        final activo = _parseBoolCsv(_cellAt(row, 4));

        if (nombre.isEmpty) {
          throw const FormatException('El nombre es obligatorio.');
        }
        final precio = double.tryParse(precioValue);
        if (precio == null || precio <= 0) {
          throw const FormatException('El precio debe ser numérico y mayor a 0.');
        }

        final key = _buildCsvLookupKey(nombre, categoria);
        if (!seenCsvKeys.add(key)) {
          errors.add(
            'Fila ${i + 1}: clave duplicada en CSV para nombre/categoría ($nombre / ${categoria ?? 'sin categoría'}).',
          );
          continue;
        }

        final existente = byKey[key];
        if (existente == null) {
          final createdServicio = await repository.create(
            Servicio(
              id: '',
              nombre: nombre,
              descripcion: descripcion,
              precio: precio,
              categoria: categoria,
              activo: activo,
              fechaCreacion: DateTime.now(),
            ),
          );
          byKey[key] = createdServicio;
          created++;
        } else {
          final previousKey = _buildCsvLookupKey(existente.nombre, existente.categoria);
          final updatedServicio = await repository.update(
            existente.copyWith(
              nombre: nombre,
              descripcion: descripcion,
              clearDescripcion: descripcion == null,
              precio: precio,
              categoria: categoria,
              clearCategoria: categoria == null,
              activo: activo,
            ),
          );
          byKey.remove(previousKey);
          byKey[key] = updatedServicio;
          updated++;
        }
      } catch (error) {
        errors.add('Fila ${i + 1}: $error');
      }
    }

    await reload();
    return ServiciosCsvImportResult(
      created: created,
      updated: updated,
      skipped: skipped,
      errors: errors,
    );
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  String _cellAt(List<dynamic> row, int index) {
    if (index >= row.length) {
      return '';
    }
    return row[index].toString();
  }

  bool _parseBoolCsv(String value) {
    switch (value.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'si':
      case 'sí':
      case 'activo':
        return true;
      case 'false':
      case '0':
      case 'no':
      case 'inactivo':
        return false;
      default:
        throw const FormatException('El campo activo debe ser true/false.');
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _buildCsvLookupKey(String nombre, String? categoria) {
    return '${nombre.trim().toLowerCase()}|${(categoria ?? '').trim().toLowerCase()}';
  }
}
