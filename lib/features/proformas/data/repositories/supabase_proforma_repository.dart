import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/proforma.dart';
import '../../domain/repositories/proforma_repository.dart';

class SupabaseProformaRepository implements ProformaRepository {
  SupabaseProformaRepository(this._client);

  final SupabaseClient _client;

  static const _proformasWithItemsSelect =
      'id,numero,cliente_id,vehiculo_id,fecha,condiciones_pago,validez,tiempo_entrega,tiempo_garantia,forma_pago,estado,total,fecha_creacion,proforma_items(id,tipo_item,referencia_id,descripcion,cantidad,precio_unitario,total)';

  @override
  Future<List<Proforma>> getAll({
    ProformaEstado? estado,
    String? clienteId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    try {
      var request = _client.from('proformas').select(_proformasWithItemsSelect);

      if (estado != null) {
        request = request.eq('estado', _estadoToDb(estado));
      }
      if (clienteId != null && clienteId.trim().isNotEmpty) {
        request = request.eq('cliente_id', clienteId.trim());
      }
      if (fechaDesde != null) {
        request = request.gte('fecha', _dateOnlyIso(fechaDesde));
      }
      if (fechaHasta != null) {
        request = request.lte('fecha', _dateOnlyIso(fechaHasta));
      }

      final rows = await request.order('fecha_creacion', ascending: false);
      return _rows(rows).map(_fromProformaRow).toList(growable: false);
    } on PostgrestException catch (error) {
      throw StateError('No se pudieron cargar las proformas: ${error.message}');
    }
  }

  @override
  Future<Proforma?> getById(String id) async {
    try {
      final row = await _client.from('proformas').select(_proformasWithItemsSelect).eq('id', id).maybeSingle();
      if (row == null) {
        return null;
      }
      return _fromProformaRow(_row(row));
    } on PostgrestException catch (error) {
      throw StateError('No se pudo cargar la proforma $id: ${error.message}');
    }
  }

  @override
  Future<Proforma> create(Proforma proforma) async {
    final numero = proforma.numero.trim().isNotEmpty
        ? proforma.numero.trim()
        : await generarSiguienteNumero(anio: proforma.fecha.year);

    try {
      final inserted = await _client
          .from('proformas')
          .insert({
            'numero': numero,
            'cliente_id': proforma.clienteId,
            'vehiculo_id': proforma.vehiculoId,
            'fecha': _dateOnlyIso(proforma.fecha),
            'condiciones_pago': _optional(proforma.condicionesPago),
            'validez': _optional(proforma.validez),
            'tiempo_entrega': _optional(proforma.tiempoEntrega),
            'tiempo_garantia': _optional(proforma.tiempoGarantia),
            'forma_pago': _optional(proforma.formaPago),
            'estado': _estadoToDb(proforma.estado),
            'total': proforma.totalFinal,
          })
          .select('id,numero,cliente_id,vehiculo_id,fecha,condiciones_pago,validez,tiempo_entrega,tiempo_garantia,forma_pago,estado,total,fecha_creacion')
          .single();

      final created = _fromProformaRow(_row(inserted));
      if (proforma.items.isNotEmpty) {
        await _replaceItems(proformaId: created.id, items: proforma.items);
      }

      final withItems = await getById(created.id);
      if (withItems == null) {
        throw StateError('No se pudo recargar la proforma creada.');
      }
      return withItems;
    } on PostgrestException catch (error) {
      throw StateError('No se pudo crear la proforma: ${error.message}');
    }
  }

  @override
  Future<Proforma> update(Proforma proforma) async {
    try {
      final row = await _client
          .from('proformas')
          .update({
            'cliente_id': proforma.clienteId,
            'vehiculo_id': proforma.vehiculoId,
            'fecha': _dateOnlyIso(proforma.fecha),
            'condiciones_pago': _optional(proforma.condicionesPago),
            'validez': _optional(proforma.validez),
            'tiempo_entrega': _optional(proforma.tiempoEntrega),
            'tiempo_garantia': _optional(proforma.tiempoGarantia),
            'forma_pago': _optional(proforma.formaPago),
            'estado': _estadoToDb(proforma.estado),
            'total': proforma.totalFinal,
          })
          .eq('id', proforma.id)
          .select('id')
          .maybeSingle();

      if (row == null) {
        throw StateError('Proforma no encontrada: ${proforma.id}');
      }

      await _replaceItems(proformaId: proforma.id, items: proforma.items);
      final updated = await getById(proforma.id);
      if (updated == null) {
        throw StateError('No se pudo recargar la proforma actualizada.');
      }
      return updated;
    } on PostgrestException catch (error) {
      throw StateError('No se pudo actualizar la proforma ${proforma.id}: ${error.message}');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      final deleted = await _client.from('proformas').delete().eq('id', id).select('id').maybeSingle();
      if (deleted == null) {
        throw StateError('Proforma no encontrada: $id');
      }
    } on PostgrestException catch (error) {
      throw StateError('No se pudo eliminar la proforma $id: ${error.message}');
    }
  }

  @override
  Future<String> generarSiguienteNumero({required int anio}) async {
    try {
      final response = await _client.rpc('generar_siguiente_numero_proforma', params: {
        'anio_actual': anio,
      });
      if (response is String && response.trim().isNotEmpty) {
        return response.trim();
      }
      throw const FormatException('Respuesta inválida al generar número de proforma.');
    } on PostgrestException catch (error) {
      throw StateError('No se pudo generar el número de proforma: ${error.message}');
    } on FormatException catch (error) {
      throw StateError(error.message);
    }
  }

  Future<void> _replaceItems({required String proformaId, required List<ProformaItem> items}) async {
    await _client.from('proforma_items').delete().eq('proforma_id', proformaId);
    if (items.isEmpty) {
      return;
    }

    final payload = items
        .map(
          (item) => {
            'proforma_id': proformaId,
            'tipo_item': _tipoToDb(item.tipoItem),
            'referencia_id': item.referenciaId,
            'descripcion': item.descripcion,
            'cantidad': item.cantidad,
            'precio_unitario': item.precioUnitario,
            'total': item.total,
          },
        )
        .toList(growable: false);

    await _client.from('proforma_items').insert(payload);
  }

  Proforma _fromProformaRow(Map<String, dynamic> row) {
    final itemsRows = row['proforma_items'] as List<dynamic>? ?? const [];
    final items = itemsRows.map((item) => _fromItemRow(_row(item))).toList(growable: false);

    return Proforma(
      id: row['id'] as String,
      numero: row['numero'] as String,
      clienteId: row['cliente_id'] as String,
      vehiculoId: row['vehiculo_id'] as String,
      fecha: _parseDateTime(row['fecha']),
      items: items,
      condicionesPago: row['condiciones_pago'] as String?,
      validez: row['validez'] as String?,
      tiempoEntrega: row['tiempo_entrega'] as String?,
      tiempoGarantia: row['tiempo_garantia'] as String?,
      formaPago: row['forma_pago'] as String?,
      estado: _estadoFromDb(row['estado'] as String? ?? 'borrador'),
      total: (row['total'] as num?)?.toDouble(),
      fechaCreacion: _parseDateTime(row['fecha_creacion']),
    );
  }

  ProformaItem _fromItemRow(Map<String, dynamic> row) {
    final cantidad = (row['cantidad'] as num?)?.toDouble() ?? 1;
    final precio = (row['precio_unitario'] as num?)?.toDouble() ?? 0;
    return ProformaItem(
      id: row['id'] as String,
      tipoItem: _tipoFromDb(row['tipo_item'] as String? ?? 'repuesto_insumo'),
      referenciaId: row['referencia_id'] as String?,
      descripcion: row['descripcion'] as String? ?? '',
      cantidad: cantidad,
      precioUnitario: precio,
      total: (row['total'] as num?)?.toDouble() ?? (cantidad * precio),
    );
  }

  String _estadoToDb(ProformaEstado estado) {
    switch (estado) {
      case ProformaEstado.borrador:
        return 'borrador';
      case ProformaEstado.emitida:
        return 'emitida';
      case ProformaEstado.aceptada:
        return 'aceptada';
      case ProformaEstado.rechazada:
        return 'rechazada';
    }
  }

  ProformaEstado _estadoFromDb(String estado) {
    switch (estado) {
      case 'emitida':
        return ProformaEstado.emitida;
      case 'aceptada':
        return ProformaEstado.aceptada;
      case 'rechazada':
        return ProformaEstado.rechazada;
      case 'borrador':
      default:
        return ProformaEstado.borrador;
    }
  }

  String _tipoToDb(ProformaItemTipo tipo) {
    switch (tipo) {
      case ProformaItemTipo.servicio:
        return 'servicio';
      case ProformaItemTipo.paquete:
        return 'paquete';
      case ProformaItemTipo.repuestoInsumo:
        return 'repuesto_insumo';
    }
  }

  ProformaItemTipo _tipoFromDb(String tipo) {
    switch (tipo) {
      case 'servicio':
        return ProformaItemTipo.servicio;
      case 'paquete':
        return ProformaItemTipo.paquete;
      case 'repuesto_insumo':
      default:
        return ProformaItemTipo.repuestoInsumo;
    }
  }

  String _dateOnlyIso(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$month-$day';
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
