import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../vehiculos/presentation/providers/vehiculos_provider.dart';
import '../providers/clientes_provider.dart';

class ClienteDetailScreen extends ConsumerWidget {
  const ClienteDetailScreen({required this.clienteId, super.key});

  final String clienteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientesAsync = ref.watch(clientesProvider);
    final cliente = ref.watch(clienteByIdProvider(clienteId));

    if (cliente == null) {
      if (clientesAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return const Center(child: Text('Cliente no encontrado.'));
    }

    final vehiculos = ref.watch(vehiculosByClienteIdProvider(clienteId));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cliente.nombreCompleto,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              AppPrimaryButton(
                label: 'Agregar vehículo',
                icon: Icons.directions_car_filled_rounded,
                onPressed: () => context.go('/vehiculos/nuevo?clienteId=${cliente.id}'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppSectionCard(
            title: 'Datos del cliente',
            trailing: AppBadge(label: 'Registro ${_formatDate(cliente.fechaRegistro)}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'Teléfono', value: cliente.telefono),
                _InfoRow(label: 'Email', value: cliente.email ?? 'No registrado'),
                _InfoRow(label: 'Dirección', value: cliente.direccion ?? 'No registrada'),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.go('/clientes/${cliente.id}/editar'),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Editar'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final warning = vehiculos.isNotEmpty
                            ? 'Este cliente tiene ${vehiculos.length} vehículo(s) asociado(s). Si lo eliminas, también se eliminarán esos vehículos.'
                            : '¿Seguro que deseas eliminar este cliente?';
                        final accepted = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return ConfirmDeleteDialog(
                              title: 'Eliminar cliente',
                              message: warning,
                            );
                          },
                        );
                        if (accepted != true) {
                          return;
                        }
                        await ref.read(clientesProvider.notifier).delete(cliente.id);
                        if (context.mounted) {
                          context.go('/clientes');
                        }
                      },
                      icon: const Icon(Icons.delete_rounded),
                      label: const Text('Eliminar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionCard(
            title: 'Vehículos asociados',
            child: vehiculos.isEmpty
                ? const Text('Este cliente aún no tiene vehículos registrados.')
                : AppDataTable(
                    columns: const [
                      DataColumn(label: Text('Placa')),
                      DataColumn(label: Text('Marca')),
                      DataColumn(label: Text('Modelo')),
                      DataColumn(label: Text('Año')),
                    ],
                    rows: [
                      for (final vehiculo in vehiculos)
                        DataRow(
                          onSelectChanged: (selected) {
                            if (selected == true) {
                              context.go('/vehiculos/${vehiculo.id}');
                            }
                          },
                          cells: [
                            DataCell(Text(vehiculo.placa)),
                            DataCell(Text(vehiculo.marca)),
                            DataCell(Text(vehiculo.modelo)),
                            DataCell(Text('${vehiculo.anio}')),
                          ],
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
