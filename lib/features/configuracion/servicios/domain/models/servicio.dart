class Servicio {
  const Servicio({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    this.categoria,
    required this.activo,
    required this.fechaCreacion,
  });

  final String id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String? categoria;
  final bool activo;
  final DateTime fechaCreacion;

  Servicio copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    bool clearDescripcion = false,
    double? precio,
    String? categoria,
    bool clearCategoria = false,
    bool? activo,
    DateTime? fechaCreacion,
  }) {
    return Servicio(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: clearDescripcion ? null : (descripcion ?? this.descripcion),
      precio: precio ?? this.precio,
      categoria: clearCategoria ? null : (categoria ?? this.categoria),
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
