import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/servicio.dart';
import '../../domain/repositories/servicio_repository.dart';

class SupabaseServicioRepository implements ServicioRepository {
  SupabaseServicioRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Servicio>> getAll() async {
    try {
      final rows = await _client.from('servicios').select().order('fecha_creacion', ascending: true);
      return _rows(rows).map(_fromRow).toList(growable: false);
    } on PostgrestException catch (error) {
      throw StateError('No se pudieron cargar los servicios: ${error.message}');
    }
  }

  @override
  Future<Servicio?> getById(String id) async {
    try {
      final row = await _client.from('servicios').select().eq('id', id).maybeSingle();
      if (row == null) {
        return null;
      }
      return _fromRow(_row(row));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo cargar el servicio $id: ${error.message}');
    }
  }

  @override
  Future<List<Servicio>> search({String? query, String? categoria}) async {
    try {
      var request = _client.from('servicios').select();
      final normalizedQuery = query?.trim();
      final normalizedCategoria = categoria?.trim();

      if (normalizedQuery != null && normalizedQuery.isNotEmpty) {
        request = request.ilike('nombre', '%$normalizedQuery%');
      }
      if (normalizedCategoria != null && normalizedCategoria.isNotEmpty) {
        request = request.ilike('categoria', '%$normalizedCategoria%');
      }

      final rows = await request.order('fecha_creacion', ascending: true);
      return _rows(rows).map(_fromRow).toList(growable: false);
    } on PostgrestException catch (error) {
      throw StateError('No se pudieron buscar servicios: ${error.message}');
    }
  }

  @override
  Future<Servicio> create(Servicio servicio) async {
    try {
      final row = await _client.from('servicios').insert(_toInsertPayload(servicio)).select().single();
      return _fromRow(_row(row));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo crear el servicio: ${error.message}');
    }
  }

  @override
  Future<Servicio> update(Servicio servicio) async {
    try {
      final row = await _client
          .from('servicios')
          .update(_toUpdatePayload(servicio))
          .eq('id', servicio.id)
          .select()
          .maybeSingle();
      if (row == null) {
        throw StateError('Servicio no encontrado: ${servicio.id}');
      }
      return _fromRow(_row(row));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo actualizar el servicio ${servicio.id}: ${error.message}');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final deleted = await _client.from('servicios').delete().eq('id', id).select('id').maybeSingle();
      if (deleted == null) {
        throw StateError('Servicio no encontrado: $id');
      }
    } on PostgrestException catch (error) {
      throw StateError('No se pudo eliminar el servicio $id: ${error.message}');
    }
  }

  Servicio _fromRow(Map<String, dynamic> row) {
    return Servicio(
      id: row['id'] as String,
      nombre: row['nombre'] as String,
      descripcion: row['descripcion'] as String?,
      precio: (row['precio'] as num).toDouble(),
      categoria: row['categoria'] as String?,
      activo: row['activo'] as bool? ?? true,
      fechaCreacion: _parseDateTime(row['fecha_creacion']),
    );
  }

  Map<String, dynamic> _toInsertPayload(Servicio servicio) {
    final payload = <String, dynamic>{
      'nombre': servicio.nombre,
      'descripcion': servicio.descripcion,
      'precio': servicio.precio,
      'categoria': servicio.categoria,
      'activo': servicio.activo,
    };
    if (servicio.id.isNotEmpty) {
      payload['id'] = servicio.id;
      payload['fecha_creacion'] = servicio.fechaCreacion.toUtc().toIso8601String();
    }
    return payload;
  }

  Map<String, dynamic> _toUpdatePayload(Servicio servicio) {
    return {
      'nombre': servicio.nombre,
      'descripcion': servicio.descripcion,
      'precio': servicio.precio,
      'categoria': servicio.categoria,
      'activo': servicio.activo,
    };
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
