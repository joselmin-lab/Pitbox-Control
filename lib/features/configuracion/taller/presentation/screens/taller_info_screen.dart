import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../providers/taller_info_provider.dart';

class TallerInfoScreen extends ConsumerStatefulWidget {
  const TallerInfoScreen({super.key});

  @override
  ConsumerState<TallerInfoScreen> createState() => _TallerInfoScreenState();
}

class _TallerInfoScreenState extends ConsumerState<TallerInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();

  bool _initialized = false;
  bool _saving = false;
  bool _uploadingLogo = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tallerInfoAsync = ref.watch(tallerInfoProvider);
    final tallerInfo = tallerInfoAsync.valueOrNull;

    if (tallerInfo != null && !_initialized) {
      _nombreController.text = tallerInfo.nombre;
      _direccionController.text = tallerInfo.direccion ?? '';
      _telefonoController.text = tallerInfo.telefono ?? '';
      _correoController.text = tallerInfo.correo ?? '';
      _initialized = true;
    }

    if (tallerInfoAsync.isLoading && !_initialized) {
      return const Center(child: CircularProgressIndicator());
    }
    if (tallerInfoAsync.hasError && tallerInfo == null) {
      return Center(child: Text('Error al cargar datos del taller: ${tallerInfoAsync.error}'));
    }

    return SingleChildScrollView(
      child: AppSectionCard(
        title: 'Datos del taller',
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
                controller: _direccionController,
                decoration: const InputDecoration(labelText: 'Dirección (opcional)'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(labelText: 'Correo (opcional)'),
                validator: (value) {
                  final correo = value?.trim() ?? '';
                  if (correo.isEmpty) {
                    return null;
                  }
                  final emailRegExp = RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$');
                  if (!emailRegExp.hasMatch(correo)) {
                    return 'Ingresa un correo válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Logo del taller',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              _LogoPreview(logoUrl: tallerInfo?.logoUrl),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: _uploadingLogo ? null : _seleccionarYSubirLogo,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(_uploadingLogo ? 'Subiendo logo...' : 'Cambiar logo'),
                  ),
                  if (_uploadingLogo) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator()),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: _saving ? 'Guardando...' : 'Guardar cambios',
                icon: Icons.save_rounded,
                onPressed: _saving
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        setState(() => _saving = true);
                        try {
                          await ref.read(tallerInfoProvider.notifier).guardar(
                                nombre: _nombreController.text,
                                direccion: _direccionController.text,
                                telefono: _telefonoController.text,
                                correo: _correoController.text,
                              );
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Datos del taller guardados correctamente.')),
                          );
                        } catch (_) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No se pudo guardar la información del taller.')),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _saving = false);
                          }
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _seleccionarYSubirLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
      withData: true,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final extension = file.extension?.toLowerCase();
    const validExtensions = {'png', 'jpg', 'jpeg', 'webp'};
    if (extension == null || !validExtensions.contains(extension)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formato inválido. Solo se permiten PNG, JPG, JPEG o WEBP.')),
      );
      return;
    }
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo leer el archivo seleccionado.')),
      );
      return;
    }

    setState(() => _uploadingLogo = true);
    try {
      await ref.read(tallerInfoProvider.notifier).actualizarLogo(
            bytes,
            file.name,
          );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo actualizado correctamente.')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo subir el logo del taller.')),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingLogo = false);
      }
    }
  }
}

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({required this.logoUrl});

  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoUrl != null && logoUrl!.trim().isNotEmpty;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasLogo
          ? Image.network(
              logoUrl!,
              fit: BoxFit.cover,
              width: 120,
              height: 120,
              errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_rounded, size: 42),
            )
          : const Icon(Icons.business_rounded, size: 42),
    );
  }
}
