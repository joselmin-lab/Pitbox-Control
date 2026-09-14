import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';

class TrabajosScreen extends StatelessWidget {
  const TrabajosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trabajos',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.md),
        AppSectionCard(
          title: 'Recepción de vehículos',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registra el ingreso del vehículo, checklist, inventario, daños, fotografías y firmas.',
              ),
              const SizedBox(height: AppSpacing.md),
              AppPrimaryButton(
                label: 'Abrir recepciones',
                icon: Icons.assignment_rounded,
                onPressed: () => context.go('/trabajos/recepciones'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
