enum ProformaEstado {
  borrador,
  emitida,
  aceptada,
  rechazada,
}

enum ProformaItemTipo {
  servicio,
  paquete,
  repuestoInsumo,
}

class ProformaItem {
  const ProformaItem({
    required this.id,
    required this.tipoItem,
    this.referenciaId,
    required this.descripcion,
    this.cantidad = 1,
    required this.precioUnitario,
    double? total,
  }) : total = total ?? (cantidad * precioUnitario);

  final String id;
  final ProformaItemTipo tipoItem;
  final String? referenciaId;
  final String descripcion;
  final double cantidad;
  final double precioUnitario;
  final double total;

  ProformaItem copyWith({
    String? id,
    ProformaItemTipo? tipoItem,
    String? referenciaId,
    bool clearReferenciaId = false,
    String? descripcion,
    double? cantidad,
    double? precioUnitario,
    double? total,
  }) {
    final nextCantidad = cantidad ?? this.cantidad;
    final nextPrecio = precioUnitario ?? this.precioUnitario;
    return ProformaItem(
      id: id ?? this.id,
      tipoItem: tipoItem ?? this.tipoItem,
      referenciaId: clearReferenciaId ? null : (referenciaId ?? this.referenciaId),
      descripcion: descripcion ?? this.descripcion,
      cantidad: nextCantidad,
      precioUnitario: nextPrecio,
      total: total ?? (nextCantidad * nextPrecio),
    );
  }
}

class Proforma {
  const Proforma({
    required this.id,
    required this.numero,
    required this.clienteId,
    required this.vehiculoId,
    required this.fecha,
    this.items = const <ProformaItem>[],
    this.condicionesPago,
    this.validez,
    this.tiempoEntrega,
    this.tiempoGarantia,
    this.formaPago,
    this.estado = ProformaEstado.borrador,
    this.total,
    required this.fechaCreacion,
  });

  final String id;
  final String numero;
  final String clienteId;
  final String vehiculoId;
  final DateTime fecha;
  final List<ProformaItem> items;
  final String? condicionesPago;
  final String? validez;
  final String? tiempoEntrega;
  final String? tiempoGarantia;
  final String? formaPago;
  final ProformaEstado estado;
  final double? total;
  final DateTime fechaCreacion;

  double get totalCalculado {
    return items.fold<double>(0, (acc, item) => acc + item.total);
  }

  double get totalFinal => total ?? totalCalculado;

  Proforma copyWith({
    String? id,
    String? numero,
    String? clienteId,
    String? vehiculoId,
    DateTime? fecha,
    List<ProformaItem>? items,
    String? condicionesPago,
    bool clearCondicionesPago = false,
    String? validez,
    bool clearValidez = false,
    String? tiempoEntrega,
    bool clearTiempoEntrega = false,
    String? tiempoGarantia,
    bool clearTiempoGarantia = false,
    String? formaPago,
    bool clearFormaPago = false,
    ProformaEstado? estado,
    double? total,
    bool clearTotal = false,
    DateTime? fechaCreacion,
  }) {
    return Proforma(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      clienteId: clienteId ?? this.clienteId,
      vehiculoId: vehiculoId ?? this.vehiculoId,
      fecha: fecha ?? this.fecha,
      items: items ?? this.items,
      condicionesPago: clearCondicionesPago ? null : (condicionesPago ?? this.condicionesPago),
      validez: clearValidez ? null : (validez ?? this.validez),
      tiempoEntrega: clearTiempoEntrega ? null : (tiempoEntrega ?? this.tiempoEntrega),
      tiempoGarantia: clearTiempoGarantia ? null : (tiempoGarantia ?? this.tiempoGarantia),
      formaPago: clearFormaPago ? null : (formaPago ?? this.formaPago),
      estado: estado ?? this.estado,
      total: clearTotal ? null : (total ?? this.total),
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
