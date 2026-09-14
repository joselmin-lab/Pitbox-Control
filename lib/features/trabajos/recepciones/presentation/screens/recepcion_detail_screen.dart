import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_badge.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../clientes/domain/models/cliente.dart';
import '../../../../clientes/presentation/providers/clientes_provider.dart';
import '../../../../configuracion/taller/presentation/providers/taller_info_provider.dart';
import '../../../../vehiculos/domain/models/vehiculo.dart';
import '../../../../vehiculos/presentation/providers/vehiculos_provider.dart';
import '../../domain/models/recepcion_vehiculo.dart';
import '../providers/recepciones_provider.dart';
import '../utils/recepcion_pdf_exporter.dart';
import '../widgets/damage_diagram.dart';

class RecepcionDetailScreen extends ConsumerWidget {
  const RecepcionDetailScreen({required this.recepcionId, super.key});

  final String recepcionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recepcionesAsync = ref.watch(recepcionesProvider);
    final recepcion = ref.watch(recepcionByIdProvider(recepcionId));
    final clientes = ref.watch(clientesProvider).valueOrNull ?? const <Cliente>[];
    final vehiculos = ref.watch(vehiculosProvider).valueOrNull ?? const <Vehiculo>[];
    final tallerInfo = ref.watch(tallerInfoProvider).valueOrNull;

