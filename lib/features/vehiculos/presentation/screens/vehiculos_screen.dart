import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder.dart';

class VehiculosScreen extends StatelessWidget {
  const VehiculosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Módulo Vehículos',
      description: 'Próximamente podrás registrar vehículos, placas, marcas y relación con clientes.',
      icon: Icons.directions_car_filled_rounded,
    );
  }
}
