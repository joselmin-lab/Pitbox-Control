import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder.dart';

class ProformasScreen extends StatelessWidget {
  const ProformasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Módulo Proformas',
      description: 'Próximamente podrás generar y revisar cotizaciones del taller.',
      icon: Icons.receipt_long_rounded,
    );
  }
}
