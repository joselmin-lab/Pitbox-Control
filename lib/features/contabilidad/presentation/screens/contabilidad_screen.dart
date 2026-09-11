import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder.dart';

class ContabilidadScreen extends StatelessWidget {
  const ContabilidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Módulo Contabilidad',
      description: 'Próximamente podrás monitorear ingresos, egresos y cierres diarios.',
      icon: Icons.assessment_rounded,
    );
  }
}
