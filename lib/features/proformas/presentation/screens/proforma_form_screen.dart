import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../clientes/domain/models/cliente.dart';
import '../../../clientes/presentation/providers/clientes_provider.dart';
import '../../../configuracion/servicios/domain/models/paquete_servicio.dart';
import '../../../configuracion/servicios/domain/models/servicio.dart';
import '../../../configuracion/servicios/presentation/providers/paquetes_servicios_provider.dart';
import '../../../configuracion/servicios/presentation/providers/servicios_provider.dart';
import '../../../vehiculos/domain/models/vehiculo.dart';
import '../../../vehiculos/presentation/providers/vehiculos_provider.dart';
import '../../domain/models/proforma.dart';
import '../providers/proformas_provider.dart';

class ProformaFormScreen extends ConsumerStatefulWidget {
  const ProformaFormScreen({this.proformaId, super.key});

  final String? proformaId;

  @override
  ConsumerState<ProformaFormScreen> createState() => _ProformaFormScreenState();
}

class _ProformaFormScreenState extends ConsumerState<ProformaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clienteController = TextEditingController();
  final _clienteFocusNode = FocusNode();
  final _condicionesController = TextEditingController();
  final _validezController = TextEditingController();
  final _tiempoEntregaController = TextEditingController();
  final _tiempoGarantiaController = TextEditingController();
  final _formaPagoController = TextEditingController();

  final _servicioController = TextEditingController();
  final _servicioFocusNode = FocusNode();
  final _paqueteController = TextEditingController();
  final _paqueteFocusNode = FocusNode();
  final _repuestoDescripcionController = TextEditingController();
  final _repuestoCantidadController = TextEditingController(text: '1');
  final _repuestoPrecioController = TextEditingController();

  bool _initialized = false;
  bool _saving = false;
  DateTime _fecha = DateTime.now();
  String _numeroProforma = '';
  String? _selectedClienteId;
  String? _selectedVehiculoId;
  Servicio? _servicioSeleccionado;
  PaqueteServicio? _paqueteSeleccionado;
  List<ProformaItem> _items = <ProformaItem>[];
  Proforma? _editingProforma;
  List<String> _itemRowKeys = <String>[];
  int _nextItemKey = 0;

  @override
  void didUpdateWidget(covariant ProformaFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.proformaId != widget.proformaId) {
      _resetLocalState();
    }
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _clienteFocusNode.dispose();
    _condicionesController.dispose();
    _validezController.dispose();
    _tiempoEntregaController.dispose();
    _tiempoGarantiaController.dispose();
    _formaPagoController.dispose();
    _servicioController.dispose();
    _servicioFocusNode.dispose();
    _paqueteController.dispose();
    _paqueteFocusNode.dispose();
    _repuestoDescripcionController.dispose();
    _repuestoCantidadController.dispose();
    _repuestoPrecioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proformasAsync = ref.watch(proformasProvider);
    final proformaId = widget.proformaId;
    final proforma = proformaId == null ? null : ref.watch(proformaByIdProvider(proformaId));

    final clientesAsync = ref.watch(clientesProvider);
    final clientes = clientesAsync.valueOrNull ?? const <Cliente>[];

    final vehiculosAsync = ref.watch(vehiculosProvider);
    final vehiculos = vehiculosAsync.valueOrNull ?? const <Vehiculo>[];

    final serviciosAsync = ref.watch(serviciosProvider);
    final servicios = serviciosAsync.valueOrNull ?? const <Servicio>[];

    final paquetesAsync = ref.watch(paquetesServiciosProvider);
    final paquetes = paquetesAsync.valueOrNull ?? const <PaqueteServicio>[];

    if (clientesAsync.isLoading || vehiculosAsync.isLoading || serviciosAsync.isLoading || paquetesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (clientesAsync.hasError) {
      return Center(child: Text('Error al cargar clientes: ${clientesAsync.error}'));
    }
    if (vehiculosAsync.hasError) {
      return Center(child: Text('Error al cargar vehículos: ${vehiculosAsync.error}'));
    }
    if (serviciosAsync.hasError) {
      return Center(child: Text('Error al cargar servicios: ${serviciosAsync.error}'));
    }
    if (paquetesAsync.hasError) {
      return Center(child: Text('Error al cargar paquetes: ${paquetesAsync.error}'));
    }

    if (proformaId != null && proforma == null) {
      if (proformasAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (proformasAsync.hasError) {
        return Center(child: Text('Error al cargar proforma: ${proformasAsync.error}'));
      }
      return const Center(child: Text('Proforma no encontrada.'));
    }

    if (!_initialized) {
      if (proforma != null) {
        _editingProforma = proforma;
        _fecha = proforma.fecha;
        _numeroProforma = proforma.numero;
        _selectedClienteId = proforma.clienteId;
        _selectedVehiculoId = proforma.vehiculoId;
        _condicionesController.text = proforma.condicionesPago ?? '';
        _validezController.text = proforma.validez ?? '';
        _tiempoEntregaController.text = proforma.tiempoEntrega ?? '';
        _tiempoGarantiaController.text = proforma.tiempoGarantia ?? '';
        _formaPagoController.text = proforma.formaPago ?? '';
        _items = proforma.items.toList(growable: true);
        _itemRowKeys = _items.map((item) => _buildRowKey(baseId: item.id)).toList(growable: true);
      } else {
        _editingProforma = null;
        _fecha = DateTime.now();
        _numeroProforma = '';
        _itemRowKeys = <String>[];
      }
      _syncClienteField(clientes);
      _initialized = true;
    }

    final vehiculosDelCliente = _selectedClienteId == null
        ? const <Vehiculo>[]
        : vehiculos.where((vehiculo) => vehiculo.clienteId == _selectedClienteId).toList(growable: false);

    final selectedCliente = _findClienteById(clientes, _selectedClienteId);
    if (selectedCliente != null &&
        !_clienteFocusNode.hasFocus &&
        _clienteController.text.trim().toLowerCase() != selectedCliente.nombreCompleto.trim().toLowerCase()) {
      _setClienteFieldText(selectedCliente.nombreCompleto);
    }

    final total = _items.fold<double>(0, (sum, item) => sum + item.total);

    return SingleChildScrollView(
      child: AppSectionCard(
        title: proforma == null ? 'Nueva proforma' : 'Editar proforma',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('N° Proforma: ${_numeroProforma.isEmpty ? 'Se asignará al guardar' : _numeroProforma}'),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de emisión'),
                subtitle: Text(_formatDate(_fecha)),
                trailing: IconButton(
                  tooltip: 'Cambiar fecha',
                  onPressed: _saving
                      ? null
                      : () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: _fecha,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (!mounted || selected == null) {
                            return;
                          }
                          setState(() {
                            _fecha = selected;
                          });
                        },
                  icon: const Icon(Icons.edit_calendar_rounded),
                ),
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
                      setState(() {
                        _selectedClienteId = cliente.id;
                        _selectedVehiculoId = null;
                      });
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
                          if (_selectedClienteId == null || _selectedClienteId!.isEmpty) {
                            return 'Debes seleccionar un cliente.';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          final selected = _findClienteById(clientes, _selectedClienteId);
                          final matchesSelection = selected != null &&
                              selected.nombreCompleto.trim().toLowerCase() == value.trim().toLowerCase();
                          if (!matchesSelection && _selectedClienteId != null) {
                            setState(() {
                              _selectedClienteId = null;
                              _selectedVehiculoId = null;
                            });
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
                key: ValueKey('${_selectedClienteId ?? ''}-${_selectedVehiculoId ?? ''}'),
                value: vehiculosDelCliente.any((item) => item.id == _selectedVehiculoId) ? _selectedVehiculoId : null,
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
                        setState(() => _selectedVehiculoId = value);
                      },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Debes seleccionar un vehículo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Agregar ítems', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              _CatalogAddField<Servicio>(
                label: 'Agregar servicio',
                controller: _servicioController,
                focusNode: _servicioFocusNode,
                options: servicios,
                optionLabel: (servicio) => '${servicio.nombre} · ${_formatBs(servicio.precio)}',
                onSelected: (servicio) => _servicioSeleccionado = servicio,
                onTextChanged: (value) {
                  final selected = _servicioSeleccionado;
                  if (selected == null) {
                    return;
                  }
                  final expected = '${selected.nombre} · ${_formatBs(selected.precio)}';
                  if (value.trim() != expected.trim()) {
                    _servicioSeleccionado = null;
                  }
                },
                onAdd: () {
                  final servicio = _servicioSeleccionado;
                  if (servicio == null) {
                    return;
                  }
                  setState(() {
                    _items.add(
                      ProformaItem(
                        id: '',
                        tipoItem: ProformaItemTipo.servicio,
                        referenciaId: servicio.id,
                        descripcion: servicio.nombre,
                        cantidad: 1,
                        precioUnitario: servicio.precio,
                      ),
                    );
                    _itemRowKeys.add(_buildRowKey());
                    _servicioSeleccionado = null;
                    _servicioController.clear();
                  });
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _CatalogAddField<PaqueteServicio>(
                label: 'Agregar paquete',
                controller: _paqueteController,
                focusNode: _paqueteFocusNode,
                options: paquetes,
                optionLabel: (paquete) => '${paquete.nombre} · ${_formatBs(paquete.precioTotalCalculado)}',
                onSelected: (paquete) => _paqueteSeleccionado = paquete,
                onTextChanged: (value) {
                  final selected = _paqueteSeleccionado;
                  if (selected == null) {
                    return;
                  }
                  final expected = '${selected.nombre} · ${_formatBs(selected.precioTotalCalculado)}';
                  if (value.trim() != expected.trim()) {
                    _paqueteSeleccionado = null;
                  }
                },
                onAdd: () {
                  final paquete = _paqueteSeleccionado;
                  if (paquete == null) {
                    return;
                  }
                  setState(() {
                    _items.add(
                      ProformaItem(
                        id: '',
                        tipoItem: ProformaItemTipo.paquete,
                        referenciaId: paquete.id,
                        descripcion: paquete.nombre,
                        cantidad: 1,
                        precioUnitario: paquete.precioTotalCalculado,
                      ),
                    );
                    _itemRowKeys.add(_buildRowKey());
                    _paqueteSeleccionado = null;
                    _paqueteController.clear();
                  });
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _repuestoDescripcionController,
                      decoration: const InputDecoration(labelText: 'Repuesto/Insumo'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _repuestoCantidadController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Cant.'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _repuestoPrecioController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Precio'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    tooltip: 'Agregar repuesto/insumo',
                    onPressed: _agregarRepuesto,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (_items.isEmpty)
                const Text('Aún no agregaste ítems.')
              else
                AppDataTable(
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(label: Text('Cant.')),
                    DataColumn(label: Text('Descripción')),
                    DataColumn(label: Text('Precio unitario')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('')),
                  ],
                  rows: [
                    for (var i = 0; i < _items.length; i++)
                      DataRow(
                        key: ValueKey(_itemRowKeys[i]),
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 70,
                              child: TextFormField(
                                key: ValueKey('${_itemRowKeys[i]}-cantidad'),
                                initialValue: _items[i].cantidad.toStringAsFixed(2),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (value) => _updateCantidad(i, value),
                              ),
                            ),
                          ),
                          DataCell(Text(_items[i].descripcion)),
                          DataCell(
                            SizedBox(
                              width: 110,
                              child: TextFormField(
                                key: ValueKey('${_itemRowKeys[i]}-precio'),
                                initialValue: _items[i].precioUnitario.toStringAsFixed(2),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (value) => _updatePrecio(i, value),
                              ),
                            ),
                          ),
                          DataCell(Text(_formatBs(_items[i].total))),
                          DataCell(
                            IconButton(
                              tooltip: 'Eliminar ítem',
                              onPressed: () => setState(() {
                                _items.removeAt(i);
                                _itemRowKeys.removeAt(i);
                              }),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'TOTAL: ${_formatBs(total)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _condicionesController,
                decoration: const InputDecoration(labelText: 'Condiciones y forma de pago'),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _validezController,
                decoration: const InputDecoration(labelText: 'Validez de la proforma'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _tiempoEntregaController,
                decoration: const InputDecoration(labelText: 'Tiempo de entrega'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _tiempoGarantiaController,
                decoration: const InputDecoration(labelText: 'Tiempo de garantía'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _formaPagoController,
                decoration: const InputDecoration(labelText: 'Forma de pago'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppPrimaryButton(
                    label: _saving ? 'Guardando...' : 'Guardar',
                    icon: Icons.save_rounded,
                    onPressed: _saving ? null : () => _guardar(emitir: false),
                  ),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : () => _guardar(emitir: true),
                    icon: const Icon(Icons.task_alt_rounded),
                    label: const Text('Marcar como emitida'),
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

  void _agregarRepuesto() {
    final descripcion = _repuestoDescripcionController.text.trim();
    final cantidad = double.tryParse(_repuestoCantidadController.text.replaceAll(',', '.').trim());
    final precio = double.tryParse(_repuestoPrecioController.text.replaceAll(',', '.').trim());

    if (descripcion.isEmpty || cantidad == null || cantidad <= 0 || precio == null || precio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa repuesto/insumo con descripción, cantidad y precio válidos.')),
      );
      return;
    }

    setState(() {
      _items.add(
        ProformaItem(
          id: '',
          tipoItem: ProformaItemTipo.repuestoInsumo,
          descripcion: descripcion,
          cantidad: cantidad,
          precioUnitario: precio,
        ),
      );
      _itemRowKeys.add(_buildRowKey());
      _repuestoDescripcionController.clear();
      _repuestoCantidadController.text = '1';
      _repuestoPrecioController.clear();
    });
  }

  void _updateCantidad(int index, String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.').trim());
    if (parsed == null || parsed <= 0) {
      return;
    }
    setState(() {
      _items[index] = _items[index].copyWith(cantidad: parsed);
    });
  }

  void _updatePrecio(int index, String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.').trim());
    if (parsed == null || parsed <= 0) {
      return;
    }
    setState(() {
      _items[index] = _items[index].copyWith(precioUnitario: parsed);
    });
  }

  Future<void> _guardar({required bool emitir}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes agregar al menos un ítem.')),
      );
      return;
    }

    final hasInvalidItem = _items.any((item) => item.cantidad <= 0 || item.precioUnitario <= 0);
    if (hasInvalidItem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los ítems deben tener cantidad y precio unitario positivos.')),
      );
      return;
    }

    setState(() => _saving = true);
    final current = widget.proformaId == null ? null : _editingProforma;
    if (widget.proformaId != null && current == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aún se está cargando la proforma para editar.')),
        );
        setState(() => _saving = false);
      }
      return;
    }

    final proforma = Proforma(
      id: current?.id ?? '',
      numero: current?.numero ?? _numeroProforma,
      clienteId: _selectedClienteId!,
      vehiculoId: _selectedVehiculoId!,
      fecha: _fecha,
      items: _items,
      condicionesPago: _optional(_condicionesController.text),
      validez: _optional(_validezController.text),
      tiempoEntrega: _optional(_tiempoEntregaController.text),
      tiempoGarantia: _optional(_tiempoGarantiaController.text),
      formaPago: _optional(_formaPagoController.text),
      estado: emitir ? ProformaEstado.emitida : (current?.estado ?? ProformaEstado.borrador),
      total: _items.fold<double>(0, (sum, item) => sum + item.total),
      fechaCreacion: current?.fechaCreacion ?? DateTime.now(),
    );

    try {
      final notifier = ref.read(proformasProvider.notifier);
      final saved = current == null ? await notifier.crearProforma(proforma) : await notifier.editarProforma(proforma);
      if (!mounted) {
        return;
      }
      _editingProforma = saved;
      context.go('/proformas/${saved.id}');
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la proforma.')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Cliente? _findClienteById(List<Cliente> clientes, String? clienteId) {
    if (clienteId == null) {
      return null;
    }
    for (final cliente in clientes) {
      if (cliente.id == clienteId) {
        return cliente;
      }
    }
    return null;
  }

  void _syncClienteField(List<Cliente> clientes) {
    final selected = _findClienteById(clientes, _selectedClienteId);
    if (selected == null) {
      _setClienteFieldText('');
      return;
    }
    _setClienteFieldText(selected.nombreCompleto);
  }

  void _setClienteFieldText(String value) {
    _clienteController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _formatBs(double value) => 'Bs. ${value.toStringAsFixed(2)}';

  String? _optional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _buildRowKey({String? baseId}) {
    if (baseId != null && baseId.trim().isNotEmpty) {
      return 'db_${baseId.trim()}';
    }
    final key = 'tmp_${_nextItemKey.toString()}';
    _nextItemKey++;
    return key;
  }

  void _resetLocalState() {
    _initialized = false;
    _saving = false;
    _fecha = DateTime.now();
    _numeroProforma = '';
    _selectedClienteId = null;
    _selectedVehiculoId = null;
    _servicioSeleccionado = null;
    _paqueteSeleccionado = null;
    _items = <ProformaItem>[];
    _editingProforma = null;
    _itemRowKeys = <String>[];
    _nextItemKey = 0;
    _clienteController.clear();
    _condicionesController.clear();
    _validezController.clear();
    _tiempoEntregaController.clear();
    _tiempoGarantiaController.clear();
    _formaPagoController.clear();
    _servicioController.clear();
    _paqueteController.clear();
    _repuestoDescripcionController.clear();
    _repuestoCantidadController.text = '1';
    _repuestoPrecioController.clear();
  }
}

class _CatalogAddField<T> extends StatelessWidget {
  const _CatalogAddField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.options,
    required this.optionLabel,
    required this.onSelected,
    required this.onTextChanged,
    required this.onAdd,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<T> options;
  final String Function(T) optionLabel;
  final void Function(T) onSelected;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: RawAutocomplete<T>(
            displayStringForOption: optionLabel,
            textEditingController: controller,
            focusNode: focusNode,
            optionsBuilder: (textEditingValue) {
              final query = textEditingValue.text.trim().toLowerCase();
              if (query.isEmpty) {
                return options;
              }
              return options.where((option) => optionLabel(option).toLowerCase().contains(query));
            },
            onSelected: onSelected,
            fieldViewBuilder: (context, textEditingController, focusNode, _) {
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(labelText: label),
                onChanged: onTextChanged,
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
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(optionLabel(option)),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              tooltip: label,
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ],
        );
      },
    );
  }
}
