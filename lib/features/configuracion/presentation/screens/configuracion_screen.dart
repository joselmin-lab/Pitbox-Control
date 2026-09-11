import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder.dart';

class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Módulo Configuración',
      description: 'Próximamente podrás administrar catálogos, parámetros y preferencias del sistema.',
      icon: Icons.settings_rounded,
    );
  }
}
