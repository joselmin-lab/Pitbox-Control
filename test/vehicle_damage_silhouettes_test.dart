import 'package:flutter_test/flutter_test.dart';
import 'package:pitbox_control/features/trabajos/recepciones/domain/models/recepcion_vehiculo.dart';
import 'package:pitbox_control/features/trabajos/recepciones/presentation/widgets/vehicle_damage_silhouettes.dart';

void main() {
  test('cada vista de daños tiene un asset SVG asignado', () {
    expect(vehicleDamageSilhouetteAssetPaths.length, RecepcionVistaVehiculo.values.length);
    for (final vista in RecepcionVistaVehiculo.values) {
      final assetPath = vehicleDamageSilhouetteAssetFor(vista);
      expect(assetPath, startsWith('assets/images/vehiculo_danos/'));
      expect(assetPath, endsWith('.svg'));
    }
  });

  test('los assets de vistas son únicos', () {
    final uniqueAssets = vehicleDamageSilhouetteAssetPaths.values.toSet();
    expect(uniqueAssets.length, vehicleDamageSilhouetteAssetPaths.length);
  });
}
