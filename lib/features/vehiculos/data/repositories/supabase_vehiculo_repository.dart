import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/vehiculo.dart';
import '../../domain/repositories/vehiculo_repository.dart';

class SupabaseVehiculoRepository implements VehiculoRepository {
  SupabaseVehiculoRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Vehiculo>> getAll() async {
    try {
      final rows = await _client.from('vehiculos').select().order('fecha_registro', ascending: true);
      return _rows(rows).map(_fromRow).toList(growable: false);
    } on PostgrestException catch (error) {
      throw StateError('No se pudieron cargar los vehículos: ${error.message}');
    }
  }

  @override
  Future<Vehiculo?> getById(String id) async {
    try {
      final row = await _client.from('vehiculos').select().eq('id', id).maybeSingle();
      if (row == null) {
        return null;
      }
      return _fromRow(_row(row));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo cargar el vehículo $id: ${error.message}');
    }
  }

  @override
  Future<List<Vehiculo>> getByClienteId(String clienteId) async {
    try {
      final rows = await _client
          .from('vehiculos')
          .select()
          .eq('cliente_id', clienteId)
          .order('fecha_registro', ascending: true);
      return _rows(rows).map(_fromRow).toList(growable: false);
    } on PostgrestException catch (error) {
      throw StateError('No se pudieron cargar los vehículos del cliente $clienteId: ${error.message}');
    }
  }

  @override
  Future<Vehiculo> create(Vehiculo vehiculo) async {
    try {
      final row = await _client.from('vehiculos').insert(_toInsertPayload(vehiculo)).select().single();
      return _fromRow(_row(row));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo crear el vehículo: ${error.message}');
    }
  }

  @override
  Future<Vehiculo> update(Vehiculo vehiculo) async {
    try {
      final row = await _client
          .from('vehiculos')
          .update(_toUpdatePayload(vehiculo))
          .eq('id', vehiculo.id)
          .select()
          .maybeSingle();
      if (row == null) {
        throw StateError('Vehículo no encontrado: ${vehiculo.id}');
      }
      return _fromRow(_row(row));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo actualizar el vehículo ${vehiculo.id}: ${error.message}');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _client.from('vehiculos').delete().eq('id', id);
    } on PostgrestException catch (error) {
      throw StateError('No se pudo eliminar el vehículo $id: ${error.message}');
    }
  }

  @override
  Future<void> deleteByClienteId(String clienteId) async {
    try {
      await _client.from('vehiculos').delete().eq('cliente_id', clienteId);
    } on PostgrestException catch (error) {
      throw StateError('No se pudieron eliminar los vehículos del cliente $clienteId: ${error.message}');
    }
  }

  Vehiculo _fromRow(Map<String, dynamic> row) {
    return Vehiculo(
      id: row['id'] as String,
      clienteId: row['cliente_id'] as String,
      placa: row['placa'] as String,
      marca: row['marca'] as String,
      modelo: row['modelo'] as String,
      anio: (row['anio'] as num).toInt(),
      color: row['color'] as String?,
      kilometraje: (row['kilometraje'] as num?)?.toInt(),
      fechaRegistro: _parseDateTime(row['fecha_registro']),
    );
  }

  Map<String, dynamic> _toInsertPayload(Vehiculo vehiculo) {
    final payload = <String, dynamic>{
      'cliente_id': vehiculo.clienteId,
      'placa': vehiculo.placa,
      'marca': vehiculo.marca,
      'modelo': vehiculo.modelo,
      'anio': vehiculo.anio,
      'color': vehiculo.color,
      'kilometraje': vehiculo.kilometraje,
    };
    if (vehiculo.id.isNotEmpty) {
      payload['id'] = vehiculo.id;
      payload['fecha_registro'] = vehiculo.fechaRegistro.toUtc().toIso8601String();
    }
    return payload;
  }

  Map<String, dynamic> _toUpdatePayload(Vehiculo vehiculo) {
    return {
      'cliente_id': vehiculo.clienteId,
      'placa': vehiculo.placa,
      'marca': vehiculo.marca,
      'modelo': vehiculo.modelo,
      'anio': vehiculo.anio,
      'color': vehiculo.color,
      'kilometraje': vehiculo.kilometraje,
      'fecha_registro': vehiculo.fechaRegistro.toUtc().toIso8601String(),
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