    if (recepcion == null) {
      if (recepcionesAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (recepcionesAsync.hasError) {
        return Center(child: Text('Error al cargar recepción: ${recepcionesAsync.error}'));
      }
      return const Center(child: Text('Recepción no encontrada.'));
    }

    final cliente = _findClienteById(clientes, recepcion.clienteId);
    final vehiculo = _findVehiculoById(vehiculos, recepcion.vehiculoId);

    return SingleChildScrollView(
      child: AppSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppPrimaryButton(
                  label: 'Editar',
                  icon: Icons.edit_rounded,
                  onPressed: () => context.go('/trabajos/recepciones/${recepcion.id}/editar'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await RecepcionPdfExporter.exportar(
                      recepcion: recepcion,
                      cliente: cliente,
                      vehiculo: vehiculo,
                      taller: tallerInfo,
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Exportar PDF'),
                ),
                if (recepcion.estado == RecepcionEstado.abierta)
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await ref.read(recepcionesProvider.notifier).cambiarEstado(
                              recepcion: recepcion,
                              estado: RecepcionEstado.vehiculoEntregado,
                            );
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Recepción marcada como vehículo entregado.')),
                        );
                      } catch (_) {
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No se pudo actualizar el estado de la recepción.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.task_alt_rounded),
                    label: const Text('Marcar entregado'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                'RECEPCIÓN DE VEHÍCULOS',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: SizedBox(
                width: 92,
                height: 92,
                child: ((tallerInfo?.logoUrl ?? '').trim().isNotEmpty)
                  ? Image.network(
                      tallerInfo?.logoUrl ?? '',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.precision_manufacturing_rounded, size: 56),
                    )
                  : const Icon(Icons.precision_manufacturing_rounded, size: 56),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                tallerInfo?.nombre.trim().isNotEmpty == true ? tallerInfo!.nombre.trim() : 'Pitbox Control',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Center(
              child: Text(
                [tallerInfo?.direccion, tallerInfo?.telefono, tallerInfo?.correo]
                    .where((value) => value != null && value.trim().isNotEmpty)
                    .join(' · '),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'N° ${recepcion.numero}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                AppBadge(
                  label: recepcion.estado.label,
                  backgroundColor: recepcion.estado == RecepcionEstado.abierta ? AppColors.warning : AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionBand(title: 'DATOS DEL CLIENTE'),
            _InfoGrid(
              items: [
                _InfoItem('Marca', vehiculo?.marca ?? '—'),
                _InfoItem('Ingreso', _formatDate(recepcion.fechaIngreso)),
                _InfoItem('Modelo', vehiculo?.modelo ?? '—'),
                _InfoItem('Color', vehiculo?.color ?? '—'),
                _InfoItem('Salida estimada', _formatDate(recepcion.fechaSalidaEstimada)),
                _InfoItem('Kilometraje', recepcion.kilometraje ?? '—'),
                _InfoItem('Placas', vehiculo?.placa ?? '—'),
                _InfoItem('Nombre', cliente?.nombreCompleto ?? '—'),
                _InfoItem('Año', vehiculo == null ? '—' : vehiculo.anio.toString()),
                _InfoItem('Teléfono', cliente?.telefono ?? '—'),
                _InfoItem('Ingreso en grúa', recepcion.ingresoEnGrua ? 'Sí' : 'No'),
                _InfoItem('Email', cliente?.email ?? '—'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionBand(title: 'TRABAJO A REALIZAR'),
            _BlockValue(text: recepcion.trabajoARealizar),
            const SizedBox(height: AppSpacing.md),
            _SectionBand(title: 'OBSERVACIONES'),
            _BlockValue(text: recepcion.observaciones),
            const SizedBox(height: AppSpacing.md),
            _SectionBand(title: 'SISTEMAS'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final item in recepcion.checklistSistemas)
                    FilterChip(
                      selected: item.marcado,
                      onSelected: null,
                      avatar: Icon(_iconFor(item.icono), size: 18),
                      label: Text(item.etiqueta),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionBand(title: 'INVENTARIO'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final item in recepcion.inventario)
                        SizedBox(
                          width: 220,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(value: item.marcado, onChanged: null),
                              Expanded(child: Text(item.item)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Nivel de combustible', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Text('E'),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 12,
                            value: recepcion.nivelCombustible.clamp(0.0, 1.0).toDouble(),
                            backgroundColor: Colors.black12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Text('F'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionBand(title: 'DAÑOS PREEXISTENTES DEL VEHÍCULO'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (final vista in RecepcionVistaVehiculo.values)
                        SizedBox(
                          width: 260,
                          child: DamageDiagram(
                            title: vista.label,
                            vista: vista,
                            puntos: recepcion.danosPreexistentes
                                .where((item) => item.vista == vista)
                                .toList(growable: false),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Fotografías adjuntas', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  if (recepcion.fotografias.isEmpty)
                    const Text('No hay fotografías adjuntas.')
                  else
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final foto in recepcion.fotografias)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              foto,
                              width: 120,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 120,
                                height: 90,
                                color: Colors.black12,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.md,
              children: [
                SizedBox(
                  width: 320,
                  child: _SignaturePreview(
                    title: 'FIRMA DEL PRESTADOR DEL SERVICIO',
                    imageUrl: recepcion.firmaPrestadorUrl,
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: _SignaturePreview(
                    title: 'FIRMA DEL CLIENTE',
                    imageUrl: recepcion.firmaClienteUrl,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Cliente? _findClienteById(List<Cliente> clientes, String id) {
    for (final cliente in clientes) {
      if (cliente.id == id) {
        return cliente;
      }
    }
    return null;
  }

  Vehiculo? _findVehiculoById(List<Vehiculo> vehiculos, String id) {
    for (final vehiculo in vehiculos) {
      if (vehiculo.id == id) {
        return vehiculo;
      }
    }
    return null;
  }

  static String _formatDate(DateTime? value) {
    if (value == null) {
      return '—';
    }
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  static IconData _iconFor(String icono) {
    switch (icono) {
      case 'key':
        return Icons.key_rounded;
      case 'engine':
        return Icons.settings_rounded;
      case 'abs':
        return Icons.car_crash_rounded;
      case 'oil_battery':
        return Icons.battery_charging_full_rounded;
      case 'tow':
        return Icons.local_shipping_rounded;
      case 'parking':
        return Icons.local_parking_rounded;
      case 'lights':
        return Icons.lightbulb_rounded;
      case 'wiper':
        return Icons.cleaning_services_rounded;
      case 'temperature':
        return Icons.thermostat_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }
}

class _SectionBand extends StatelessWidget {
  const _SectionBand({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _BlockValue extends StatelessWidget {
  const _BlockValue({required this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Text((text == null || text!.trim().isEmpty) ? '—' : text!.trim()),
    );
  }
}

class _InfoItem {
  const _InfoItem(this.label, this.value);

  final String label;
  final String value;
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        children: [
          for (final item in items)
            SizedBox(
              width: 260,
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: '${item.label}: ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: item.value),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SignaturePreview extends StatelessWidget {
  const _SignaturePreview({
    required this.title,
    required this.imageUrl,
  });

  final String title;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              left: BorderSide(color: Theme.of(context).dividerColor),
              top: BorderSide(color: Theme.of(context).dividerColor),
              right: BorderSide(color: Theme.of(context).dividerColor),
              bottom: const BorderSide(color: Colors.black54),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: hasImage
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                )
              : const Text('Sin firma'),
        ),
      ],
    );
  }
}
