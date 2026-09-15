import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../clientes/domain/models/cliente.dart';
import '../../../../clientes/presentation/providers/clientes_provider.dart';
import '../../../../vehiculos/domain/models/vehiculo.dart';
import '../../../../vehiculos/presentation/providers/vehiculos_provider.dart';
import '../../../../configuracion/taller/domain/utils/logo_image_validator.dart';
import '../../domain/models/recepcion_vehiculo.dart';
import '../providers/recepciones_provider.dart';
import '../widgets/damage_diagram.dart';
import '../widgets/signature_pad.dart';

class RecepcionFormScreen extends ConsumerStatefulWidget {
  const RecepcionFormScreen({this.recepcionId, super.key});

  final String? recepcionId;

  @override
  ConsumerState<RecepcionFormScreen> createState() => _RecepcionFormScreenState();
}

class _RecepcionFormScreenState extends ConsumerState<RecepcionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clienteController = TextEditingController();
  final _clienteFocusNode = FocusNode();
  final _kilometrajeController = TextEditingController();
  final _trabajoController = TextEditingController();
  final _observacionesController = TextEditingController();
  bool _saving = false;
  String? _initializedFor;
  String? _lastVehicleKilometrajeSuggestion;

  @override
  void dispose() {
    _clienteController.dispose();
    _clienteFocusNode.dispose();
    _kilometrajeController.dispose();
    _trabajoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recepcionesAsync = ref.watch(recepcionesProvider);
    final recepcion = widget.recepcionId == null ? null : ref.watch(recepcionByIdProvider(widget.recepcionId!));
    final clientesAsync = ref.watch(clientesProvider);
    final vehiculosAsync = ref.watch(vehiculosProvider);

    if (clientesAsync.isLoading || vehiculosAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (clientesAsync.hasError) {
      return Center(child: Text('Error al cargar clientes: ${clientesAsync.error}'));
    }
    if (vehiculosAsync.hasError) {
      return Center(child: Text('Error al cargar vehículos: ${vehiculosAsync.error}'));
    }
    if (widget.recepcionId != null && recepcion == null) {
      if (recepcionesAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (recepcionesAsync.hasError) {
        return Center(child: Text('Error al cargar recepción: ${recepcionesAsync.error}'));
      }
      return const Center(child: Text('Recepción no encontrada.'));
    }

    final clientes = clientesAsync.valueOrNull ?? const <Cliente>[];
    final vehiculos = vehiculosAsync.valueOrNull ?? const <Vehiculo>[];
    final providerDraft = ref.watch(recepcionFormProvider);
    final seedKey = widget.recepcionId == null
        ? 'nueva'
        : '${widget.recepcionId}:${recepcion?.fechaCreacion.toIso8601String() ?? 'loading'}';
    final draft = _ensureInitialized(seedKey, recepcion, clientes, providerDraft);

    final selectedCliente = _findClienteById(clientes, draft.clienteId);
    if (selectedCliente != null &&
        !_clienteFocusNode.hasFocus &&
        _clienteController.text.trim().toLowerCase() != selectedCliente.nombreCompleto.trim().toLowerCase()) {
      _setClienteFieldText(selectedCliente.nombreCompleto);
    }

    final vehiculosDelCliente = draft.clienteId == null
        ? const <Vehiculo>[]
        : vehiculos.where((vehiculo) => vehiculo.clienteId == draft.clienteId).toList(growable: false);
    final selectedVehiculo = _findVehiculoById(vehiculos, draft.vehiculoId);

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionBand(title: 'DATOS DEL CLIENTE'),
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
                        Text(
                          'N° Recepción: ${draft.numero.isEmpty ? 'Se asignará al guardar' : draft.numero}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return RawAutocomplete<Cliente>(
                              displayStringForOption: (cliente) => cliente.nombreCompleto,
                              textEditingController: _clienteController,
                              focusNode: _clienteFocusNode,
                              optionsBuilder: (textEditingValue) {
                                final query = textEditingValue.text.trim().toLowerCase();
                                if (query.isEmpty) {
                                  return clientes;
                                }
                                return clientes.where(
                                  (cliente) => cliente.nombreCompleto.toLowerCase().contains(query),
                                );
                              },
                              onSelected: (cliente) {
                                ref.read(recepcionFormProvider.notifier).setCliente(cliente.id);
                                _setClienteFieldText(cliente.nombreCompleto);
                              },
                              fieldViewBuilder: (context, textEditingController, focusNode, _) {
                                return TextFormField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'Cliente *',
                                    hintText: 'Buscar cliente por nombre',
                                  ),
                                  validator: (_) {
                                    if (ref.read(recepcionFormProvider).clienteId == null) {
                                      return 'Debes seleccionar un cliente.';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    final selected = _findClienteById(clientes, ref.read(recepcionFormProvider).clienteId);
                                    final matchesSelection = selected != null &&
                                        selected.nombreCompleto.trim().toLowerCase() == value.trim().toLowerCase();
                                    if (!matchesSelection) {
                                      ref.read(recepcionFormProvider.notifier).setCliente(null);
                                    }
                                  },
                                );
                              },
                              optionsViewBuilder: (context, onSelected, options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4,
                                    child: SizedBox(
                                      width: constraints.maxWidth,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxHeight: 220),
                                        child: ListView.builder(
                                          padding: EdgeInsets.zero,
                                          itemCount: options.length,
                                          itemBuilder: (context, index) {
                                            final cliente = options.elementAt(index);
                                            return ListTile(
                                              title: Text(cliente.nombreCompleto),
                                              subtitle: Text(cliente.telefono),
                                              onTap: () => onSelected(cliente),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DropdownButtonFormField<String>(
                          key: ValueKey('${draft.clienteId ?? ''}-${draft.vehiculoId ?? ''}'),
                          initialValue: vehiculosDelCliente.any((item) => item.id == draft.vehiculoId) ? draft.vehiculoId : null,
                          decoration: const InputDecoration(labelText: 'Vehículo *'),
                          items: [
                            for (final vehiculo in vehiculosDelCliente)
                              DropdownMenuItem(
                                value: vehiculo.id,
                                child: Text('${vehiculo.placa} · ${vehiculo.marca} ${vehiculo.modelo}'),
                              ),
                          ],
                          onChanged: _saving
                              ? null
                              : (value) {
                                  final vehiculo = _findVehiculoById(vehiculos, value);
                                  final suggestion = vehiculo?.kilometraje?.toString() ?? '';
                                  final currentValue = _kilometrajeController.text.trim();
                                  final shouldReplaceKilometraje = currentValue.isEmpty ||
                                      (_lastVehicleKilometrajeSuggestion != null &&
                                          currentValue == _lastVehicleKilometrajeSuggestion);
                                  if (shouldReplaceKilometraje) {
                                    _kilometrajeController.text = suggestion;
                                  }
                                  _lastVehicleKilometrajeSuggestion = suggestion;
                                  ref.read(recepcionFormProvider.notifier).setVehiculo(
                                        value,
                                        kilometrajeSugerido: vehiculo?.kilometraje?.toString(),
                                      );
                                },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Debes seleccionar un vehículo.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.md,
                          children: [
                            _DateField(
                              label: 'Fecha de ingreso',
                              value: draft.fechaIngreso,
                              onPressed: _saving
                                  ? null
                                  : () async {
                                      final selected = await showDatePicker(
                                        context: context,
                                        initialDate: draft.fechaIngreso,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (!mounted || selected == null) {
                                        return;
                                      }
                                      ref.read(recepcionFormProvider.notifier).setFechaIngreso(selected);
                                    },
                            ),
                            _DateField(
                              label: 'Fecha de salida estimada',
                              value: draft.fechaSalidaEstimada,
                              onPressed: _saving
                                  ? null
                                  : () async {
                                      final selected = await showDatePicker(
                                        context: context,
                                        initialDate: draft.fechaSalidaEstimada ?? draft.fechaIngreso,
                                        firstDate: draft.fechaIngreso,
                                        lastDate: DateTime(2100),
                                      );
                                      if (!mounted) {
                                        return;
                                      }
                                      ref.read(recepcionFormProvider.notifier).setFechaSalidaEstimada(selected);
                                    },
                            ),
                            SizedBox(
                              width: 220,
                              child: TextFormField(
                                controller: _kilometrajeController,
                                decoration: const InputDecoration(labelText: 'Kilometraje'),
                                keyboardType: TextInputType.number,
                                onChanged: (value) => ref.read(recepcionFormProvider.notifier).setKilometraje(value),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SwitchListTile(
                          value: draft.ingresoEnGrua,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Ingreso en grúa'),
                          onChanged: _saving
                              ? null
                              : (value) => ref.read(recepcionFormProvider.notifier).setIngresoEnGrua(value),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.sm,
                          children: [
                            _InfoPill(label: 'Marca', value: selectedVehiculo?.marca ?? '—'),
                            _InfoPill(label: 'Modelo', value: selectedVehiculo?.modelo ?? '—'),
                            _InfoPill(label: 'Color', value: selectedVehiculo?.color ?? '—'),
                            _InfoPill(label: 'Placas', value: selectedVehiculo?.placa ?? '—'),
                            _InfoPill(label: 'Nombre', value: selectedCliente?.nombreCompleto ?? '—'),
                            _InfoPill(label: 'Teléfono', value: selectedCliente?.telefono ?? '—'),
                            _InfoPill(label: 'Email', value: selectedCliente?.email ?? '—'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _TextSectionCard(
              title: 'TRABAJO A REALIZAR',
              controller: _trabajoController,
              hintText: 'Describe el trabajo solicitado por el cliente.',
              onChanged: (value) => ref.read(recepcionFormProvider.notifier).setTrabajoARealizar(value),
            ),
            const SizedBox(height: AppSpacing.md),
            _TextSectionCard(
              title: 'OBSERVACIONES',
              controller: _observacionesController,
              hintText: 'Anota artículos, detalles adicionales o información no contemplada en el checklist fijo.',
              onChanged: (value) => ref.read(recepcionFormProvider.notifier).setObservaciones(value),
            ),
            const SizedBox(height: AppSpacing.md),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        for (final item in draft.checklistSistemas)
                          FilterChip(
                            selected: item.marcado,
                            avatar: Icon(_iconFor(item.icono), size: 18),
                            label: Text(item.etiqueta),
                            onSelected: _saving
                                ? null
                                : (_) => ref.read(recepcionFormProvider.notifier).toggleSistema(item.clave),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final item in draft.inventario)
                              SizedBox(
                                width: 220,
                                child: CheckboxListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item.item),
                                  value: item.marcado,
                                  onChanged: _saving
                                      ? null
                                      : (_) => ref.read(recepcionFormProvider.notifier).toggleInventario(item.item),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text('Nivel de combustible', style: Theme.of(context).textTheme.titleSmall),
                        Row(
                          children: [
                            const Text('E'),
                            Expanded(
                              child: Slider(
                                value: draft.nivelCombustible.clamp(0.0, 1.0).toDouble(),
                                divisions: 4,
                                label: _fuelLabel(draft.nivelCombustible),
                                onChanged: _saving
                                    ? null
                                    : (value) => ref.read(recepcionFormProvider.notifier).setNivelCombustible(value),
                              ),
                            ),
                            const Text('F'),
                          ],
                        ),
                        Text(
                          'Nivel seleccionado: ${_fuelLabel(draft.nivelCombustible)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                  puntos: draft.danosPreexistentes
                                      .where((item) => item.vista == vista)
                                      .toList(growable: false),
                                  onTapPunto: _saving
                                      ? null
                                      : (punto) => ref.read(recepcionFormProvider.notifier).addDano(
                                            vista: vista,
                                            puntoRelativo: punto,
                                          ),
                                  onUndo: _saving
                                      ? null
                                      : () => ref.read(recepcionFormProvider.notifier).undoDanoVista(vista),
                                  onClear: _saving
                                      ? null
                                      : () => ref.read(recepcionFormProvider.notifier).clearDanosVista(vista),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            AppPrimaryButton(
                              label: 'Adjuntar fotografías',
                              icon: Icons.add_a_photo_rounded,
                              onPressed: _saving ? null : _seleccionarFotografias,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (draft.fotografiasExistentes.isEmpty && draft.fotografiasPendientes.isEmpty)
                          const Text('No hay fotografías adjuntas.')
                        else
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final foto in draft.fotografiasExistentes)
                                _ImageThumbnail(
                                  image: Image.network(
                                    foto,
                                    width: 110,
                                    height: 90,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                                  ),
                                  onRemove: _saving
                                      ? null
                                      : () => ref.read(recepcionFormProvider.notifier).removeFotografiaExistente(foto),
                                ),
                              for (final foto in draft.fotografiasPendientes)
                                _ImageThumbnail(
                                  image: Image.memory(
                                    foto.bytes,
                                    width: 110,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                                  onRemove: _saving
                                      ? null
                                      : () => ref.read(recepcionFormProvider.notifier).removeFotografiaPendiente(foto.id),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionBand(title: 'FIRMAS'),
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
                      children: [
                        _SignatureCaptureCard(
                          title: 'Firma del prestador del servicio',
                          helperText: 'Captura esta firma en una ventana amplia. Se firma una a la vez.',
                          hasRemoteSignature: draft.firmaPrestadorUrl?.trim().isNotEmpty == true,
                          remoteSignatureUrl: draft.firmaPrestadorUrl,
                          trazos: draft.firmaPrestadorTrazos,
                          onTapSign: _saving
                              ? null
                              : () => _capturarFirma(
                                    title: 'Firma del prestador del servicio',
                                    helperText: 'Dibuja la firma con mouse o dedo.',
                                    initialTrazos: draft.firmaPrestadorTrazos,
                                    onSave: (value) =>
                                        ref.read(recepcionFormProvider.notifier).setFirmaPrestador(value),
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _SignatureCaptureCard(
                          title: 'Firma del cliente',
                          helperText: 'Captura esta firma en una ventana amplia. Se firma una a la vez.',
                          hasRemoteSignature: draft.firmaClienteUrl?.trim().isNotEmpty == true,
                          remoteSignatureUrl: draft.firmaClienteUrl,
                          trazos: draft.firmaClienteTrazos,
                          onTapSign: _saving
                              ? null
                              : () => _capturarFirma(
                                    title: 'Firma del cliente',
                                    helperText: 'Firma digital capturada directamente en la pantalla.',
                                    initialTrazos: draft.firmaClienteTrazos,
                                    onSave: (value) => ref.read(recepcionFormProvider.notifier).setFirmaCliente(value),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppPrimaryButton(
                  label: _saving ? 'Guardando...' : 'Guardar recepción',
                  icon: Icons.save_rounded,
                  onPressed: _saving ? null : _guardar,
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
    );
  }

  RecepcionFormState _ensureInitialized(
    String seedKey,
    RecepcionVehiculo? recepcion,
    List<Cliente> clientes,
    RecepcionFormState providerDraft,
  ) {
    if (_initializedFor == seedKey) {
      return providerDraft;
    }
    final draft = recepcion == null ? RecepcionFormState.initial() : RecepcionFormState.fromRecepcion(recepcion);
    final cliente = _findClienteById(clientes, draft.clienteId);
    _setClienteFieldText(cliente?.nombreCompleto ?? '');
    _kilometrajeController.text = draft.kilometraje;
    _lastVehicleKilometrajeSuggestion = draft.kilometraje.isEmpty ? null : draft.kilometraje;
    _trabajoController.text = draft.trabajoARealizar;
    _observacionesController.text = draft.observaciones;
    _initializedFor = seedKey;
    Future.microtask(() => ref.read(recepcionFormProvider.notifier).initialize(recepcion));
    return draft;
  }

  Future<void> _seleccionarFotografias() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
      allowMultiple: true,
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }
    final files = <RecepcionArchivoLocal>[];
    for (var index = 0; index < result.files.length; index++) {
      final file = result.files[index];
      final extension = file.extension?.toLowerCase();
      const validExtensions = {'png', 'jpg', 'jpeg', 'webp'};
      if (extension == null || !validExtensions.contains(extension)) {
        continue;
      }
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        continue;
      }
      files.add(
        RecepcionArchivoLocal(
          id: '${DateTime.now().microsecondsSinceEpoch}-$index',
          nombreArchivo: file.name,
          bytes: bytes,
        ),
      );
    }
    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron leer imágenes válidas.')),
      );
      return;
    }
    ref.read(recepcionFormProvider.notifier).addFotografiasPendientes(files);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final draft = ref.read(recepcionFormProvider);
    if (!draft.tieneFirmaPrestador || !draft.tieneFirmaCliente) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes capturar ambas firmas antes de guardar la recepción.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repository = ref.read(recepcionRepositoryProvider);
      final urlsFotografias = [...draft.fotografiasExistentes];
      for (final foto in draft.fotografiasPendientes) {
        final url = await repository.subirFotografia(foto.bytes, foto.nombreArchivo);
        urlsFotografias.add(url);
      }

      var firmaPrestadorUrl = draft.firmaPrestadorUrl;
      if (draft.firmaPrestadorTrazos.any((stroke) => stroke.isNotEmpty)) {
        final bytes = await _renderSignatureBytes(draft.firmaPrestadorTrazos);
        if (bytes == null || bytes.isEmpty) {
          throw StateError('No se pudo generar la firma del prestador.');
        }
        firmaPrestadorUrl = await repository.subirFirma(
          bytes,
          'prestador_${DateTime.now().microsecondsSinceEpoch}.png',
        );
      }

      var firmaClienteUrl = draft.firmaClienteUrl;
      if (draft.firmaClienteTrazos.any((stroke) => stroke.isNotEmpty)) {
        final bytes = await _renderSignatureBytes(draft.firmaClienteTrazos);
        if (bytes == null || bytes.isEmpty) {
          throw StateError('No se pudo generar la firma del cliente.');
        }
        firmaClienteUrl = await repository.subirFirma(
          bytes,
          'cliente_${DateTime.now().microsecondsSinceEpoch}.png',
        );
      }

      final recepcion = draft.toRecepcion(
        fotografias: urlsFotografias,
        firmaPrestadorUrl: firmaPrestadorUrl,
        firmaClienteUrl: firmaClienteUrl,
      );

      final saved = widget.recepcionId == null
          ? await ref.read(recepcionesProvider.notifier).crear(recepcion)
          : await ref.read(recepcionesProvider.notifier).editar(recepcion);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recepción guardada correctamente.')),
      );
      context.go('/trabajos/recepciones/${saved.id}');
    } catch (error) {
      if (!mounted) {
        return;
      }
      final rawMessage = error is StateError ? error.message : error.toString();
      final message = rawMessage == emptyImageUploadErrorMessage ||
              rawMessage == 'Solo se permiten imágenes PNG, JPG/JPEG o WEBP.' ||
              rawMessage == 'La extensión del archivo no coincide con su formato real.'
          ? 'No se pudo guardar la recepción: uno de los archivos está vacío o no es válido. Intenta seleccionarlo nuevamente.'
          : 'No se pudo guardar la recepción: $rawMessage';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _capturarFirma({
    required String title,
    required String helperText,
    required List<List<Offset>> initialTrazos,
    required ValueChanged<List<List<Offset>>> onSave,
  }) async {
    final dialogSize = MediaQuery.sizeOf(context);
    final trazosIniciales = initialTrazos.map((stroke) => stroke.toList(growable: true)).toList(growable: true);
    final result = await showDialog<List<List<Offset>>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var currentTrazos = trazosIniciales;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: dialogSize.width * 0.92,
                height: dialogSize.height * 0.86,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Expanded(
                        child: SignaturePad(
                          title: 'Área de firma',
                          helperText: helperText,
                          trazos: currentTrazos,
                          onChanged: (value) => setDialogState(() => currentTrazos = value),
                          repaintBoundaryKey: GlobalKey(),
                          canvasHeight: dialogSize.height * 0.52,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => setDialogState(() => currentTrazos = <List<Offset>>[]),
                            icon: const Icon(Icons.restart_alt_rounded),
                            label: const Text('Limpiar'),
                          ),
                          FilledButton.icon(
                            onPressed: currentTrazos.any((stroke) => stroke.isNotEmpty)
                                ? () => Navigator.of(context).pop(
                                      currentTrazos
                                          .map((stroke) => stroke.toList(growable: false))
                                          .toList(growable: false),
                                    )
                                : null,
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Guardar firma'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (result != null) {
      onSave(result);
    }
  }

  Future<Uint8List?> _renderSignatureBytes(List<List<Offset>> trazos) async {
    final nonEmptyStrokes = trazos.where((stroke) => stroke.isNotEmpty).toList(growable: false);
    if (nonEmptyStrokes.isEmpty) {
      return null;
    }
    const width = 1200.0;
    const height = 480.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), backgroundPaint);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..color = Colors.black87;

    double maxX = 0;
    double maxY = 0;
    for (final stroke in nonEmptyStrokes) {
      for (final point in stroke) {
        if (point.dx > maxX) {
          maxX = point.dx;
        }
        if (point.dy > maxY) {
          maxY = point.dy;
        }
      }
    }
    final scaleX = maxX <= 0 ? 1.0 : (width - 40) / maxX;
    final scaleY = maxY <= 0 ? 1.0 : (height - 40) / maxY;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    canvas.translate(20, 20);
    canvas.scale(scale.isFinite && scale > 0 ? scale : 1.0);
    for (final stroke in nonEmptyStrokes) {
      if (stroke.length == 1) {
        canvas.drawPoints(ui.PointMode.points, stroke, paint);
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var index = 1; index < stroke.length; index++) {
        path.lineTo(stroke[index].dx, stroke[index].dy);
      }
      canvas.drawPath(path, paint);
    }
    final picture = recorder.endRecording();
    ui.Image? image;
    try {
      image = await picture.toImage(width.toInt(), height.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes?.buffer.asUint8List();
    } finally {
      image?.dispose();
    }
  }

  void _setClienteFieldText(String value) {
    _clienteController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Cliente? _findClienteById(List<Cliente> clientes, String? id) {
    if (id == null) {
      return null;
    }
    for (final cliente in clientes) {
      if (cliente.id == id) {
        return cliente;
      }
    }
    return null;
  }

  Vehiculo? _findVehiculoById(List<Vehiculo> vehiculos, String? id) {
    if (id == null) {
      return null;
    }
    for (final vehiculo in vehiculos) {
      if (vehiculo.id == id) {
        return vehiculo;
      }
    }
    return null;
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

  static String _fuelLabel(double value) {
    final normalized = value.clamp(0.0, 1.0).toDouble();
    if (normalized <= 0.1) {
      return 'Vacío';
    }
    if (normalized <= 0.3) {
      return '1/4';
    }
    if (normalized <= 0.55) {
      return '1/2';
    }
    if (normalized <= 0.8) {
      return '3/4';
    }
    return 'Lleno';
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

class _SignatureCaptureCard extends StatelessWidget {
  const _SignatureCaptureCard({
    required this.title,
    required this.helperText,
    required this.hasRemoteSignature,
    required this.remoteSignatureUrl,
    required this.trazos,
    required this.onTapSign,
  });

  final String title;
  final String helperText;
  final bool hasRemoteSignature;
  final String? remoteSignatureUrl;
  final List<List<Offset>> trazos;
  final VoidCallback? onTapSign;

  @override
  Widget build(BuildContext context) {
    final hasLocalSignature = trazos.any((stroke) => stroke.isNotEmpty);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text(helperText, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          if (hasLocalSignature)
            SignatureThumbnail(trazos: trazos)
          else if (hasRemoteSignature && remoteSignatureUrl != null && remoteSignatureUrl!.trim().isNotEmpty)
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              alignment: Alignment.center,
              child: Image.network(
                remoteSignatureUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text('Firma guardada'),
              ),
            )
          else
            const SignatureThumbnail(trazos: <List<Offset>>[]),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasLocalSignature || hasRemoteSignature ? 'Estado: firma capturada.' : 'Estado: pendiente de firma.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: onTapSign,
            icon: const Icon(Icons.draw_rounded),
            label: Text(hasLocalSignature || hasRemoteSignature ? 'Volver a firmar' : 'Firmar'),
          ),
        ],
      ),
    );
  }
}

class _TextSectionCard extends StatelessWidget {
  const _TextSectionCard({
    required this.title,
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final String title;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionBand(title: title),
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
            child: TextFormField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final DateTime? value;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: ListTile(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(label),
        subtitle: Text(_formatDate(value)),
        trailing: IconButton(
          tooltip: 'Cambiar fecha',
          onPressed: onPressed,
          icon: const Icon(Icons.edit_calendar_rounded),
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Sin definir';
    }
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0x08000000),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({
    required this.image,
    required this.onRemove,
  });

  final Widget image;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 110,
            height: 90,
            color: Colors.black12,
            child: image,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton.filledTonal(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          ),
        ),
      ],
    );
  }
}
