import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../clientes/domain/models/cliente.dart';
import '../../../clientes/presentation/providers/clientes_provider.dart';
import '../../../configuracion/taller/presentation/providers/taller_info_provider.dart';
import '../../../configuracion/impuestos/presentation/providers/impuestos_provider.dart';
import '../../../vehiculos/domain/models/vehiculo.dart';
import '../../../vehiculos/presentation/providers/vehiculos_provider.dart';
import '../../domain/utils/numero_a_literal_es.dart';
import '../providers/proformas_provider.dart';
import '../utils/proforma_pdf_exporter.dart';

class ProformaDetailScreen extends ConsumerWidget {
  const ProformaDetailScreen({required this.proformaId, super.key});

  final String proformaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proformasAsync = ref.watch(proformasProvider);
    final proforma = ref.watch(proformaByIdProvider(proformaId));
    final clientes = ref.watch(clientesProvider).valueOrNull ?? const <Cliente>[];
    final vehiculos = ref.watch(vehiculosProvider).valueOrNull ?? const <Vehiculo>[];
    final tallerInfo = ref.watch(tallerInfoProvider).valueOrNull;
    final impuestos = ref.watch(impuestosProvider).valueOrNull;

    if (proforma == null) {
      if (proformasAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (proformasAsync.hasError) {
        return Center(child: Text('Error al cargar proforma: ${proformasAsync.error}'));
      }
      return const Center(child: Text('Proforma no encontrada.'));
    }

    final cliente = _findClienteById(clientes, proforma.clienteId);
    final vehiculo = _findVehiculoById(vehiculos, proforma.vehiculoId);

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
                  onPressed: () => context.go('/proformas/${proforma.id}/editar'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ProformaPdfExporter.exportar(
                      proforma: proforma,
                      cliente: cliente,
                      vehiculo: vehiculo,
                      taller: tallerInfo,
                      porcentajeIva: impuestos?.porcentajeIva ?? 13,
                      porcentajeIt: impuestos?.porcentajeIt ?? 3,
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Exportar PDF'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                '★ PROFORMA ★',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: SizedBox(
                width: 90,
                height: 90,
                child: ((tallerInfo?.logoUrl ?? '').trim().isNotEmpty)
                    ? Image.network(tallerInfo?.logoUrl ?? '', fit: BoxFit.contain)
                    : const Icon(Icons.business_rounded, size: 56),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CLIENTE', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.primary)),
                      Text(cliente?.nombreCompleto ?? '—'),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        vehiculo == null
                            ? 'Vehículo: —'
                            : 'Vehículo: ${vehiculo.placa} · ${vehiculo.marca} ${vehiculo.modelo} (${vehiculo.anio})',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('N° PROFORMA', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.primary)),
                    Text(proforma.numero),
                    const SizedBox(height: AppSpacing.xs),
                    AppBadge(
                      label: proforma.facturado ? 'Facturado' : 'No facturado',
                      backgroundColor: proforma.facturado ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('FECHA', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.primary)),
                    Text(_formatDate(proforma.fecha)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Table(
              border: TableBorder.all(color: Theme.of(context).dividerColor),
              columnWidths: const {
                0: FixedColumnWidth(70),
                1: FlexColumnWidth(),
                2: FixedColumnWidth(140),
                3: FixedColumnWidth(120),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: AppColors.primary),
                  children: const [
                    _HeaderCell('Cant.'),
                    _HeaderCell('Descripción'),
                    _HeaderCell('Precio unitario'),
                    _HeaderCell('Total'),
                  ],
                ),
                ...proforma.items.map(
                  (item) => TableRow(
                    children: [
                      _BodyCell(item.cantidad.toStringAsFixed(2)),
                      _BodyCell(item.descripcion),
                      _BodyCell(_formatBs(item.precioUnitario)),
                      _BodyCell(_formatBs(item.total)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Subtotal: ${_formatBs(proforma.subtotalFinal)}'),
            ),
            if (!proforma.facturado)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Descuento por no facturar (IVA ${(impuestos?.porcentajeIva ?? 13).toStringAsFixed(2)}% + IT ${(impuestos?.porcentajeIt ?? 3).toStringAsFixed(2)}%): -${_formatBs(proforma.descuentoNoFacturadoFinal)}',
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                montoEnLiteralBolivianos(proforma.totalFinal),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    child: const Text('TOTAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Text(_formatBs(proforma.totalFinal), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _ConditionLine(label: 'CONDICIONES Y FORMA DE PAGO:', value: proforma.condicionesPago),
            _ConditionLine(label: 'VALIDEZ DE LA PROFORMA:', value: proforma.validez),
            _ConditionLine(label: 'TIEMPO DE ENTREGA:', value: proforma.tiempoEntrega),
            _ConditionLine(label: 'TIEMPO DE GARANTÍA:', value: proforma.tiempoGarantia),
            _ConditionLine(label: 'FORMA DE PAGO:', value: proforma.formaPago),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  static String _formatBs(double value) => 'Bs. ${value.toStringAsFixed(2)}';

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
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Text(text),
    );
  }
}

class _ConditionLine extends StatelessWidget {
  const _ConditionLine({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
            TextSpan(text: (value == null || value.trim().isEmpty) ? '—' : value.trim()),
          ],
        ),
      ),
    );
  }
}
