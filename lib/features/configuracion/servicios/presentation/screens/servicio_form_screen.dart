import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../providers/servicios_provider.dart';

class ServicioFormScreen extends ConsumerStatefulWidget {
  const ServicioFormScreen({this.servicioId, super.key});

  final String? servicioId;

  @override
  ConsumerState<ServicioFormScreen> createState() => _ServicioFormScreenState();
}

class _ServicioFormScreenState extends ConsumerState<ServicioFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _categoriaController = TextEditingController();

  bool _activo = true;
  bool _initialized = false;
  bool _saving = false;

  @override
  void didUpdateWidget(covariant ServicioFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.servicioId != widget.servicioId) {
      _initialized = false;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serviciosAsync = ref.watch(serviciosProvider);
    final servicioId = widget.servicioId;
    final servicio = servicioId == null ? null : ref.watch(servicioByIdProvider(servicioId));

    if (servicioId != null && servicio == null) {
      if (serviciosAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (serviciosAsync.hasError) {
        return Center(child: Text('Error al cargar servicio: ${serviciosAsync.error}'));
      }
      return const Center(child: Text('Servicio no encontrado.'));
    }

    if (!_initialized) {
      _nombreController.text = servicio?.nombre ?? '';
      _descripcionController.text = servicio?.descripcion ?? '';
      _precioController.text = servicio == null ? '' : servicio.precio.toStringAsFixed(2);
      _categoriaController.text = servicio?.categoria ?? '';
      _activo = servicio?.activo ?? true;
      _initialized = true;
    }

    final isEdit = servicio != null;

    return SingleChildScrollView(
      child: AppSectionCard(
        title: isEdit ? 'Editar servicio' : 'Nuevo servicio',
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
                controller: _precioController,
                decoration: const InputDecoration(labelText: 'Precio (Bs.) *'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El precio es obligatorio.';
                  }
                  final precio = double.tryParse(value.replaceAll(',', '.').trim());
                  if (precio == null || precio <= 0) {
                    return 'Ingresa un precio numérico mayor a 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _categoriaController,
                decoration: const InputDecoration(labelText: 'Categoría (opcional)'),
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Servicio activo'),
                value: _activo,
                onChanged: (value) => setState(() => _activo = value),
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
                            final precio = double.parse(_precioController.text.replaceAll(',', '.').trim());
                            try {
                              if (isEdit) {
                                await ref.read(serviciosProvider.notifier).editarServicio(
                                      id: servicio.id,
                                      fechaCreacion: servicio.fechaCreacion,
                                      nombre: _nombreController.text.trim(),
                                      descripcion: _descripcionController.text,
                                      precio: precio,
                                      categoria: _categoriaController.text,
                                      activo: _activo,
                                    );
                              } else {
                                await ref.read(serviciosProvider.notifier).create(
                                      nombre: _nombreController.text.trim(),
                                      descripcion: _descripcionController.text,
                                      precio: precio,
                                      categoria: _categoriaController.text,
                                      activo: _activo,
                                    );
                              }
                              if (context.mounted) {
                                context.go('/configuracion/servicios');
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No se pudo guardar el servicio. Intenta nuevamente.'),
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
}
