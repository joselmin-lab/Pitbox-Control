import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/taller_info.dart';
import '../../domain/repositories/taller_repository.dart';

class SupabaseTallerRepository implements TallerRepository {
  SupabaseTallerRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'taller_info';
  static const _bucket = 'taller-logos';
  static const _singletonId = '00000000-0000-0000-0000-000000000001';

  @override
  Future<TallerInfo> getInfo() async {
    try {
      final row = await _client.from(_table).select().eq('id', _singletonId).maybeSingle();
      if (row == null) {
        final legacyRow =
            await _client.from(_table).select().order('fecha_actualizacion', ascending: false).limit(1).maybeSingle();
        if (legacyRow == null) {
          return TallerInfo.vacio();
        }
        return _fromRow(_row(legacyRow));
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
      final sanitizedName = _sanitizeFileName(nombreArchivo);
      final contentType = _contentTypeForBytes(bytes);
      final objectPath = 'logo_${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';

      await _client.storage.from(_bucket).uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );

      return _client.storage.from(_bucket).getPublicUrl(objectPath);
    } on StorageException catch (error) {
      throw StateError('No se pudo subir el logo: ${error.message}');
    } on FormatException catch (error) {
      throw StateError(error.message);
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

  String _sanitizeFileName(String value) {
    final trimmed = value.trim().toLowerCase();
    final sanitized = trimmed.replaceAll(RegExp(r'[^a-z0-9._-]'), '_');
    return sanitized.isEmpty ? 'logo.png' : sanitized;
  }

  String _contentTypeForBytes(Uint8List bytes) {
    if (_startsWith(bytes, const [0xFF, 0xD8, 0xFF])) {
      return 'image/jpeg';
    }
    if (_startsWith(bytes, const [0x89, 0x50, 0x4E, 0x47])) {
      return 'image/png';
    }
    if (_startsWith(bytes, const [0x52, 0x49, 0x46, 0x46]) &&
        bytes.length > 11 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    throw const FormatException('Solo se permiten imágenes PNG, JPG/JPEG o WEBP.');
  }

  bool _startsWith(List<int> bytes, List<int> signature) {
    if (bytes.length < signature.length) {
      return false;
    }
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) {
        return false;
      }
    }
    return true;
  }
}
