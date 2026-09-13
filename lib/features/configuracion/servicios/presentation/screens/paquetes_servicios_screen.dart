import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_badge.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_table.dart';
import '../../../../../shared/widgets/confirm_delete_dialog.dart';
import '../providers/paquetes_servicios_provider.dart';

class PaquetesServiciosScreen extends ConsumerStatefulWidget {
  const PaquetesServiciosScreen({super.key});

  @override
  ConsumerState<PaquetesServiciosScreen> createState() => _PaquetesServiciosScreenState();
}

class _PaquetesServiciosScreenState extends ConsumerState<PaquetesServiciosScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paquetesAsync = ref.watch(paquetesServiciosProvider);
    final paquetes = ref.watch(paquetesServiciosFiltradosProvider);
    final query = ref.watch(paquetesServiciosSearchQueryProvider);

    if (_searchController.text != query) {
      _searchController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Paquetes de servicios',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            AppPrimaryButton(
              label: 'Nuevo paquete',
              icon: Icons.add_box_rounded,
              onPressed: () => context.go('/configuracion/paquetes/nuevo'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: 340,
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Buscar paquete',
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Nombre del paquete',
            ),
            onChanged: (value) => ref.read(paquetesServiciosSearchQueryProvider.notifier).state = value,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: AppSectionCard(
            title: 'Listado de paquetes',
            child: paquetesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error al cargar paquetes: $error'),
              data: (_) {
                if (paquetes.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Text('No se encontraron paquetes con ese criterio.'),
                  );
                }

                return AppDataTable(
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Servicios incluidos')),
                    DataColumn(label: Text('Precio total')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: [
                    for (final paquete in paquetes)
                      DataRow(
                        cells: [
                          DataCell(Text(paquete.nombre)),
                          DataCell(Text('${paquete.items.length}')),
                          DataCell(Text(_formatBs(paquete.precioTotalCalculado))),
                          DataCell(
                            AppBadge(
                              label: paquete.activo ? 'Activo' : 'Inactivo',
                              backgroundColor: paquete.activo ? Colors.green : AppColors.accent,
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Ver detalle',
                                  onPressed: () => context.go('/configuracion/paquetes/${paquete.id}'),
                                  icon: const Icon(Icons.visibility_rounded),
                                ),
                                IconButton(
                                  tooltip: 'Editar',
                                  onPressed: () => context.go('/configuracion/paquetes/${paquete.id}/editar'),
                                  icon: const Icon(Icons.edit_rounded),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  onPressed: () async {
                                    final accepted = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => const ConfirmDeleteDialog(
                                        title: 'Eliminar paquete',
                                        message: '¿Seguro que deseas eliminar este paquete?',
                                      ),
                                    );
                                    if (accepted != true || !context.mounted) {
                                      return;
                                    }
                                    try {
                                      await ref.read(paquetesServiciosProvider.notifier).delete(paquete.id);
                                    } catch (error) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('No se pudo eliminar el paquete: $error')),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.delete_rounded),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _formatBs(double value) {
    return 'Bs. ${value.toStringAsFixed(2)}';
  }
}
