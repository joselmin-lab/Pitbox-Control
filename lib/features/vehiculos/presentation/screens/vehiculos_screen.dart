import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../clientes/presentation/providers/clientes_provider.dart';
import '../providers/vehiculos_provider.dart';

class VehiculosScreen extends ConsumerStatefulWidget {
  const VehiculosScreen({super.key});

  @override
  ConsumerState<VehiculosScreen> createState() => _VehiculosScreenState();
}

class _VehiculosScreenState extends ConsumerState<VehiculosScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehiculosAsync = ref.watch(vehiculosProvider);
    final vehiculos = ref.watch(vehiculosFiltradosProvider);
    final clientes = ref.watch(clientesProvider).maybeWhen(
          data: (value) => value,
          orElse: () => const [],
        );
    final query = ref.watch(vehiculosSearchQueryProvider);

    if (_searchController.text != query) {
      _searchController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }

    final clientesById = {
      for (final cliente in clientes) cliente.id: cliente.nombreCompleto,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Vehículos',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            AppPrimaryButton(
              label: 'Nuevo Vehículo',
              icon: Icons.add_rounded,
              onPressed: () => context.go('/vehiculos/nuevo'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Buscar vehículo',
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Buscar por placa, marca o modelo',
          ),
          onChanged: (value) => ref.read(vehiculosSearchQueryProvider.notifier).state = value,
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: AppSectionCard(
            title: 'Listado de vehículos',
            child: vehiculosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error al cargar vehículos: $error'),
              data: (_) {
                if (vehiculos.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Text('No se encontraron vehículos con ese criterio.'),
                  );
                }
                return AppDataTable(
                  columns: const [
                    DataColumn(label: Text('Placa')),
                    DataColumn(label: Text('Marca')),
                    DataColumn(label: Text('Modelo')),
                    DataColumn(label: Text('Cliente')),
                    DataColumn(label: Text('Año')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: [
                    for (final vehiculo in vehiculos)
                      DataRow(cells: [
                        DataCell(Text(vehiculo.placa)),
                        DataCell(Text(vehiculo.marca)),
                        DataCell(Text(vehiculo.modelo)),
                        DataCell(Text(clientesById[vehiculo.clienteId] ?? 'Sin cliente')),
                        DataCell(Text('${vehiculo.anio}')),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Ver detalle',
                                onPressed: () => context.go('/vehiculos/${vehiculo.id}'),
                                icon: const Icon(Icons.visibility_rounded),
                              ),
                              IconButton(
                                tooltip: 'Editar',
                                onPressed: () => context.go('/vehiculos/${vehiculo.id}/editar'),
                                icon: const Icon(Icons.edit_rounded),
                              ),
                            ],
                          ),
                        ),
                      ]),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
