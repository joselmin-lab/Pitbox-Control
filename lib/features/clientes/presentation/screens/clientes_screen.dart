import 'package:flutter/material.dart';

import '../../../../shared/widgets/feature_placeholder.dart';

class ClientesScreen extends StatelessWidget {
  const ClientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Módulo Clientes',
      description: 'Próximamente podrás administrar fichas de clientes, historial y contactos.',
      icon: Icons.people_alt_rounded,
    );
  }
}
