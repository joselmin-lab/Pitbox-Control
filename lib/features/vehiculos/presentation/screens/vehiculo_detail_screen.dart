import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/confirm_delete_dialog.dart';
import '../../../clientes/presentation/providers/clientes_provider.dart';
import '../providers/vehiculos_provider.dart';

class VehiculoDetailScreen extends ConsumerWidget {
  const VehiculoDetailScreen({required this.vehiculoId, super.key});

  final String vehiculoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiculosAsync = ref.watch(vehiculosProvider);
    final vehiculo = ref.watch(vehiculoByIdProvider(vehiculoId));

    if (vehiculo == null) {
      if (vehiculosAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (vehiculosAsync.hasError) {
        return Center(child: Text('Error al cargar vehículo: ${vehiculosAsync.error}'));
      }
      return const Center(child: Text('Vehículo no encontrado.'));
    }

    final clientesAsync = ref.watch(clientesProvider);
    final cliente = ref.watch(clienteByIdProvider(vehiculo.clienteId));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  vehiculo.placa,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              AppBadge(label: '${vehiculo.marca} ${vehiculo.modelo}'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppSectionCard(
            title: 'Datos del vehículo',
            trailing: AppBadge(label: 'Registro ${_formatDate(vehiculo.fechaRegistro)}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: 'Marca', value: vehiculo.marca),
                _InfoRow(label: 'Modelo', value: vehiculo.modelo),
                _InfoRow(label: 'Año', value: '${vehiculo.anio}'),
                _InfoRow(label: 'Color', value: vehiculo.color ?? 'No registrado'),
                _InfoRow(
                  label: 'Kilometraje',
                  value: vehiculo.kilometraje == null ? 'No registrado' : '${vehiculo.kilometraje} km',
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.go('/vehiculos/${vehiculo.id}/editar'),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Editar'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final accepted = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return const ConfirmDeleteDialog(
                              title: 'Eliminar vehículo',
                              message: '¿Seguro que deseas eliminar este vehículo? Esta acción no se puede deshacer.',
                            );
                          },
                        );
                        if (accepted != true) {
                          return;
                        }
                        try {
                          await ref.read(vehiculosProvider.notifier).delete(vehiculo.id);
                          if (context.mounted) {
                            context.go('/vehiculos');
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No se pudo eliminar el vehículo. Intenta nuevamente.')),
                            );
                          }
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
            title: 'Cliente propietario',
            child: clientesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (error, _) => Text('Error al cargar cliente: $error'),
              data: (_) {
                if (cliente == null) {
                  return const Text('No se encontró el cliente asociado.');
                }
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cliente.nombreCompleto,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text('Teléfono: ${cliente.telefono}'),
                          Text('Email: ${cliente.email ?? 'No registrado'}'),
                        ],
                      ),
                    ),
                    AppPrimaryButton(
                      label: 'Ver cliente',
                      onPressed: () => context.go('/clientes/${cliente.id}'),
                    ),
                  ],
                );
              },
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
