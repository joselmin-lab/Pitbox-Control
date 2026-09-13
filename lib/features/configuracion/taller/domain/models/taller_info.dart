class TallerInfo {
  const TallerInfo({
    required this.id,
    required this.nombre,
    this.direccion,
    this.telefono,
    this.correo,
    this.logoUrl,
    required this.fechaActualizacion,
  });

  factory TallerInfo.vacio() {
    return TallerInfo(
      id: '',
      nombre: 'Mi Taller',
      fechaActualizacion: DateTime.now(),
    );
  }

  final String id;
  final String nombre;
  final String? direccion;
  final String? telefono;
  final String? correo;
  final String? logoUrl;
  final DateTime fechaActualizacion;

  TallerInfo copyWith({
    String? id,
    String? nombre,
    String? direccion,
    bool clearDireccion = false,
    String? telefono,
    bool clearTelefono = false,
    String? correo,
    bool clearCorreo = false,
    String? logoUrl,
    bool clearLogoUrl = false,
    DateTime? fechaActualizacion,
  }) {
    return TallerInfo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: clearDireccion ? null : (direccion ?? this.direccion),
      telefono: clearTelefono ? null : (telefono ?? this.telefono),
      correo: clearCorreo ? null : (correo ?? this.correo),
      logoUrl: clearLogoUrl ? null : (logoUrl ?? this.logoUrl),
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}
