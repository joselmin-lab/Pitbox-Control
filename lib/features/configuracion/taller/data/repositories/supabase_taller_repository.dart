import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/taller_info.dart';
import '../../domain/repositories/taller_repository.dart';

class SupabaseTallerRepository implements TallerRepository {
  SupabaseTallerRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'taller_info';
  static const _bucket = 'taller-logos';

  @override
  Future<TallerInfo> getInfo() async {
    try {
      final row = await _client
          .from(_table)
          .select()
          .order('fecha_actualizacion', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) {
        return TallerInfo.vacio();
      }
      return _fromRow(_row(row));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo cargar la información del taller: ${error.message}');
    }
  }

  @override
  Future<TallerInfo> guardarInfo(TallerInfo info) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final existing = await _client.from(_table).select('id').limit(1).maybeSingle();
      final existingId = existing == null ? null : (_row(existing)['id'] as String);
      final id = info.id.isNotEmpty ? info.id : existingId;

      if (id == null) {
        final inserted = await _client
            .from(_table)
            .insert({
              'nombre': info.nombre,
              'direccion': info.direccion,
              'telefono': info.telefono,
              'correo': info.correo,
              'logo_url': info.logoUrl,
              'fecha_actualizacion': now,
            })
            .select()
            .single();
        return _fromRow(_row(inserted));
      }

      final updated = await _client
          .from(_table)
          .upsert({
            'id': id,
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
    }
  }

  @override
  Future<String> subirLogo(Uint8List bytes, String nombreArchivo) async {
    try {
      final sanitizedName = _sanitizeFileName(nombreArchivo);
      final objectPath = 'logo_${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';

      await _client.storage.from(_bucket).uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _contentTypeForFileName(sanitizedName),
            ),
          );

      return _client.storage.from(_bucket).getPublicUrl(objectPath);
    } on StorageException catch (error) {
      throw StateError('No se pudo subir el logo: ${error.message}');
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
    return DateTime.now();
  }

  String _sanitizeFileName(String value) {
    final trimmed = value.trim().toLowerCase();
    final sanitized = trimmed.replaceAll(RegExp(r'[^a-z0-9._-]'), '_');
    return sanitized.isEmpty ? 'logo.png' : sanitized;
  }

  String _contentTypeForFileName(String fileName) {
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (fileName.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/png';
  }
}
