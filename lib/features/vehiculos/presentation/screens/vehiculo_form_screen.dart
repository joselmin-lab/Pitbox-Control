import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../clientes/domain/models/cliente.dart';
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
  final _clienteController = TextEditingController();
  final _clienteFocusNode = FocusNode();
  final _placaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anioController = TextEditingController();
  final _colorController = TextEditingController();
  final _kilometrajeController = TextEditingController();

  String? _selectedClienteId;
  bool _initialized = false;
  bool _saving = false;
  bool _showAllClienteSuggestions = false;

  @override
  void didUpdateWidget(covariant VehiculoFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehiculoId != widget.vehiculoId || oldWidget.clienteId != widget.clienteId) {
      _initialized = false;
    }
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _clienteFocusNode.dispose();
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
      orElse: () => const <Cliente>[],
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
      _syncClienteField(clientes);
      _initialized = true;
    }

    final isEdit = vehiculo != null;
    final selectedCliente = _findClienteById(clientes, _selectedClienteId);

    if (selectedCliente != null &&
        !_clienteFocusNode.hasFocus &&
        _normalizeClienteValue(_clienteController.text) !=
            _normalizeClienteValue(selectedCliente.nombreCompleto)) {
      _setClienteFieldText(selectedCliente.nombreCompleto);
    }

    return SingleChildScrollView(
      child: AppSectionCard(
        title: isEdit ? 'Editar vehículo' : 'Nuevo vehículo',
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, fieldConstraints) {
                  return RawAutocomplete<Cliente>(
                    displayStringForOption: (cliente) => cliente.nombreCompleto,
                    textEditingController: _clienteController,
                    focusNode: _clienteFocusNode,
                    optionsBuilder: (textEditingValue) {
                      final query = _normalizeClienteValue(textEditingValue.text);
                      if (_showAllClienteSuggestions) {
                        return clientes;
                      }
                      if (query.isNotEmpty) {
                        return clientes.where((cliente) {
                          return _normalizeClienteValue(cliente.nombreCompleto).contains(query);
                        });
                      }
                      return const <Cliente>[];
                    },
                    onSelected: (cliente) {
                      setState(() {
                        _selectedClienteId = cliente.id;
                        _showAllClienteSuggestions = false;
                      });
                      _setClienteFieldText(cliente.nombreCompleto);
                    },
                    fieldViewBuilder: (context, textEditingController, focusNode, _) {
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Cliente asociado *',
                          hintText: 'Buscar cliente por nombre',
                          helperText: 'Selecciona un cliente de la lista o escribe el nombre completo.',
                          suffixIcon: IconButton(
                            tooltip: 'Mostrar clientes',
                            icon: const Icon(Icons.arrow_drop_down_rounded),
                            onPressed: () {
                              setState(() => _showAllClienteSuggestions = true);
                              _clienteFocusNode.requestFocus();
                              _clienteController.value = TextEditingValue(
                                text: _clienteController.text,
                                selection: TextSelection(
                                  baseOffset: 0,
                                  extentOffset: _clienteController.text.length,
                                ),
                              );
                            },
                          ),
                        ),
                        onChanged: (value) {
                          if (_showAllClienteSuggestions) {
                            setState(() => _showAllClienteSuggestions = false);
                          }
                          final exactCliente = _findClienteByExactName(clientes, value);
                          final currentSelectedCliente = _findClienteById(clientes, _selectedClienteId);
                          final normalizedValue = _normalizeClienteValue(value);
                          final normalizedSelectedName =
                              _normalizeClienteValue(currentSelectedCliente?.nombreCompleto ?? '');
                          final stillMatchesSelected =
                              _selectedClienteId != null && normalizedValue == normalizedSelectedName;

                          if (stillMatchesSelected) {
                            return;
                          }
                          if (exactCliente != null && exactCliente.id != _selectedClienteId) {
                            setState(() => _selectedClienteId = exactCliente.id);
                            return;
                          }
                          if (exactCliente == null && _selectedClienteId != null) {
                            setState(() => _selectedClienteId = null);
                          }
                        },
                        onFieldSubmitted: (_) {
                          _applyResolvedClienteSelection(
                            clientes,
                            _findClienteByExactName(clientes, textEditingController.text),
                          );
                        },
                        validator: (_) {
                          final exactCliente =
                              _findClienteByExactName(clientes, textEditingController.text);
                          if ((_selectedClienteId == null || _selectedClienteId!.isEmpty) &&
                              exactCliente == null) {
                            return 'Debes seleccionar un cliente.';
                          }
                          return null;
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Semantics(
                          label: 'Sugerencias de clientes',
                          child: Material(
                            elevation: 4,
                            child: SizedBox(
                              width: fieldConstraints.maxWidth,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 240),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final cliente = options.elementAt(index);
                                    final isHighlighted =
                                        AutocompleteHighlightedOption.of(context) == index;
                                    return Semantics(
                                      button: true,
                                      label: 'Seleccionar cliente ${cliente.nombreCompleto}',
                                      child: Material(
                                        color: isHighlighted
                                            ? Theme.of(context).colorScheme.surfaceContainerHighest
                                            : Colors.transparent,
                                        child: ListTile(
                                          selected: isHighlighted,
                                          title: Text(cliente.nombreCompleto),
                                          onTap: () => onSelected(cliente),
                                        ),
                                      ),
                                    );
                                  },
                                ),
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
                            _applyResolvedClienteSelection(
                              clientes,
                              _findClienteByExactName(clientes, _clienteController.text),
                            );
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

  Cliente? _findClienteByExactName(List<Cliente> clientes, String value) {
    final normalizedValue = _normalizeClienteValue(value);
    if (normalizedValue.isEmpty) {
      return null;
    }
    Cliente? match;
    for (final cliente in clientes) {
      if (_normalizeClienteValue(cliente.nombreCompleto) == normalizedValue) {
        if (match != null) {
          return null;
        }
        match = cliente;
      }
    }
    return match;
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

  void _setClienteFieldText(String value) {
    _clienteController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _applyResolvedClienteSelection(List<Cliente> clientes, Cliente? cliente) {
    final previousSelectedCliente = _findClienteById(clientes, _selectedClienteId);
    final shouldClearField = cliente == null &&
        previousSelectedCliente != null &&
        _normalizeClienteValue(_clienteController.text) ==
            _normalizeClienteValue(previousSelectedCliente.nombreCompleto);

    setState(() {
      _showAllClienteSuggestions = false;
      _selectedClienteId = cliente?.id;
    });
    if (cliente != null) {
      _setClienteFieldText(cliente.nombreCompleto);
    } else if (shouldClearField) {
      _setClienteFieldText('');
    }
  }

  void _syncClienteField(List<Cliente> clientes) {
    final selectedCliente = _findClienteById(clientes, _selectedClienteId);
    if (selectedCliente == null) {
      if (_selectedClienteId != null) {
        _selectedClienteId = null;
      }
      _setClienteFieldText('');
      return;
    }
    _setClienteFieldText(selectedCliente.nombreCompleto);
  }

  String _normalizeClienteValue(String value) {
    const replacements = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ç': 'c',
      'ñ': 'n',
    };

    final normalized = StringBuffer();
    for (final rune in value.trim().toLowerCase().runes) {
      if (rune >= 0x0300 && rune <= 0x036F) {
        continue;
      }
      final character = String.fromCharCode(rune);
      normalized.write(replacements[character] ?? character);
    }
    return normalized.toString();
  }
}
