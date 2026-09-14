import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_badge.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_table.dart';
import '../../../../clientes/presentation/providers/clientes_provider.dart';
import '../../../../vehiculos/presentation/providers/vehiculos_provider.dart';
import '../../domain/models/recepcion_vehiculo.dart';
import '../providers/recepciones_provider.dart';

class RecepcionesScreen extends ConsumerStatefulWidget {
  const RecepcionesScreen({super.key});

  @override
  ConsumerState<RecepcionesScreen> createState() => _RecepcionesScreenState();
}

class _RecepcionesScreenState extends ConsumerState<RecepcionesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recepcionesAsync = ref.watch(recepcionesProvider);
    final recepcionesBase = ref.watch(recepcionesFiltradasProvider);
    final query = ref.watch(recepcionesSearchQueryProvider);
    final clientes = ref.watch(clientesProvider).valueOrNull ?? const [];
    final vehiculos = ref.watch(vehiculosProvider).valueOrNull ?? const [];

    if (_searchController.text != query) {
      _searchController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }

    final clientesById = {for (final cliente in clientes) cliente.id: cliente.nombreCompleto};
    final vehiculosById = {
      for (final vehiculo in vehiculos) vehiculo.id: '${vehiculo.placa} · ${vehiculo.marca} ${vehiculo.modelo}',
    };
    final queryNorm = query.trim().toLowerCase();
    final recepciones = recepcionesBase.where((recepcion) {
      if (queryNorm.isEmpty) {
        return true;
      }
      final cliente = (clientesById[recepcion.clienteId] ?? '').toLowerCase();
      final vehiculo = (vehiculosById[recepcion.vehiculoId] ?? '').toLowerCase();
      return recepcion.numero.toLowerCase().contains(queryNorm) ||
          cliente.contains(queryNorm) ||
          vehiculo.contains(queryNorm);
    }).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recepciones de vehículos',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            AppPrimaryButton(
              label: 'Nueva recepción',
              icon: Icons.assignment_add_rounded,
              onPressed: () => context.go('/trabajos/recepciones/nueva'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Buscar recepción',
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Buscar por número, cliente o vehículo',
          ),
          onChanged: (value) => ref.read(recepcionesSearchQueryProvider.notifier).state = value,
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: AppSectionCard(
            title: 'Listado de recepciones',
            child: recepcionesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error al cargar recepciones: $error'),
              data: (_) {
                if (recepciones.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Text('No hay recepciones registradas.'),
                  );
                }

                return AppDataTable(
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(label: Text('N° Recepción')),
                    DataColumn(label: Text('Cliente')),
                    DataColumn(label: Text('Vehículo')),
                    DataColumn(label: Text('Ingreso')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: [
                    for (final recepcion in recepciones)
                      DataRow(
                        cells: [
                          DataCell(Text(recepcion.numero)),
                          DataCell(Text(clientesById[recepcion.clienteId] ?? '—')),
                          DataCell(Text(vehiculosById[recepcion.vehiculoId] ?? '—')),
                          DataCell(Text(_formatDate(recepcion.fechaIngreso))),
                          DataCell(
                            AppBadge(
                              label: recepcion.estado.label,
                              backgroundColor: recepcion.estado == RecepcionEstado.abierta
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Ver detalle',
                                  onPressed: () => context.go('/trabajos/recepciones/${recepcion.id}'),
                                  icon: const Icon(Icons.visibility_rounded),
                                ),
                                IconButton(
                                  tooltip: 'Editar',
                                  onPressed: () => context.go('/trabajos/recepciones/${recepcion.id}/editar'),
                                  icon: const Icon(Icons.edit_rounded),
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

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}
