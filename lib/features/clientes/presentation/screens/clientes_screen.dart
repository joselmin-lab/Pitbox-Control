import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_table.dart';
import '../providers/clientes_provider.dart';

class ClientesScreen extends ConsumerStatefulWidget {
  const ClientesScreen({super.key});

  @override
  ConsumerState<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends ConsumerState<ClientesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientesAsync = ref.watch(clientesProvider);
    final clientes = ref.watch(clientesFiltradosProvider);
    final query = ref.watch(clientesSearchQueryProvider);

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
                'Clientes',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            AppPrimaryButton(
              label: 'Nuevo Cliente',
              icon: Icons.person_add_alt_1_rounded,
              onPressed: () => context.go('/clientes/nuevo'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Buscar cliente',
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Buscar por nombre o teléfono',
          ),
          onChanged: (value) => ref.read(clientesSearchQueryProvider.notifier).state = value,
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: AppSectionCard(
            title: 'Listado de clientes',
            child: clientesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error al cargar clientes: $error'),
              data: (_) {
                if (clientes.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Text('No se encontraron clientes con ese criterio.'),
                  );
                }

                return AppDataTable(
                  columns: const [
                    DataColumn(label: Text('Nombre')),
                    DataColumn(label: Text('Teléfono')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Registro')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: [
                    for (final cliente in clientes)
                      DataRow(
                        cells: [
                          DataCell(Text(cliente.nombreCompleto)),
                          DataCell(Text(cliente.telefono)),
                          DataCell(Text(cliente.email ?? '—')),
                          DataCell(Text(_formatDate(cliente.fechaRegistro))),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Ver detalle',
                                  onPressed: () => context.go('/clientes/${cliente.id}'),
                                  icon: const Icon(Icons.visibility_rounded),
                                ),
                                IconButton(
                                  tooltip: 'Editar',
                                  onPressed: () => context.go('/clientes/${cliente.id}/editar'),
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
