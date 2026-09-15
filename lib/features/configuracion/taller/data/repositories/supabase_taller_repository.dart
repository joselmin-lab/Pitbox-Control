import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/taller_info.dart';
import '../../domain/repositories/taller_repository.dart';
import '../../domain/utils/logo_image_validator.dart';

class SupabaseTallerRepository implements TallerRepository {
  SupabaseTallerRepository(this._client);

  final SupabaseClient _client;
  final Random _random = Random.secure();
  static const _table = 'taller_info';
  static const _bucket = 'taller-logos';
  static const _singletonId = '00000000-0000-0000-0000-000000000001';

  @override
  Future<TallerInfo> getInfo() async {
    try {
      final row = await _client.from(_table).select().eq('id', _singletonId).maybeSingle();
      if (row == null) {
        return TallerInfo.vacio().copyWith(id: _singletonId);
      }
      return _fromRow(_row(row));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo cargar la información del taller: ${error.message}');
    } on FormatException catch (error) {
      throw StateError('Datos inválidos de taller_info: ${error.message}');
    }
  }

  @override
  Future<TallerInfo> guardarInfo(TallerInfo info) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final updated = await _client
          .from(_table)
          .upsert({
            'id': _singletonId,
            'nombre': info.nombre,
            'direccion': info.direccion,
            'telefono': info.telefono,
            'correo': info.correo,
            'logo_url': info.logoUrl,
            'fecha_actualizacion': now,
          }, onConflict: 'id')
          .select()
          .single();
      return _fromRow(_row(updated));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo guardar la información del taller: ${error.message}');
    } on FormatException catch (error) {
      throw StateError('Datos inválidos al guardar taller_info: ${error.message}');
    }
  }

  @override
  Future<String> subirLogo(Uint8List bytes, String nombreArchivo) async {
    try {
      validateImageBytesNotEmpty(bytes);
      final sanitizedName = _sanitizeFileName(nombreArchivo);
      final imageType = detectLogoImageType(bytes);
      if (imageType == null) {
        throw const FormatException('Solo se permiten imágenes PNG, JPG/JPEG o WEBP.');
      }
      final extension = extractLogoExtension(sanitizedName);
      if (extension == null || !doesLogoExtensionMatchType(extension, imageType)) {
        throw const FormatException('La extensión del archivo no coincide con su formato real.');
      }
      final randomSuffix = _random.nextInt(1000000).toString().padLeft(6, '0');
      // Nota: se evita el uso de guiones bajos ("_") en el nombre del objeto.
      // Supabase Storage tiene un bug conocido en el trigger de validación de
      // prefijos que, al usar LIKE con guiones bajos sin un ESCAPE explícito,
      // provoca el error de Postgres 22025 (invalid_escape_sequence) al
      // insertar filas en storage.objects. Usar guiones ("-") como separador
      // evita ese problema por completo.
      final objectPath =
          'logo-${DateTime.now().microsecondsSinceEpoch}-$randomSuffix-$sanitizedName';

      await _client.storage.from(_bucket).uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              upsert: false,
              contentType: imageType.contentType,
            ),
          );

      return _client.storage.from(_bucket).getPublicUrl(objectPath);
    } on StorageException catch (error) {
      final status = error.statusCode == null ? '' : ' [${error.statusCode}]';
      final code = (error.error ?? '').trim();
      final codeSuffix = code.isEmpty ? '' : ' ($code)';
      throw StateError(
        'No se pudo subir el logo al bucket "$_bucket"$status$codeSuffix: ${error.message}',
      );
    } on FormatException catch (error) {
      throw StateError(error.message);
    }
  }

  @override
  Future<void> eliminarLogoPorUrl(String logoUrl) async {
    final objectPath = _extractObjectPathFromPublicUrl(logoUrl);
    if (objectPath == null) {
      return;
    }
    try {
      await _client.storage.from(_bucket).remove([objectPath]);
    } on StorageException {
      // Ignorado: la limpieza es best effort.
    }
  }

  TallerInfo _fromRow(Map<String, dynamic> row) {
    return TallerInfo(
      id: row['id'] as String? ?? '',
      nombre: row['nombre'] as String? ?? 'Mi Taller',
      direccion: row['direccion'] as String?,
      telefono: row['telefono'] as String?,
      correo: row['correo'] as String?,
      logoUrl: row['logo_url'] as String?,
      fechaActualizacion: _parseDateTime(row['fecha_actualizacion']),
    );
  }

  Map<String, dynamic> _row(dynamic value) {
    return Map<String, dynamic>.from(value as Map);
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value.toLocal();
    }
    if (value is String) {
      return DateTime.parse(value).toLocal();
    }
    throw const FormatException('fecha_actualizacion inválida en taller_info');
  }

  /// Sanitiza el nombre de archivo para usarlo como parte del `objectPath`
  /// en Supabase Storage.
  ///
  /// Importante: los caracteres no permitidos se reemplazan por guiones
  /// ("-") y NO por guiones bajos ("_"). Un bug conocido en el trigger de
  /// validación de prefijos de Supabase Storage provoca el error de
  /// Postgres 22025 (invalid_escape_sequence) cuando el nombre del objeto
  /// contiene guiones bajos, por lo que deben evitarse por completo.
  String _sanitizeFileName(String value) {
    final trimmed = value.trim().toLowerCase();
    var sanitized = trimmed.replaceAll(RegExp(r'[^a-z0-9.-]'), '-');
    // Colapsa guiones repetidos que pudieran resultar del reemplazo anterior.
    sanitized = sanitized.replaceAll(RegExp(r'-{2,}'), '-');
    return sanitized.isEmpty ? 'logo.png' : sanitized;
  }

  String? _extractObjectPathFromPublicUrl(String logoUrl) {
    final uri = Uri.tryParse(logoUrl);
    if (uri == null) {
      return null;
    }
    final marker = '/storage/v1/object/public/$_bucket/';
    final fullPath = uri.path;
    final markerIndex = fullPath.indexOf(marker);
    if (markerIndex < 0) {
      return null;
    }
    return Uri.decodeComponent(fullPath.substring(markerIndex + marker.length));
  }
}
