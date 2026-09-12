class Cliente {
  const Cliente({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.telefono,
    this.email,
    this.direccion,
    required this.fechaRegistro,
  });

  final String id;
  final String nombre;
  final String apellido;
  final String telefono;
  final String? email;
  final String? direccion;
  final DateTime fechaRegistro;

  String get nombreCompleto => '$nombre $apellido'.trim();

  Cliente copyWith({
    String? id,
    String? nombre,
    String? apellido,
    String? telefono,
    String? email,
    bool clearEmail = false,
    String? direccion,
    bool clearDireccion = false,
    DateTime? fechaRegistro,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      telefono: telefono ?? this.telefono,
      email: clearEmail ? null : (email ?? this.email),
      direccion: clearDireccion ? null : (direccion ?? this.direccion),
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }
}
