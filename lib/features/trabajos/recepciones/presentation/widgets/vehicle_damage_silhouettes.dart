import 'package:flutter/services.dart';

import '../../domain/models/recepcion_vehiculo.dart';

const Map<RecepcionVistaVehiculo, String> vehicleDamageSilhouetteAssetPaths = {
  RecepcionVistaVehiculo.derecho: 'assets/images/vehiculo_danos/lado_derecho.svg',
  RecepcionVistaVehiculo.frente: 'assets/images/vehiculo_danos/frente.svg',
  RecepcionVistaVehiculo.detras: 'assets/images/vehiculo_danos/detras.svg',
  RecepcionVistaVehiculo.izquierdo: 'assets/images/vehiculo_danos/lado_izquierdo.svg',
};

String vehicleDamageSilhouetteAssetFor(RecepcionVistaVehiculo vista) {
  return vehicleDamageSilhouetteAssetPaths[vista] ?? vehicleDamageSilhouetteAssetPaths.values.first;
}

Future<Map<RecepcionVistaVehiculo, String>> loadVehicleDamageSilhouettesSvg() async {
  final entries = await Future.wait(
    vehicleDamageSilhouetteAssetPaths.entries.map((entry) async {
      String svg;
      try {
        svg = await rootBundle.loadString(entry.value);
      } catch (_) {
        svg = '';
      }
      return MapEntry(entry.key, svg);
    }),
  );
  return Map<RecepcionVistaVehiculo, String>.fromEntries(entries);
}
