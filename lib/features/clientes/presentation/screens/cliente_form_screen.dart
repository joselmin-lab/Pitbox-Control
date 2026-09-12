import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../providers/clientes_provider.dart';

class ClienteFormScreen extends ConsumerStatefulWidget {
  const ClienteFormScreen({this.clienteId, super.key});

  final String? clienteId;

  @override
  ConsumerState<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends ConsumerState<ClienteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();

  bool _initialized = false;
  bool _saving = false;

  @override
  void didUpdateWidget(covariant ClienteFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clienteId != widget.clienteId) {
      _initialized = false;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientesAsync = ref.watch(clientesProvider);
    final clienteId = widget.clienteId;
    final cliente = clienteId == null ? null : ref.watch(clienteByIdProvider(clienteId));

    if (clienteId != null && cliente == null) {
      if (clientesAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (clientesAsync.hasError) {
        return Center(child: Text('Error al cargar cliente: ${clientesAsync.error}'));
      }
      return const Center(child: Text('Cliente no encontrado.'));
    }

    if (!_initialized) {
      _nombreController.text = cliente?.nombre ?? '';
      _apellidoController.text = cliente?.apellido ?? '';
      _telefonoController.text = cliente?.telefono ?? '';
      _emailController.text = cliente?.email ?? '';
      _direccionController.text = cliente?.direccion ?? '';
      _initialized = true;
    }

    final isEdit = cliente != null;

    return SingleChildScrollView(
      child: AppSectionCard(
        title: isEdit ? 'Editar cliente' : 'Nuevo cliente',
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
                controller: _apellidoController,
                decoration: const InputDecoration(labelText: 'Apellido'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono *'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El teléfono es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email (opcional)'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(labelText: 'Dirección (opcional)'),
                maxLines: 2,
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
                            try {
                              if (isEdit) {
                                await ref.read(clientesProvider.notifier).editarCliente(
                                      id: cliente.id,
                                      fechaRegistro: cliente.fechaRegistro,
                                      nombre: _nombreController.text.trim(),
                                      apellido: _apellidoController.text.trim(),
                                      telefono: _telefonoController.text.trim(),
                                      email: _emailController.text,
                                      direccion: _direccionController.text,
                                    );
                                if (mounted) {
                                  context.go('/clientes/${cliente.id}');
                                }
                              } else {
                                await ref.read(clientesProvider.notifier).create(
                                      nombre: _nombreController.text.trim(),
                                      apellido: _apellidoController.text.trim(),
                                      telefono: _telefonoController.text.trim(),
                                      email: _emailController.text,
                                      direccion: _direccionController.text,
                                    );
                                if (mounted) {
                                  context.go('/clientes');
                                }
                              }
                            } catch (_) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No se pudo guardar el cliente. Intenta nuevamente.')),
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
