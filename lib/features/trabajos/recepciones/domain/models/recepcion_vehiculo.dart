enum RecepcionEstado {
  abierta,
  vehiculoEntregado,
}

enum RecepcionVistaVehiculo {
  derecho,
  frente,
  detras,
  izquierdo,
}

extension RecepcionEstadoX on RecepcionEstado {
  String get label {
    switch (this) {
      case RecepcionEstado.abierta:
        return 'Abierta';
      case RecepcionEstado.vehiculoEntregado:
        return 'Vehículo entregado';
    }
  }
}

extension RecepcionVistaVehiculoX on RecepcionVistaVehiculo {
  String get clave {
    switch (this) {
      case RecepcionVistaVehiculo.derecho:
        return 'derecho';
      case RecepcionVistaVehiculo.frente:
        return 'frente';
      case RecepcionVistaVehiculo.detras:
        return 'detras';
      case RecepcionVistaVehiculo.izquierdo:
        return 'izquierdo';
    }
  }

  String get label {
    switch (this) {
      case RecepcionVistaVehiculo.derecho:
        return 'Lado derecho';
      case RecepcionVistaVehiculo.frente:
        return 'Frente';
      case RecepcionVistaVehiculo.detras:
        return 'Detrás';
      case RecepcionVistaVehiculo.izquierdo:
        return 'Lado izquierdo';
    }
  }

  static RecepcionVistaVehiculo fromClave(String value) {
    switch (value) {
      case 'derecho':
        return RecepcionVistaVehiculo.derecho;
      case 'frente':
        return RecepcionVistaVehiculo.frente;
      case 'detras':
        return RecepcionVistaVehiculo.detras;
      case 'izquierdo':
        return RecepcionVistaVehiculo.izquierdo;
      default:
        throw FormatException('Vista de vehículo inválida: $value');
    }
  }
}

class RecepcionChecklistItem {
  const RecepcionChecklistItem({
    required this.clave,
    required this.etiqueta,
    required this.icono,
    this.marcado = false,
  });

  final String clave;
  final String etiqueta;
  final String icono;
  final bool marcado;

  RecepcionChecklistItem copyWith({
    String? clave,
    String? etiqueta,
    String? icono,
    bool? marcado,
  }) {
    return RecepcionChecklistItem(
      clave: clave ?? this.clave,
      etiqueta: etiqueta ?? this.etiqueta,
      icono: icono ?? this.icono,
      marcado: marcado ?? this.marcado,
    );
  }
}

class RecepcionInventarioItem {
  const RecepcionInventarioItem({
    required this.item,
    this.marcado = false,
  });

  final String item;
  final bool marcado;

  RecepcionInventarioItem copyWith({
    String? item,
    bool? marcado,
  }) {
    return RecepcionInventarioItem(
      item: item ?? this.item,
      marcado: marcado ?? this.marcado,
    );
  }
}

class DanoVehiculoMarcado {
  const DanoVehiculoMarcado({
    required this.vista,
    required this.x,
    required this.y,
    this.descripcion,
  });

  final RecepcionVistaVehiculo vista;
  final double x;
  final double y;
  final String? descripcion;

  DanoVehiculoMarcado copyWith({
    RecepcionVistaVehiculo? vista,
    double? x,
    double? y,
    String? descripcion,
    bool clearDescripcion = false,
  }) {
    return DanoVehiculoMarcado(
      vista: vista ?? this.vista,
      x: x ?? this.x,
      y: y ?? this.y,
      descripcion: clearDescripcion ? null : (descripcion ?? this.descripcion),
    );
  }
}

class RecepcionVehiculo {
  const RecepcionVehiculo({
    required this.id,
    required this.numero,
    required this.clienteId,
    required this.vehiculoId,
    required this.fechaIngreso,
    this.fechaSalidaEstimada,
    this.kilometraje,
    this.ingresoEnGrua = false,
    this.trabajoARealizar,
    this.observaciones,
    this.checklistSistemas = recepcionChecklistBase,
    this.inventario = recepcionInventarioBase,
    this.nivelCombustible = 0,
    this.danosPreexistentes = const <DanoVehiculoMarcado>[],
    this.fotografias = const <String>[],
    this.firmaPrestadorUrl,
    this.firmaClienteUrl,
    this.estado = RecepcionEstado.abierta,
    required this.fechaCreacion,
  });

  final String id;
  final String numero;
  final String clienteId;
  final String vehiculoId;
  final DateTime fechaIngreso;
  final DateTime? fechaSalidaEstimada;
  final String? kilometraje;
  final bool ingresoEnGrua;
  final String? trabajoARealizar;
  final String? observaciones;
  final List<RecepcionChecklistItem> checklistSistemas;
  final List<RecepcionInventarioItem> inventario;
  final double nivelCombustible;
  final List<DanoVehiculoMarcado> danosPreexistentes;
  final List<String> fotografias;
  final String? firmaPrestadorUrl;
  final String? firmaClienteUrl;
  final RecepcionEstado estado;
  final DateTime fechaCreacion;

