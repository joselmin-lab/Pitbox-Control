import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/cliente.dart';
import '../../domain/repositories/cliente_repository.dart';

class SupabaseClienteRepository implements ClienteRepository {
  SupabaseClienteRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Cliente>> getAll() async {
    try {
      final rows = await _client.from('clientes').select().order('fecha_registro', ascending: true);
      return _rows(rows).map(_fromRow).toList(growable: false);
    } on PostgrestException catch (error) {
      throw StateError('No se pudieron cargar los clientes: ${error.message}');
    }
  }

  @override
  Future<Cliente?> getById(String id) async {
    try {
      final row = await _client.from('clientes').select().eq('id', id).maybeSingle();
      if (row == null) {
        return null;
      }
      return _fromRow(_row(row));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo cargar el cliente $id: ${error.message}');
    }
  }

  @override
  Future<Cliente> create(Cliente cliente) async {
    try {
      final payload = _toInsertPayload(cliente);
      final row = await _client.from('clientes').insert(payload).select().single();
      return _fromRow(_row(row));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo crear el cliente: ${error.message}');
    }
  }

  @override
  Future<Cliente> update(Cliente cliente) async {
    try {
      final row = await _client
          .from('clientes')
          .update(_toUpdatePayload(cliente))
          .eq('id', cliente.id)
          .select()
          .maybeSingle();
      if (row == null) {
        throw StateError('Cliente no encontrado: ${cliente.id}');
      }
      return _fromRow(_row(row));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo actualizar el cliente ${cliente.id}: ${error.message}');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final deleted = await _client.from('clientes').delete().eq('id', id).select('id').maybeSingle();
      if (deleted == null) {
        throw StateError('Cliente no encontrado: $id');
      }
    } on PostgrestException catch (error) {
      throw StateError('No se pudo eliminar el cliente $id: ${error.message}');
    }
  }

  Cliente _fromRow(Map<String, dynamic> row) {
    return Cliente(
      id: row['id'] as String,
      nombre: row['nombre'] as String,
      apellido: row['apellido'] as String,
      telefono: row['telefono'] as String,
      email: row['email'] as String?,
      direccion: row['direccion'] as String?,
      fechaRegistro: _parseDateTime(row['fecha_registro']),
    );
  }

  Map<String, dynamic> _toInsertPayload(Cliente cliente) {
    final payload = <String, dynamic>{
      'nombre': cliente.nombre,
      'apellido': cliente.apellido,
      'telefono': cliente.telefono,
      'email': cliente.email,
      'direccion': cliente.direccion,
    };

    if (cliente.id.isNotEmpty) {
      payload['id'] = cliente.id;
      payload['fecha_registro'] = cliente.fechaRegistro.toUtc().toIso8601String();
    }
    return payload;
  }

  Map<String, dynamic> _toUpdatePayload(Cliente cliente) {
    return {
      'nombre': cliente.nombre,
      'apellido': cliente.apellido,
      'telefono': cliente.telefono,
      'email': cliente.email,
      'direccion': cliente.direccion,
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
