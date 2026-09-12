import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../clientes/presentation/providers/clientes_provider.dart';
import '../../../vehiculos/presentation/providers/vehiculos_provider.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/kpi_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalClientes = ref.watch(clientesProvider).when(
          data: (clientes) => '${clientes.length}',
          loading: () => '...',
          error: (_, _) => '—',
        );
    final totalVehiculos = ref.watch(vehiculosProvider).when(
          data: (vehiculos) => '${vehiculos.length}',
          loading: () => '...',
          error: (_, _) => '—',
        );
    final kpis = <({String title, String value, IconData icon, bool highlight})>[
      (
        title: 'Total clientes',
        value: totalClientes,
        icon: Icons.people_alt_rounded,
        highlight: true,
      ),
      (
        title: 'Total vehículos',
        value: totalVehiculos,
        icon: Icons.directions_car_filled_rounded,
        highlight: false,
      ),
      (
        title: 'Proformas pendientes',
        value: '3',
        icon: Icons.receipt_long_rounded,
        highlight: false,
      ),
      (
        title: 'Trabajos del día',
        value: '5',
        icon: Icons.build_circle_rounded,
        highlight: false,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactHeader = constraints.maxWidth < 720;
        final bottomStacked = constraints.maxWidth < 980;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCompactHeader)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard general',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Resumen operativo base del taller con métricas y seguimiento diario.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppPrimaryButton(
                      label: 'Nueva proforma',
                      icon: Icons.add_rounded,
                      onPressed: () {},
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard general',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Resumen operativo base del taller con métricas y seguimiento diario.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    AppPrimaryButton(
                      label: 'Nueva proforma',
                      icon: Icons.add_rounded,
                      onPressed: () {},
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, gridConstraints) {
                  final crossAxisCount = gridConstraints.maxWidth >= 1200
                      ? 4
                      : gridConstraints.maxWidth >= 700
                          ? 2
                          : 1;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: kpis.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      mainAxisExtent: 150,
                    ),
                    itemBuilder: (context, index) {
                      final item = kpis[index];
                      return KpiCard(
                        title: item.title,
                        value: item.value,
                        icon: item.icon,
                        highlight: item.highlight,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              if (bottomStacked)
                Column(
                  children: [
                    AppSectionCard(
                      title: 'Estado rápido',
                      trailing: const AppBadge(
                        label: 'En línea',
                        backgroundColor: AppColors.success,
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StatusRow(label: 'Recepciones programadas', value: '4'),
                          SizedBox(height: AppSpacing.sm),
                          _StatusRow(label: 'Mecánicos activos', value: '6'),
                          SizedBox(height: AppSpacing.sm),
                          _StatusRow(label: 'Alertas de stock', value: '2'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppSectionCard(
                      title: 'Trabajos recientes',
                      child: const AppDataTable(
                        columns: [
                          DataColumn(label: Text('Orden')),
                          DataColumn(label: Text('Cliente')),
                          DataColumn(label: Text('Estado')),
                        ],
                        rows: [
                          DataRow(cells: [
                            DataCell(Text('TB-1042')),
                            DataCell(Text('María López')),
                            DataCell(AppBadge(label: 'En proceso')),
                          ]),
                          DataRow(cells: [
                            DataCell(Text('TB-1043')),
                            DataCell(Text('Carlos Pérez')),
                            DataCell(
                              AppBadge(
                                label: 'Pendiente',
                                backgroundColor: AppColors.warning,
                                foregroundColor: AppColors.textPrimary,
                              ),
                            ),
                          ]),
                          DataRow(cells: [
                            DataCell(Text('TB-1044')),
                            DataCell(Text('Ana Rojas')),
                            DataCell(AppBadge(label: 'Listo', backgroundColor: AppColors.success)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: AppSectionCard(
                        title: 'Estado rápido',
                        trailing: const AppBadge(
                          label: 'En línea',
                          backgroundColor: AppColors.success,
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _StatusRow(label: 'Recepciones programadas', value: '4'),
                            SizedBox(height: AppSpacing.sm),
                            _StatusRow(label: 'Mecánicos activos', value: '6'),
                            SizedBox(height: AppSpacing.sm),
                            _StatusRow(label: 'Alertas de stock', value: '2'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 5,
                      child: AppSectionCard(
                        title: 'Trabajos recientes',
                        child: const AppDataTable(
                          columns: [
                            DataColumn(label: Text('Orden')),
                            DataColumn(label: Text('Cliente')),
                            DataColumn(label: Text('Estado')),
                          ],
                          rows: [
                            DataRow(cells: [
                              DataCell(Text('TB-1042')),
                              DataCell(Text('María López')),
                              DataCell(AppBadge(label: 'En proceso')),
                            ]),
                            DataRow(cells: [
                              DataCell(Text('TB-1043')),
                              DataCell(Text('Carlos Pérez')),
                              DataCell(
                                AppBadge(
                                  label: 'Pendiente',
                                  backgroundColor: AppColors.warning,
                                  foregroundColor: AppColors.textPrimary,
                                ),
                              ),
                            ]),
                            DataRow(cells: [
                              DataCell(Text('TB-1044')),
                              DataCell(Text('Ana Rojas')),
                              DataCell(AppBadge(label: 'Listo', backgroundColor: AppColors.success)),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
