import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../clientes/presentation/providers/clientes_provider.dart';
import '../providers/vehiculos_provider.dart';

class VehiculoFormScreen extends ConsumerStatefulWidget {
  const VehiculoFormScreen({
    this.vehiculoId,
    this.clienteId,
    super.key,
  });

  final String? vehiculoId;
  final String? clienteId;

  @override
  ConsumerState<VehiculoFormScreen> createState() => _VehiculoFormScreenState();
}

class _VehiculoFormScreenState extends ConsumerState<VehiculoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anioController = TextEditingController();
  final _colorController = TextEditingController();
  final _kilometrajeController = TextEditingController();

  String? _selectedClienteId;
  bool _initialized = false;
  bool _saving = false;

  @override
  void didUpdateWidget(covariant VehiculoFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehiculoId != widget.vehiculoId || oldWidget.clienteId != widget.clienteId) {
      _initialized = false;
    }
  }

  @override
  void dispose() {
    _placaController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    _colorController.dispose();
    _kilometrajeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehiculosAsync = ref.watch(vehiculosProvider);
    final vehiculoId = widget.vehiculoId;
    final vehiculo = vehiculoId == null ? null : ref.watch(vehiculoByIdProvider(vehiculoId));
    final clientesAsync = ref.watch(clientesProvider);
    final clientes = clientesAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const [],
    );

    if (clientesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (clientesAsync.hasError) {
      return Center(child: Text('Error al cargar clientes: ${clientesAsync.error}'));
    }
    if (clientes.isEmpty) {
      return AppSectionCard(
        title: 'No hay clientes disponibles',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Primero debes registrar un cliente para poder asociar un vehículo.'),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => context.go('/clientes/nuevo'),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Crear cliente'),
            ),
          ],
        ),
      );
    }

    if (vehiculoId != null && vehiculo == null) {
      if (vehiculosAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (vehiculosAsync.hasError) {
        return Center(child: Text('Error al cargar vehículo: ${vehiculosAsync.error}'));
      }
      return const Center(child: Text('Vehículo no encontrado.'));
    }

    if (!_initialized) {
      _placaController.text = vehiculo?.placa ?? '';
      _marcaController.text = vehiculo?.marca ?? '';
      _modeloController.text = vehiculo?.modelo ?? '';
      _anioController.text = vehiculo?.anio.toString() ?? '';
      _colorController.text = vehiculo?.color ?? '';
      _kilometrajeController.text = vehiculo?.kilometraje?.toString() ?? '';
      _selectedClienteId = vehiculo?.clienteId ?? widget.clienteId;
      _initialized = true;
    }

    final isEdit = vehiculo != null;
    final clienteIds = clientes.map((item) => item.id).toSet();
    final selectedClienteId = clienteIds.contains(_selectedClienteId) ? _selectedClienteId : null;

    return SingleChildScrollView(
      child: AppSectionCard(
        title: isEdit ? 'Editar vehículo' : 'Nuevo vehículo',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: selectedClienteId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Cliente asociado *'),
                items: [
                  for (final cliente in clientes)
                    DropdownMenuItem(value: cliente.id, child: Text(cliente.nombreCompleto)),
                ],
                onChanged: (value) => setState(() => _selectedClienteId = value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Debes seleccionar un cliente.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _placaController,
                decoration: const InputDecoration(labelText: 'Placa *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La placa es obligatoria.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(labelText: 'Marca *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La marca es obligatoria.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _modeloController,
                decoration: const InputDecoration(labelText: 'Modelo *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El modelo es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _anioController,
                decoration: const InputDecoration(labelText: 'Año *'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El año es obligatorio.';
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null) {
                    return 'El año debe ser numérico.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Color (opcional)'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _kilometrajeController,
                decoration: const InputDecoration(labelText: 'Kilometraje (opcional)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'El kilometraje debe ser numérico.';
                  }
                  return null;
                },
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
                            setState(() => _saving = true);
                            final parsedAnio = int.parse(_anioController.text.trim());
                            final parsedKilometraje = _kilometrajeController.text.trim().isEmpty
                                ? null
                                : int.parse(_kilometrajeController.text.trim());
                            try {
                              if (isEdit) {
                                await ref.read(vehiculosProvider.notifier).editarVehiculo(
                                      id: vehiculo.id,
                                      fechaRegistro: vehiculo.fechaRegistro,
                                      clienteId: _selectedClienteId!,
                                      placa: _placaController.text.trim().toUpperCase(),
                                      marca: _marcaController.text.trim(),
                                      modelo: _modeloController.text.trim(),
                                      anio: parsedAnio,
                                      color: _colorController.text,
                                      kilometraje: parsedKilometraje,
                                    );
                                if (mounted) {
                                  context.go('/vehiculos/${vehiculo.id}');
                                }
                              } else {
                                await ref.read(vehiculosProvider.notifier).create(
                                      clienteId: _selectedClienteId!,
                                      placa: _placaController.text.trim().toUpperCase(),
                                      marca: _marcaController.text.trim(),
                                      modelo: _modeloController.text.trim(),
                                      anio: parsedAnio,
                                      color: _colorController.text,
                                      kilometraje: parsedKilometraje,
                                    );
                                if (mounted) {
                                  context.go('/vehiculos');
                                }
                              }
                            } catch (_) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No se pudo guardar el vehículo. Intenta nuevamente.')),
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
}
