import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_badge.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_table.dart';
import '../providers/paquetes_servicios_provider.dart';

class PaqueteServicioDetailScreen extends ConsumerWidget {
  const PaqueteServicioDetailScreen({required this.paqueteId, super.key});

  final String paqueteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paquetesAsync = ref.watch(paquetesServiciosProvider);
    final paquete = ref.watch(paqueteServicioByIdProvider(paqueteId));

    if (paquete == null) {
      if (paquetesAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (paquetesAsync.hasError) {
        return Center(child: Text('Error al cargar paquete: ${paquetesAsync.error}'));
      }
      return const Center(child: Text('Paquete no encontrado.'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  paquete.nombre,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/configuracion/paquetes/${paquete.id}/editar'),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Editar'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppSectionCard(
            title: 'Información del paquete',
            trailing: AppBadge(
              label: paquete.activo ? 'Activo' : 'Inactivo',
              backgroundColor: paquete.activo ? Colors.green : AppColors.accent,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Descripción: ${paquete.descripcion ?? 'Sin descripción'}'),
                const SizedBox(height: AppSpacing.xs),
                Text('Servicios incluidos: ${paquete.items.length}'),
                const SizedBox(height: AppSpacing.xs),
                Text('Precio total: ${_formatBs(paquete.precioTotalCalculado)}'),
                if (paquete.precioManual != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text('Precio manual: ${_formatBs(paquete.precioManual!)}'),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionCard(
            title: 'Servicios del paquete',
            child: paquete.items.isEmpty
                ? const Text('Este paquete no tiene servicios asociados.')
                : AppDataTable(
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Servicio')),
                      DataColumn(label: Text('Categoría')),
                      DataColumn(label: Text('Cantidad')),
                      DataColumn(label: Text('Precio unitario')),
                      DataColumn(label: Text('Subtotal')),
                    ],
                    rows: [
                      for (final item in paquete.items)
                        DataRow(
                          cells: [
                            DataCell(Text(item.servicio?.nombre ?? 'Servicio eliminado')),
                            DataCell(Text(item.servicio?.categoria ?? '—')),
                            DataCell(Text('${item.cantidad}')),
                            DataCell(Text(_formatBs(item.servicio?.precio ?? 0))),
                            DataCell(Text(_formatBs((item.servicio?.precio ?? 0) * item.cantidad))),
                          ],
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _formatBs(double value) {
    return 'Bs. ${value.toStringAsFixed(2)}';
  }
}
