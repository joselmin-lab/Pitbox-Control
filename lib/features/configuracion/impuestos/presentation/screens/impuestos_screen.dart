import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../domain/utils/impuestos_validator.dart';
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
  DateTime? _lastSyncedAt;
  bool _isDirty = false;
  bool _isSyncingControllers = false;

  @override
  void initState() {
    super.initState();
    _ivaController.addListener(_markDirtyOnUserEdit);
    _itController.addListener(_markDirtyOnUserEdit);
  }

  @override
  void dispose() {
    _ivaController.removeListener(_markDirtyOnUserEdit);
    _itController.removeListener(_markDirtyOnUserEdit);
    _ivaController.dispose();
    _itController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final impuestosAsync = ref.watch(impuestosProvider);
    final impuestos = impuestosAsync.valueOrNull;

    final canResync =
        impuestos != null && (!_initialized || (!_isDirty && _lastSyncedAt != impuestos.fechaActualizacion));
    if (canResync) {
      _isSyncingControllers = true;
      _ivaController.text = impuestos.porcentajeIva.toStringAsFixed(2);
      _itController.text = impuestos.porcentajeIt.toStringAsFixed(2);
      _lastSyncedAt = impuestos.fechaActualizacion;
      _initialized = true;
      _isDirty = false;
      _isSyncingControllers = false;
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
                validator: validarPorcentajeImpuesto,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _itController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'IT (%)'),
                validator: validarPorcentajeImpuesto,
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

    final iva = parsePorcentajeImpuesto(_ivaController.text)!;
    final it = parsePorcentajeImpuesto(_itController.text)!;
    final errorSuma = validarSumaImpuestos(porcentajeIva: iva, porcentajeIt: it);
    if (errorSuma != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorSuma)));
      return;
    }

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
      _isDirty = false;
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

  void _markDirtyOnUserEdit() {
    if (_isSyncingControllers || _isDirty || !mounted) {
      return;
    }
    setState(() => _isDirty = true);
  }

}
