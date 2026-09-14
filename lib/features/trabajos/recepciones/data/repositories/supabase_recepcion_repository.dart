import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/recepcion_vehiculo.dart';
import '../../domain/repositories/recepcion_repository.dart';
import '../../../../configuracion/taller/domain/utils/logo_image_validator.dart';

class SupabaseRecepcionRepository implements RecepcionRepository {
  SupabaseRecepcionRepository(this._client);

  final SupabaseClient _client;
  final Random _random = Random.secure();

  static const _table = 'recepciones_vehiculo';
  static const _fotosBucket = 'recepciones-fotos';
  static const _firmasBucket = 'recepciones-firmas';

  @override
  Future<List<RecepcionVehiculo>> getAll({
    RecepcionEstado? estado,
    String? clienteId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    try {
      var request = _client.from(_table).select();
      if (estado != null) {
        request = request.eq('estado', _estadoToDb(estado));
      }
      if (clienteId != null && clienteId.trim().isNotEmpty) {
        request = request.eq('cliente_id', clienteId.trim());
      }
      if (fechaDesde != null) {
        request = request.gte('fecha_ingreso', fechaDesde.toUtc().toIso8601String());
      }
      if (fechaHasta != null) {
        request = request.lte('fecha_ingreso', fechaHasta.toUtc().toIso8601String());
      }
      final rows = await request.order('fecha_creacion', ascending: false);
      return _rows(rows).map(_fromRow).toList(growable: false);
    } on PostgrestException catch (error) {
      throw StateError('No se pudieron cargar las recepciones: ${error.message}');
    }
  }

  @override
  Future<RecepcionVehiculo?> getById(String id) async {
    try {
      final row = await _client.from(_table).select().eq('id', id).maybeSingle();
      if (row == null) {
        return null;
      }
      return _fromRow(_row(row));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo cargar la recepción $id: ${error.message}');
    }
  }

  @override
  Future<RecepcionVehiculo> create(RecepcionVehiculo recepcion) async {
    final numero = recepcion.numero.trim().isNotEmpty
        ? recepcion.numero.trim()
        : await generarSiguienteNumero(anio: recepcion.fechaIngreso.year);
    try {
      final inserted = await _client.from(_table).insert(_payload(recepcion, numero: numero)).select().single();
      return _fromRow(_row(inserted));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo crear la recepción: ${error.message}');
    }
  }

  @override
  Future<RecepcionVehiculo> update(RecepcionVehiculo recepcion) async {
    try {
      final updated = await _client
          .from(_table)
          .update(_payload(recepcion, numero: recepcion.numero))
          .eq('id', recepcion.id)
          .select()
          .maybeSingle();
      if (updated == null) {
        throw StateError('Recepción no encontrada: ${recepcion.id}');
      }
      return _fromRow(_row(updated));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo actualizar la recepción ${recepcion.id}: ${error.message}');
    }
  }

  @override
  Future<String> generarSiguienteNumero({required int anio}) async {
    try {
      final response = await _client.rpc('generar_siguiente_numero_recepcion', params: {
        'anio_actual': anio,
      });
      if (response is String && response.trim().isNotEmpty) {
        return response.trim();
      }
      throw const FormatException('Respuesta inválida al generar número de recepción.');
    } on PostgrestException catch (error) {
      throw StateError('No se pudo generar el número de recepción: ${error.message}');
    } on FormatException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<String> subirFotografia(Uint8List bytes, String nombreArchivo) {
    return _subirArchivo(
      bucket: _fotosBucket,
      bytes: bytes,
      nombreArchivo: nombreArchivo,
      prefijo: 'foto',
    );
  }

  @override
  Future<String> subirFirma(Uint8List bytes, String nombreArchivo) {
    return _subirArchivo(
      bucket: _firmasBucket,
      bytes: bytes,
      nombreArchivo: nombreArchivo,
      prefijo: 'firma',
    );
  }

  Future<String> _subirArchivo({
    required String bucket,
    required Uint8List bytes,
    required String nombreArchivo,
    required String prefijo,
  }) async {
    try {
      final sanitizedName = _sanitizeFileName(nombreArchivo);
      final imageType = detectLogoImageType(bytes);
      if (imageType == null) {
        throw const FormatException('Solo se permiten imágenes PNG, JPG/JPEG o WEBP.');
      }
      final extension = extractLogoExtension(sanitizedName);
      if (extension == null || !doesLogoExtensionMatchType(extension, imageType)) {
        throw const FormatException('La extensión del archivo no coincide con su formato real.');
      }
      final randomSuffix = _random.nextInt(1 << 32).toRadixString(16);
      final objectPath = '${prefijo}_${DateTime.now().microsecondsSinceEpoch}_${randomSuffix}_$sanitizedName';
      await _client.storage.from(bucket).uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              upsert: false,
              contentType: imageType.contentType,
            ),
          );
      return _client.storage.from(bucket).getPublicUrl(objectPath);
    } on StorageException catch (error) {
      throw StateError('No se pudo subir el archivo: ${error.message}');
    } on FormatException catch (error) {
      throw StateError(error.message);
    }
  }

