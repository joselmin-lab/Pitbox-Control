import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/configuracion_impuestos.dart';
import '../../domain/repositories/impuestos_repository.dart';

class SupabaseImpuestosRepository implements ImpuestosRepository {
  SupabaseImpuestosRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'configuracion_impuestos';
  static const _singletonId = '00000000-0000-0000-0000-000000000002';

  @override
  Future<ConfiguracionImpuestos> getInfo() async {
    try {
      final row = await _client.from(_table).select().eq('id', _singletonId).maybeSingle();
      if (row == null) {
        return ConfiguracionImpuestos.porDefecto().copyWith(id: _singletonId);
      }
      return _fromRow(_row(row));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo cargar la configuración de impuestos: ${error.message}');
    }
  }

  @override
  Future<ConfiguracionImpuestos> guardar({
    required double porcentajeIva,
    required double porcentajeIt,
  }) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final response = await _client
          .from(_table)
          .upsert({
            'id': _singletonId,
            'porcentaje_iva': porcentajeIva,
            'porcentaje_it': porcentajeIt,
            'fecha_actualizacion': now,
          }, onConflict: 'id')
          .select()
          .single();

      return _fromRow(_row(response));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo guardar la configuración de impuestos: ${error.message}');
    }
  }

  ConfiguracionImpuestos _fromRow(Map<String, dynamic> row) {
    return ConfiguracionImpuestos(
      id: row['id'] as String? ?? '',
      porcentajeIva: (row['porcentaje_iva'] as num?)?.toDouble() ?? 13,
      porcentajeIt: (row['porcentaje_it'] as num?)?.toDouble() ?? 3,
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
}
