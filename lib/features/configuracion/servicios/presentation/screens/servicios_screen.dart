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
import '../../domain/models/paquete_servicio.dart';
import '../../domain/models/servicio.dart';
import '../providers/paquetes_servicios_provider.dart';
import '../providers/servicios_provider.dart';

class ServiciosScreen extends ConsumerStatefulWidget {
  const ServiciosScreen({super.key});

  @override
  ConsumerState<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends ConsumerState<ServiciosScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serviciosAsync = ref.watch(serviciosProvider);
    final servicios = ref.watch(serviciosFiltradosProvider);
    final query = ref.watch(serviciosSearchQueryProvider);
    final categoriaFilter = ref.watch(serviciosCategoriaFilterProvider);
    final List<Servicio> allServicios = serviciosAsync.valueOrNull ?? const <Servicio>[];
    final categorias = {
      for (final servicio in allServicios)
        if ((servicio.categoria ?? '').trim().isNotEmpty) servicio.categoria!.trim(),
    }.toList()
      ..sort();

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
                'Servicios',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            AppPrimaryButton(
              label: 'Nuevo servicio',
              icon: Icons.add_rounded,
              onPressed: () => context.go('/configuracion/servicios/nuevo'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Buscar servicio',
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Nombre o categoría',
                ),
                onChanged: (value) => ref.read(serviciosSearchQueryProvider.notifier).state = value,
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                value: categoriaFilter ?? '',
                decoration: const InputDecoration(labelText: 'Filtrar por categoría'),
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('Todas'),
                  ),
                  for (final categoria in categorias)
                    DropdownMenuItem<String>(
                      value: categoria,
                      child: Text(categoria),
                    ),
                ],
                onChanged: (value) {
                  ref.read(serviciosCategoriaFilterProvider.notifier).state =
                      (value == null || value.isEmpty) ? null : value;
                },
              ),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await ref.read(serviciosProvider.notifier).exportarCsv();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('CSV exportado correctamente.')),
                    );
                  }
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No se pudo exportar CSV: $error')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.download_rounded),
              label: const Text('Exportar CSV'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await ref.read(serviciosProvider.notifier).importarCsvDesdeArchivo();
                if (!context.mounted || result == null) {
                  return;
                }
                await showDialog<void>(
                  context: context,
                  builder: (_) {
                    return AlertDialog(
                      title: const Text('Resultado de importación CSV'),
                      content: SizedBox(
                        width: 420,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Creados: ${result.created}'),
                            Text('Actualizados: ${result.updated}'),
                            Text('Omitidos: ${result.skipped}'),
                            if (result.errors.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              const Text('Errores:'),
                              const SizedBox(height: AppSpacing.xs),
                              Flexible(
                                child: SingleChildScrollView(
                                  child: Text(result.errors.join('\n')),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Importar CSV'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text('Formato esperado: nombre,descripcion,precio,categoria,activo'),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: AppSectionCard(
            title: 'Listado de servicios',
            child: serviciosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error al cargar servicios: $error'),
              data: (_) {
                if (servicios.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Text('No se encontraron servicios con ese criterio.'),
                  );
                }

                return AppDataTable(
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Categoría')),
                    DataColumn(label: Text('Precio')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: [
                    for (final servicio in servicios)
                      DataRow(
                        cells: [
                          DataCell(Text(servicio.nombre)),
                          DataCell(Text(servicio.categoria ?? '—')),
                          DataCell(Text(_formatBs(servicio.precio))),
                          DataCell(
                            AppBadge(
                              label: servicio.activo ? 'Activo' : 'Inactivo',
                              backgroundColor: servicio.activo ? Colors.green : AppColors.accent,
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Editar',
                                  onPressed: () => context.go('/configuracion/servicios/${servicio.id}/editar'),
                                  icon: const Icon(Icons.edit_rounded),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  onPressed: () async {
                                    final List<PaqueteServicio> paquetes =
                                        ref.read(paquetesServiciosProvider).valueOrNull ??
                                        const <PaqueteServicio>[];
                                    final usadosEnPaquetes = paquetes
                                        .where(
                                          (paquete) =>
                                              paquete.items.any((item) => item.servicioId == servicio.id),
                                        )
                                        .length;
                                    final warning = usadosEnPaquetes > 0
                                        ? 'Este servicio está asociado en $usadosEnPaquetes paquete(s). Si lo eliminas, también se eliminará de esos paquetes.'
                                        : '¿Seguro que deseas eliminar este servicio?';
                                    final accepted = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => ConfirmDeleteDialog(
                                        title: 'Eliminar servicio',
                                        message: warning,
                                      ),
                                    );
                                    if (accepted != true || !context.mounted) {
                                      return;
                                    }
                                    try {
                                      await ref.read(serviciosProvider.notifier).delete(servicio.id);
                                    } catch (error) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('No se pudo eliminar el servicio: $error'),
                                          ),
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
