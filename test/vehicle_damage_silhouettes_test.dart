import 'package:flutter_test/flutter_test.dart';
import 'package:pitbox_control/features/trabajos/recepciones/domain/models/recepcion_vehiculo.dart';
import 'package:pitbox_control/features/trabajos/recepciones/presentation/widgets/vehicle_damage_silhouettes.dart';

void main() {
  test('cada vista de daños tiene un asset SVG asignado', () {
    for (final vista in RecepcionVistaVehiculo.values) {
      final assetPath = vehicleDamageSilhouetteAssetFor(vista);
      expect(assetPath, startsWith('assets/images/vehiculo_danos/'));
      expect(assetPath, endsWith('.svg'));
    }
  });
}
