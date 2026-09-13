import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../domain/models/paquete_servicio.dart';
import '../../domain/models/servicio.dart';
import '../providers/paquetes_servicios_provider.dart';
import '../providers/servicios_provider.dart';
import '../widgets/servicios_selector.dart';

class PaqueteServicioFormScreen extends ConsumerStatefulWidget {
  const PaqueteServicioFormScreen({this.paqueteId, super.key});

  final String? paqueteId;

  @override
  ConsumerState<PaqueteServicioFormScreen> createState() => _PaqueteServicioFormScreenState();
}

class _PaqueteServicioFormScreenState extends ConsumerState<PaqueteServicioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioManualController = TextEditingController();

  bool _activo = true;
  bool _initialized = false;
  bool _saving = false;
  Map<String, int> _serviciosSeleccionados = <String, int>{};

  @override
  void didUpdateWidget(covariant PaqueteServicioFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paqueteId != widget.paqueteId) {
      _initialized = false;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioManualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paquetesAsync = ref.watch(paquetesServiciosProvider);
    final serviciosAsync = ref.watch(serviciosProvider);
    final servicios = serviciosAsync.valueOrNull ?? const <Servicio>[];

    final paqueteId = widget.paqueteId;
    final paquete = paqueteId == null ? null : ref.watch(paqueteServicioByIdProvider(paqueteId));

    if (paqueteId != null && paquete == null) {
      if (paquetesAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (paquetesAsync.hasError) {
        return Center(child: Text('Error al cargar paquete: ${paquetesAsync.error}'));
      }
      return const Center(child: Text('Paquete no encontrado.'));
    }

    if (serviciosAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (serviciosAsync.hasError) {
      return Center(child: Text('Error al cargar servicios: ${serviciosAsync.error}'));
    }

    if (!_initialized) {
      _nombreController.text = paquete?.nombre ?? '';
      _descripcionController.text = paquete?.descripcion ?? '';
      _precioManualController.text = paquete?.precioManual?.toStringAsFixed(2) ?? '';
      _activo = paquete?.activo ?? true;
      _serviciosSeleccionados = {
        for (final item in paquete?.items ?? const <PaqueteServicioItem>[]) item.servicioId: item.cantidad,
      };
      _initialized = true;
    }

    final isEdit = paquete != null;
    final precioSeleccionado = _precioTotalSeleccionado(servicios);
    final precioManual = _parsePrecioManual();
    final precioFinal = precioManual ?? precioSeleccionado;

    return SingleChildScrollView(
      child: AppSectionCard(
        title: isEdit ? 'Editar paquete' : 'Nuevo paquete',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _precioManualController,
                decoration: const InputDecoration(
                  labelText: 'Precio manual (Bs., opcional)',
                  helperText: 'Si lo llenas, este precio reemplaza la suma automática.',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }
                  final parsed = double.tryParse(value.replaceAll(',', '.').trim());
                  if (parsed == null || parsed <= 0) {
                    return 'El precio manual debe ser numérico y mayor a 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Paquete activo'),
                value: _activo,
                onChanged: (value) => setState(() => _activo = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Precio total actual: ${_formatBs(precioFinal)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Selecciona servicios incluidos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              ServiciosSelector(
                servicios: servicios,
                seleccion: _serviciosSeleccionados,
                onChanged: (next) => setState(() => _serviciosSeleccionados = next),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppPrimaryButton(
                    label: _saving ? 'Guardando...' : 'Guardar',
                    icon: Icons.save_rounded,
                    onPressed: _saving
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }
                            if (_serviciosSeleccionados.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Debes seleccionar al menos un servicio para el paquete.'),
                                ),
                              );
                              return;
                            }
                            setState(() => _saving = true);
                            try {
                              final precioManual = _parsePrecioManual();
                              if (isEdit) {
                                await ref.read(paquetesServiciosProvider.notifier).editarPaquete(
                                      id: paquete.id,
                                      fechaCreacion: paquete.fechaCreacion,
                                      nombre: _nombreController.text.trim(),
                                      descripcion: _descripcionController.text,
                                      precioManual: precioManual,
                                      activo: _activo,
                                      servicioCantidad: _serviciosSeleccionados,
                                    );
                              } else {
                                await ref.read(paquetesServiciosProvider.notifier).create(
                                      nombre: _nombreController.text.trim(),
                                      descripcion: _descripcionController.text,
                                      precioManual: precioManual,
                                      activo: _activo,
                                      servicioCantidad: _serviciosSeleccionados,
                                    );
                              }
                              if (context.mounted) {
                                context.go('/configuracion/paquetes');
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No se pudo guardar el paquete. Intenta nuevamente.'),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _saving = false);
                              }
                            }
                          },
                  ),
                  OutlinedButton(
                    onPressed: _saving ? null : () => context.pop(),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _precioTotalSeleccionado(List<Servicio> servicios) {
    final byId = {for (final servicio in servicios) servicio.id: servicio};
    var total = 0.0;
    for (final entry in _serviciosSeleccionados.entries) {
      final servicio = byId[entry.key];
      if (servicio == null) {
        continue;
      }
      total += servicio.precio * entry.value;
    }
    return total;
  }

  double? _parsePrecioManual() {
    final text = _precioManualController.text.trim();
    if (text.isEmpty) {
      return null;
    }
    return double.tryParse(text.replaceAll(',', '.'));
  }

  String _formatBs(double value) {
    return 'Bs. ${value.toStringAsFixed(2)}';
  }
}
