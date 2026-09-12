class Vehiculo {
  const Vehiculo({
    required this.id,
    required this.clienteId,
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.anio,
    this.color,
    this.kilometraje,
    required this.fechaRegistro,
  });

  final String id;
  final String clienteId;
  final String placa;
  final String marca;
  final String modelo;
  final int anio;
  final String? color;
  final int? kilometraje;
  final DateTime fechaRegistro;

  Vehiculo copyWith({
    String? id,
    String? clienteId,
    String? placa,
    String? marca,
    String? modelo,
    int? anio,
    String? color,
    bool clearColor = false,
    int? kilometraje,
    bool clearKilometraje = false,
    DateTime? fechaRegistro,
  }) {
    return Vehiculo(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      placa: placa ?? this.placa,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      anio: anio ?? this.anio,
      color: clearColor ? null : (color ?? this.color),
      kilometraje: clearKilometraje ? null : (kilometraje ?? this.kilometraje),
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
    );
  }
}
