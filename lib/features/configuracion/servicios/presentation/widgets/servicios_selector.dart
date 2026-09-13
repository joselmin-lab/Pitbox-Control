import 'package:flutter/material.dart';

import '../../domain/models/servicio.dart';

class ServiciosSelector extends StatefulWidget {
  const ServiciosSelector({
    required this.servicios,
    required this.seleccion,
    required this.onChanged,
    super.key,
  });

  final List<Servicio> servicios;
  final Map<String, int> seleccion;
  final ValueChanged<Map<String, int>> onChanged;

  @override
  State<ServiciosSelector> createState() => _ServiciosSelectorState();
}

class _ServiciosSelectorState extends State<ServiciosSelector> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.servicios.isEmpty) {
      return const Text('No hay servicios disponibles para asociar.');
    }

    final query = _searchQuery.trim().toLowerCase();
    final serviciosFiltrados = widget.servicios.where((servicio) {
      if (query.isEmpty) {
        return true;
      }
      final nombre = servicio.nombre.toLowerCase();
      final categoria = (servicio.categoria ?? '').toLowerCase();
      return nombre.contains(query) || categoria.contains(query);
    }).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Buscar servicio',
            hintText: 'Nombre o categoría',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: 8),
        if (serviciosFiltrados.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No se encontraron servicios.'),
          )
        else
          for (final servicio in serviciosFiltrados)
            CheckboxListTile(
              value: widget.seleccion.containsKey(servicio.id),
              title: Text(servicio.nombre),
              subtitle: Text(
                '${servicio.categoria ?? 'Sin categoría'} • ${_formatBs(servicio.precio)}',
              ),
              controlAffinity: ListTileControlAffinity.leading,
              secondary: widget.seleccion.containsKey(servicio.id)
                  ? Semantics(
                      label: 'Cantidad del servicio ${servicio.nombre}',
                      child: DropdownButton<int>(
                        value: widget.seleccion[servicio.id] ?? 1,
                        items: [
                          for (var cantidad = 1; cantidad <= 20; cantidad++)
                            DropdownMenuItem<int>(
                              value: cantidad,
                              child: Text('x$cantidad'),
                            ),
                        ],
                        onChanged: (cantidad) {
                          if (cantidad == null) {
                            return;
                          }
                          final next = Map<String, int>.from(widget.seleccion);
                          next[servicio.id] = cantidad;
                          widget.onChanged(next);
                        },
                      ),
                    )
                  : null,
              onChanged: (selected) {
                final next = Map<String, int>.from(widget.seleccion);
                if (selected == true) {
                  next[servicio.id] = next[servicio.id] ?? 1;
                } else {
                  next.remove(servicio.id);
                }
                widget.onChanged(next);
              },
            ),
      ],
    );
  }

  String _formatBs(double value) {
    return 'Bs. ${value.toStringAsFixed(2)}';
  }
}
