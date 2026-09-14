import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../clientes/presentation/providers/clientes_provider.dart';
import '../../../vehiculos/presentation/providers/vehiculos_provider.dart';
import '../../domain/models/proforma.dart';
import '../providers/proformas_provider.dart';

class ProformasScreen extends ConsumerStatefulWidget {
  const ProformasScreen({super.key});

  @override
  ConsumerState<ProformasScreen> createState() => _ProformasScreenState();
}

class _ProformasScreenState extends ConsumerState<ProformasScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proformasAsync = ref.watch(proformasProvider);
    final proformasBase = ref.watch(proformasFiltradasProvider);
    final query = ref.watch(proformasSearchQueryProvider);
    final clientes = ref.watch(clientesProvider).valueOrNull ?? const [];
    final vehiculos = ref.watch(vehiculosProvider).valueOrNull ?? const [];

    if (_searchController.text != query) {
      _searchController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }

    final clientesById = {for (final cliente in clientes) cliente.id: cliente.nombreCompleto};
    final vehiculosById = {for (final vehiculo in vehiculos) vehiculo.id: '${vehiculo.placa} · ${vehiculo.marca} ${vehiculo.modelo}'};
    final queryNorm = query.trim().toLowerCase();
    final proformas = proformasBase.where((proforma) {
      if (queryNorm.isEmpty) {
        return true;
      }
      final clienteNombre = (clientesById[proforma.clienteId] ?? '').toLowerCase();
      return proforma.numero.toLowerCase().contains(queryNorm) || clienteNombre.contains(queryNorm);
    }).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Proformas',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            AppPrimaryButton(
              label: 'Nueva proforma',
              icon: Icons.note_add_rounded,
              onPressed: () => context.go('/proformas/nueva'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Buscar proforma',
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Buscar por número o cliente',
          ),
          onChanged: (value) => ref.read(proformasSearchQueryProvider.notifier).state = value,
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: AppSectionCard(
            title: 'Listado de proformas',
            child: proformasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error al cargar proformas: $error'),
              data: (_) {
                if (proformas.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Text('No hay proformas registradas.'),
                  );
                }

                return AppDataTable(
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(label: Text('N° Proforma')),
                    DataColumn(label: Text('Cliente')),
                    DataColumn(label: Text('Vehículo')),
                    DataColumn(label: Text('Fecha')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: [
                    for (final proforma in proformas)
                      DataRow(
                        cells: [
                          DataCell(Text(proforma.numero)),
                          DataCell(Text(clientesById[proforma.clienteId] ?? '—')),
                          DataCell(Text(vehiculosById[proforma.vehiculoId] ?? '—')),
                          DataCell(Text(_formatDate(proforma.fecha))),
                          DataCell(Text(_formatBs(proforma.totalFinal))),
                          DataCell(
                            AppBadge(
                              label: _estadoLabel(proforma.estado),
                              backgroundColor: _estadoColor(proforma.estado),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Ver detalle',
                                  onPressed: () => context.go('/proformas/${proforma.id}'),
                                  icon: const Icon(Icons.visibility_rounded),
                                ),
                                IconButton(
                                  tooltip: 'Editar',
                                  onPressed: () => context.go('/proformas/${proforma.id}/editar'),
                                  icon: const Icon(Icons.edit_rounded),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  onPressed: () => _confirmDelete(proforma),
                                  icon: const Icon(Icons.delete_outline_rounded),
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

  Future<void> _confirmDelete(Proforma proforma) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ConfirmDeleteDialog(
        title: 'Eliminar proforma',
        message: '¿Deseas eliminar la proforma ${proforma.numero}?',
      ),
    );

    if (confirm != true || !mounted) {
      return;
    }

    try {
      await ref.read(proformasProvider.notifier).eliminarProforma(proforma.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proforma eliminada.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo eliminar la proforma.')));
    }
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _formatBs(double value) => 'Bs. ${value.toStringAsFixed(2)}';

  String _estadoLabel(ProformaEstado estado) {
    switch (estado) {
      case ProformaEstado.borrador:
        return 'Borrador';
      case ProformaEstado.emitida:
        return 'Emitida';
      case ProformaEstado.aceptada:
        return 'Aceptada';
      case ProformaEstado.rechazada:
        return 'Rechazada';
    }
  }

  Color _estadoColor(ProformaEstado estado) {
    switch (estado) {
      case ProformaEstado.borrador:
        return AppColors.warning;
      case ProformaEstado.emitida:
        return AppColors.primary;
      case ProformaEstado.aceptada:
        return AppColors.success;
      case ProformaEstado.rechazada:
        return AppColors.danger;
    }
  }
}
