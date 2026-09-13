import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';

class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuración',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Administra catálogos y parámetros del sistema.'),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            SizedBox(
              width: 360,
              child: AppSectionCard(
                title: 'Servicios',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gestiona servicios con precios facturados e importación/exportación CSV.'),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/configuracion/servicios'),
                      icon: const Icon(Icons.miscellaneous_services_rounded),
                      label: const Text('Abrir servicios'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 360,
              child: AppSectionCard(
                title: 'Paquetes de servicios',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Agrupa varios servicios y define precio total automático o manual.'),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/configuracion/paquetes'),
                      icon: const Icon(Icons.inventory_2_rounded),
                      label: const Text('Abrir paquetes'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 360,
              child: AppSectionCard(
                title: 'Datos del taller',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Configura el nombre, contacto y logo del taller.'),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/configuracion/taller'),
                      icon: const Icon(Icons.storefront_rounded),
                      label: const Text('Abrir datos del taller'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
