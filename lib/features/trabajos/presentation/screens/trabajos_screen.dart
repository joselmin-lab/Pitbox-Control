import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder.dart';

class TrabajosScreen extends StatelessWidget {
  const TrabajosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Módulo Trabajos',
      description: 'Próximamente podrás coordinar órdenes, avances y entregas.',
      icon: Icons.build_rounded,
    );
  }
}