  bool get firmasCompletas {
    return (firmaPrestadorUrl?.trim().isNotEmpty ?? false) &&
        (firmaClienteUrl?.trim().isNotEmpty ?? false);
  }

  RecepcionVehiculo copyWith({
    String? id,
    String? numero,
    String? clienteId,
    String? vehiculoId,
    DateTime? fechaIngreso,
    DateTime? fechaSalidaEstimada,
    bool clearFechaSalidaEstimada = false,
    String? kilometraje,
    bool clearKilometraje = false,
    bool? ingresoEnGrua,
    String? trabajoARealizar,
    bool clearTrabajoARealizar = false,
    String? observaciones,
    bool clearObservaciones = false,
    List<RecepcionChecklistItem>? checklistSistemas,
    List<RecepcionInventarioItem>? inventario,
    double? nivelCombustible,
    List<DanoVehiculoMarcado>? danosPreexistentes,
    List<String>? fotografias,
    String? firmaPrestadorUrl,
    bool clearFirmaPrestadorUrl = false,
    String? firmaClienteUrl,
    bool clearFirmaClienteUrl = false,
    RecepcionEstado? estado,
    DateTime? fechaCreacion,
  }) {
    return RecepcionVehiculo(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      clienteId: clienteId ?? this.clienteId,
      vehiculoId: vehiculoId ?? this.vehiculoId,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      fechaSalidaEstimada: clearFechaSalidaEstimada
          ? null
          : (fechaSalidaEstimada ?? this.fechaSalidaEstimada),
      kilometraje: clearKilometraje ? null : (kilometraje ?? this.kilometraje),
      ingresoEnGrua: ingresoEnGrua ?? this.ingresoEnGrua,
      trabajoARealizar: clearTrabajoARealizar
          ? null
          : (trabajoARealizar ?? this.trabajoARealizar),
      observaciones: clearObservaciones ? null : (observaciones ?? this.observaciones),
      checklistSistemas: checklistSistemas ?? this.checklistSistemas,
      inventario: inventario ?? this.inventario,
      nivelCombustible: nivelCombustible ?? this.nivelCombustible,
      danosPreexistentes: danosPreexistentes ?? this.danosPreexistentes,
      fotografias: fotografias ?? this.fotografias,
      firmaPrestadorUrl: clearFirmaPrestadorUrl
          ? null
          : (firmaPrestadorUrl ?? this.firmaPrestadorUrl),
      firmaClienteUrl: clearFirmaClienteUrl ? null : (firmaClienteUrl ?? this.firmaClienteUrl),
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}

const recepcionChecklistBase = <RecepcionChecklistItem>[
  RecepcionChecklistItem(clave: 'llave', etiqueta: 'Llave', icono: 'key'),
  RecepcionChecklistItem(clave: 'motor', etiqueta: 'Motor', icono: 'engine'),
  RecepcionChecklistItem(clave: 'abs', etiqueta: 'ABS', icono: 'abs'),
  RecepcionChecklistItem(clave: 'aceite_bateria', etiqueta: 'Aceite/Batería', icono: 'oil_battery'),
  RecepcionChecklistItem(clave: 'grua', etiqueta: 'Grúa/Seguridad', icono: 'tow'),
  RecepcionChecklistItem(clave: 'estacionamiento', etiqueta: 'Estacionamiento', icono: 'parking'),
  RecepcionChecklistItem(clave: 'luces', etiqueta: 'Luces/Faros', icono: 'lights'),
  RecepcionChecklistItem(clave: 'limpiaparabrisas', etiqueta: 'Limpiaparabrisas', icono: 'wiper'),
  RecepcionChecklistItem(clave: 'temperatura', etiqueta: 'Temperatura', icono: 'temperature'),
];

const recepcionInventarioBase = <RecepcionInventarioItem>[
  RecepcionInventarioItem(item: 'Gato'),
  RecepcionInventarioItem(item: 'Herramientas'),
  RecepcionInventarioItem(item: 'Triángulos'),
  RecepcionInventarioItem(item: 'Tapetes'),
  RecepcionInventarioItem(item: 'Llanta de refacción'),
  RecepcionInventarioItem(item: 'Extintor'),
  RecepcionInventarioItem(item: 'Antena'),
  RecepcionInventarioItem(item: 'Emblemas'),
  RecepcionInventarioItem(item: 'Tapones de rueda'),
  RecepcionInventarioItem(item: 'Cables'),
  RecepcionInventarioItem(item: 'Estéreo'),
  RecepcionInventarioItem(item: 'Encendedor'),
];