  Map<String, dynamic> _payload(RecepcionVehiculo recepcion, {required String numero}) {
    return {
      'numero': numero,
      'cliente_id': recepcion.clienteId,
      'vehiculo_id': recepcion.vehiculoId,
      'fecha_ingreso': recepcion.fechaIngreso.toUtc().toIso8601String(),
      'fecha_salida_estimada': recepcion.fechaSalidaEstimada?.toUtc().toIso8601String(),
      'kilometraje': _optional(recepcion.kilometraje),
      'ingreso_en_grua': recepcion.ingresoEnGrua,
      'trabajo_a_realizar': _optional(recepcion.trabajoARealizar),
      'observaciones': _optional(recepcion.observaciones),
      'checklist_sistemas': recepcion.checklistSistemas
          .map(
            (item) => {
              'clave': item.clave,
              'etiqueta': item.etiqueta,
              'icono': item.icono,
              'marcado': item.marcado,
            },
          )
          .toList(growable: false),
      'inventario': recepcion.inventario
          .map(
            (item) => {
              'item': item.item,
              'marcado': item.marcado,
            },
          )
          .toList(growable: false),
      'nivel_combustible': recepcion.nivelCombustible,
      'danos_preexistentes': recepcion.danosPreexistentes
          .map(
            (dano) => {
              'vista': dano.vista.clave,
              'x': dano.x,
              'y': dano.y,
              'descripcion': _optional(dano.descripcion),
            },
          )
          .toList(growable: false),
      'fotografias': recepcion.fotografias,
      'firma_prestador_url': _optional(recepcion.firmaPrestadorUrl),
      'firma_cliente_url': _optional(recepcion.firmaClienteUrl),
      'estado': _estadoToDb(recepcion.estado),
      'fecha_creacion': recepcion.fechaCreacion.toUtc().toIso8601String(),
    };
  }

  RecepcionVehiculo _fromRow(Map<String, dynamic> row) {
    final checklistRows = row['checklist_sistemas'] as List<dynamic>? ?? const [];
    final inventarioRows = row['inventario'] as List<dynamic>? ?? const [];
    final danosRows = row['danos_preexistentes'] as List<dynamic>? ?? const [];
    final fotosRows = row['fotografias'] as List<dynamic>? ?? const [];

    return RecepcionVehiculo(
      id: row['id'] as String? ?? '',
      numero: row['numero'] as String? ?? '',
      clienteId: row['cliente_id'] as String? ?? '',
      vehiculoId: row['vehiculo_id'] as String? ?? '',
      fechaIngreso: _parseDateTime(row['fecha_ingreso']),
      fechaSalidaEstimada: row['fecha_salida_estimada'] == null ? null : _parseDateTime(row['fecha_salida_estimada']),
      kilometraje: row['kilometraje'] as String?,
      ingresoEnGrua: row['ingreso_en_grua'] as bool? ?? false,
      trabajoARealizar: row['trabajo_a_realizar'] as String?,
      observaciones: row['observaciones'] as String?,
      checklistSistemas: checklistRows.isEmpty
          ? recepcionChecklistBase
          : checklistRows
                .map(
                  (item) => _fromChecklistRow(_row(item)),
                )
                .toList(growable: false),
      inventario: inventarioRows.isEmpty
          ? recepcionInventarioBase
          : inventarioRows
                .map(
                  (item) => _fromInventarioRow(_row(item)),
                )
                .toList(growable: false),
      nivelCombustible: (row['nivel_combustible'] as num?)?.toDouble() ?? 0,
      danosPreexistentes: danosRows
          .map(
            (item) => _fromDanoRow(_row(item)),
          )
          .toList(growable: false),
      fotografias: fotosRows.map((item) => item.toString()).toList(growable: false),
      firmaPrestadorUrl: row['firma_prestador_url'] as String?,
      firmaClienteUrl: row['firma_cliente_url'] as String?,
      estado: _estadoFromDb(row['estado'] as String? ?? 'abierta'),
      fechaCreacion: _parseDateTime(row['fecha_creacion']),
    );
  }

  RecepcionChecklistItem _fromChecklistRow(Map<String, dynamic> row) {
    return RecepcionChecklistItem(
      clave: row['clave'] as String? ?? '',
      etiqueta: row['etiqueta'] as String? ?? '',
      icono: row['icono'] as String? ?? 'check',
      marcado: row['marcado'] as bool? ?? false,
    );
  }

  RecepcionInventarioItem _fromInventarioRow(Map<String, dynamic> row) {
    return RecepcionInventarioItem(
      item: row['item'] as String? ?? '',
      marcado: row['marcado'] as bool? ?? false,
    );
  }

  DanoVehiculoMarcado _fromDanoRow(Map<String, dynamic> row) {
    return DanoVehiculoMarcado(
      vista: RecepcionVistaVehiculoX.fromClave(row['vista'] as String? ?? 'izquierdo'),
      x: (row['x'] as num?)?.toDouble() ?? 0,
      y: (row['y'] as num?)?.toDouble() ?? 0,
      descripcion: row['descripcion'] as String?,
    );
  }

  String _estadoToDb(RecepcionEstado estado) {
    switch (estado) {
      case RecepcionEstado.abierta:
        return 'abierta';
      case RecepcionEstado.vehiculoEntregado:
        return 'vehiculo_entregado';
    }
  }

  RecepcionEstado _estadoFromDb(String value) {
    switch (value) {
      case 'vehiculo_entregado':
        return RecepcionEstado.vehiculoEntregado;
      case 'abierta':
      default:
        return RecepcionEstado.abierta;
    }
  }

  String _sanitizeFileName(String value) {
    final trimmed = value.trim().toLowerCase();
    final sanitized = trimmed.replaceAll(RegExp(r'[^a-z0-9._-]'), '_');
    return sanitized.isEmpty ? 'archivo.png' : sanitized;
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  List<Map<String, dynamic>> _rows(dynamic response) {
    return (response as List).map(_row).toList(growable: false);
  }

  Map<String, dynamic> _row(dynamic value) {
    return Map<String, dynamic>.from(value as Map);
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value.toLocal();
    }
    return DateTime.parse(value as String).toLocal();
  }
}
