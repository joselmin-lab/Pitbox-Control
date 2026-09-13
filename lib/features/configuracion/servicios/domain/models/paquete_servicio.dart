import 'servicio.dart';

class PaqueteServicio {
  const PaqueteServicio({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.precioManual,
    required this.activo,
    required this.fechaCreacion,
    this.items = const <PaqueteServicioItem>[],
  });

  final String id;
  final String nombre;
  final String? descripcion;
  final double? precioManual;
  final bool activo;
  final DateTime fechaCreacion;
  final List<PaqueteServicioItem> items;

  double get precioTotalCalculado {
    if (precioManual != null) {
      return precioManual!;
    }
    return items.fold<double>(
      0,
      (total, item) => total + ((item.servicio?.precio ?? 0) * item.cantidad),
    );
  }

  PaqueteServicio copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    bool clearDescripcion = false,
    double? precioManual,
    bool clearPrecioManual = false,
    bool? activo,
    DateTime? fechaCreacion,
    List<PaqueteServicioItem>? items,
  }) {
    return PaqueteServicio(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: clearDescripcion ? null : (descripcion ?? this.descripcion),
      precioManual: clearPrecioManual ? null : (precioManual ?? this.precioManual),
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      items: items ?? this.items,
    );
  }
}

class PaqueteServicioItem {
  const PaqueteServicioItem({
    required this.id,
    required this.paqueteId,
    required this.servicioId,
    this.servicio,
    this.cantidad = 1,
  });

  final String id;
  final String paqueteId;
  final String servicioId;
  final Servicio? servicio;
  final int cantidad;

  PaqueteServicioItem copyWith({
    String? id,
    String? paqueteId,
    String? servicioId,
    Servicio? servicio,
    bool clearServicio = false,
    int? cantidad,
  }) {
    return PaqueteServicioItem(
      id: id ?? this.id,
      paqueteId: paqueteId ?? this.paqueteId,
      servicioId: servicioId ?? this.servicioId,
      servicio: clearServicio ? null : (servicio ?? this.servicio),
      cantidad: cantidad ?? this.cantidad,
    );
  }
}
