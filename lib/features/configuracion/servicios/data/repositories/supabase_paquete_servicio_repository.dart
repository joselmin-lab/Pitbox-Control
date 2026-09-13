import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/paquete_servicio.dart';
import '../../domain/models/servicio.dart';
import '../../domain/repositories/paquete_servicio_repository.dart';

class SupabasePaqueteServicioRepository implements PaqueteServicioRepository {
  SupabasePaqueteServicioRepository(this._client);

  final SupabaseClient _client;

  static const _paquetesWithItemsSelect =
      'id,nombre,descripcion,precio_manual,activo,fecha_creacion,paquete_servicio_items(id,paquete_id,servicio_id,cantidad,servicios(id,nombre,descripcion,precio,categoria,activo,fecha_creacion))';

  @override
  Future<List<PaqueteServicio>> getAll() async {
    try {
      final rows = await _client
          .from('paquetes_servicios')
          .select(_paquetesWithItemsSelect)
          .order('fecha_creacion', ascending: true);
      return _rows(rows).map(_fromPaqueteRow).toList(growable: false);
    } on PostgrestException catch (error) {
      throw StateError('No se pudieron cargar los paquetes: ${error.message}');
    }
  }

  @override
  Future<PaqueteServicio?> getById(String id) async {
    try {
      final row = await _client
          .from('paquetes_servicios')
          .select(_paquetesWithItemsSelect)
          .eq('id', id)
          .maybeSingle();
      if (row == null) {
        return null;
      }
      return _fromPaqueteRow(_row(row));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo cargar el paquete $id: ${error.message}');
    }
  }

  @override
  Future<PaqueteServicio> create(PaqueteServicio paquete) async {
    try {
      final row = await _client
          .from('paquetes_servicios')
          .insert(_toInsertPayload(paquete))
          .select('id,nombre,descripcion,precio_manual,activo,fecha_creacion')
          .single();
      return _fromPaqueteRow(_row(row));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo crear el paquete: ${error.message}');
    }
  }

  @override
  Future<PaqueteServicio> update(PaqueteServicio paquete) async {
    try {
      final row = await _client
          .from('paquetes_servicios')
          .update(_toUpdatePayload(paquete))
          .eq('id', paquete.id)
          .select('id,nombre,descripcion,precio_manual,activo,fecha_creacion')
          .maybeSingle();
      if (row == null) {
        throw StateError('Paquete no encontrado: ${paquete.id}');
      }
      return _fromPaqueteRow(_row(row));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo actualizar el paquete ${paquete.id}: ${error.message}');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final deleted = await _client.from('paquetes_servicios').delete().eq('id', id).select('id').maybeSingle();
      if (deleted == null) {
        throw StateError('Paquete no encontrado: $id');
      }
    } on PostgrestException catch (error) {
      throw StateError('No se pudo eliminar el paquete $id: ${error.message}');
    }
  }

  @override
  Future<List<PaqueteServicioItem>> getServiciosByPaquete(String paqueteId) async {
    try {
      final rows = await _client
          .from('paquete_servicio_items')
          .select('id,paquete_id,servicio_id,cantidad,servicios(id,nombre,descripcion,precio,categoria,activo,fecha_creacion)')
          .eq('paquete_id', paqueteId)
          .order('id', ascending: true);
      return _rows(rows).map(_fromItemRow).toList(growable: false);
    } on PostgrestException catch (error) {
      throw StateError('No se pudieron cargar los servicios del paquete: ${error.message}');
    }
  }

  @override
  Future<PaqueteServicioItem> addServicioToPaquete({
    required String paqueteId,
    required String servicioId,
    int cantidad = 1,
  }) async {
    try {
      final existing = await _client
          .from('paquete_servicio_items')
          .select('id,cantidad')
          .eq('paquete_id', paqueteId)
          .eq('servicio_id', servicioId)
          .maybeSingle();

      if (existing != null) {
        final existingRow = _row(existing);
        final itemId = existingRow['id'] as String;
        final row = await _client
            .from('paquete_servicio_items')
            .update({'cantidad': cantidad})
            .eq('id', itemId)
            .select('id,paquete_id,servicio_id,cantidad,servicios(id,nombre,descripcion,precio,categoria,activo,fecha_creacion)')
            .single();
        return _fromItemRow(_row(row));
      }

      final row = await _client
          .from('paquete_servicio_items')
          .insert({'paquete_id': paqueteId, 'servicio_id': servicioId, 'cantidad': cantidad})
          .select('id,paquete_id,servicio_id,cantidad,servicios(id,nombre,descripcion,precio,categoria,activo,fecha_creacion)')
          .single();
      return _fromItemRow(_row(row));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo asociar el servicio al paquete: ${error.message}');
    }
  }

  @override
  Future<void> removeServicioDePaquete({
    required String paqueteId,
    required String servicioId,
  }) async {
    try {
      await _client
          .from('paquete_servicio_items')
          .delete()
          .eq('paquete_id', paqueteId)
          .eq('servicio_id', servicioId);
    } on PostgrestException catch (error) {
      throw StateError('No se pudo quitar el servicio del paquete: ${error.message}');
    }
  }

  @override
  Future<void> clearServiciosDePaquete(String paqueteId) async {
    try {
      await _client.from('paquete_servicio_items').delete().eq('paquete_id', paqueteId);
    } on PostgrestException catch (error) {
      throw StateError('No se pudo limpiar el paquete: ${error.message}');
    }
  }

  PaqueteServicio _fromPaqueteRow(Map<String, dynamic> row) {
    final itemsRows = row['paquete_servicio_items'] as List<dynamic>? ?? const [];
    final items = itemsRows.map((item) => _fromItemRow(_row(item))).toList(growable: false);
    return PaqueteServicio(
      id: row['id'] as String,
      nombre: row['nombre'] as String,
      descripcion: row['descripcion'] as String?,
      precioManual: (row['precio_manual'] as num?)?.toDouble(),
      activo: row['activo'] as bool? ?? true,
      fechaCreacion: _parseDateTime(row['fecha_creacion']),
      items: items,
    );
  }

  PaqueteServicioItem _fromItemRow(Map<String, dynamic> row) {
    final servicioRow = row['servicios'];
    return PaqueteServicioItem(
      id: row['id'] as String,
      paqueteId: row['paquete_id'] as String,
      servicioId: row['servicio_id'] as String,
      cantidad: (row['cantidad'] as num?)?.toInt() ?? 1,
      servicio: servicioRow == null ? null : _fromServicioRow(_row(servicioRow)),
    );
  }

  Servicio _fromServicioRow(Map<String, dynamic> row) {
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

  Map<String, dynamic> _toInsertPayload(PaqueteServicio paquete) {
    final payload = <String, dynamic>{
      'nombre': paquete.nombre,
      'descripcion': paquete.descripcion,
      'precio_manual': paquete.precioManual,
      'activo': paquete.activo,
    };
    if (paquete.id.isNotEmpty) {
      payload['id'] = paquete.id;
      payload['fecha_creacion'] = paquete.fechaCreacion.toUtc().toIso8601String();
    }
    return payload;
  }

  Map<String, dynamic> _toUpdatePayload(PaqueteServicio paquete) {
    return {
      'nombre': paquete.nombre,
      'descripcion': paquete.descripcion,
      'precio_manual': paquete.precioManual,
      'activo': paquete.activo,
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
