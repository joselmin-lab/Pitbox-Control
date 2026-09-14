class ConfiguracionImpuestos {
  const ConfiguracionImpuestos({
    required this.id,
    required this.porcentajeIva,
    required this.porcentajeIt,
    required this.fechaActualizacion,
  });

  factory ConfiguracionImpuestos.porDefecto() {
    return ConfiguracionImpuestos(
      id: '',
      porcentajeIva: 13,
      porcentajeIt: 3,
      fechaActualizacion: DateTime.now(),
    );
  }

  final String id;
  final double porcentajeIva;
  final double porcentajeIt;
  final DateTime fechaActualizacion;

  ConfiguracionImpuestos copyWith({
    String? id,
    double? porcentajeIva,
    double? porcentajeIt,
    DateTime? fechaActualizacion,
  }) {
    return ConfiguracionImpuestos(
      id: id ?? this.id,
      porcentajeIva: porcentajeIva ?? this.porcentajeIva,
      porcentajeIt: porcentajeIt ?? this.porcentajeIt,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }
}
