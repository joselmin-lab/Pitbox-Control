import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../providers/impuestos_provider.dart';

class ImpuestosScreen extends ConsumerStatefulWidget {
  const ImpuestosScreen({super.key});

  @override
  ConsumerState<ImpuestosScreen> createState() => _ImpuestosScreenState();
}

class _ImpuestosScreenState extends ConsumerState<ImpuestosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ivaController = TextEditingController();
  final _itController = TextEditingController();

  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _ivaController.dispose();
    _itController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final impuestosAsync = ref.watch(impuestosProvider);
    final impuestos = impuestosAsync.valueOrNull;

    if (!_initialized && impuestos != null) {
      _ivaController.text = impuestos.porcentajeIva.toStringAsFixed(2);
      _itController.text = impuestos.porcentajeIt.toStringAsFixed(2);
      _initialized = true;
    }

    if (impuestosAsync.isLoading && impuestos == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (impuestosAsync.hasError && impuestos == null) {
      return Center(child: Text('Error al cargar impuestos: ${impuestosAsync.error}'));
    }

    return SingleChildScrollView(
      child: AppSectionCard(
        title: 'Impuestos (IVA e IT)',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _ivaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'IVA (%)'),
                validator: _validatePercentage,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _itController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'IT (%)'),
                validator: _validatePercentage,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: _saving ? 'Guardando...' : 'Guardar cambios',
                icon: Icons.save_rounded,
                onPressed: _saving ? null : _guardar,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final iva = double.parse(_ivaController.text.replaceAll(',', '.').trim());
    final it = double.parse(_itController.text.replaceAll(',', '.').trim());

    setState(() => _saving = true);
    try {
      await ref.read(impuestosProvider.notifier).guardar(
            porcentajeIva: iva,
            porcentajeIt: it,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impuestos guardados correctamente.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la configuración de impuestos.')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _validatePercentage(String? value) {
    final parsed = double.tryParse((value ?? '').replaceAll(',', '.').trim());
    if (parsed == null) {
      return 'Ingresa un valor numérico válido.';
    }
    if (parsed < 0 || parsed > 100) {
      return 'El valor debe estar entre 0 y 100.';
    }
    return null;
  }
}
