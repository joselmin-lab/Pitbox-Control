import 'package:flutter/material.dart';

import '../../domain/models/servicio.dart';

class ServiciosSelector extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (servicios.isEmpty) {
      return const Text('No hay servicios disponibles para asociar.');
    }

    return Column(
      children: [
        for (final servicio in servicios)
          CheckboxListTile(
            value: seleccion.containsKey(servicio.id),
            title: Text(servicio.nombre),
            subtitle: Text(
              '${servicio.categoria ?? 'Sin categoría'} • ${_formatBs(servicio.precio)}',
            ),
            controlAffinity: ListTileControlAffinity.leading,
            secondary: seleccion.containsKey(servicio.id)
                ? Semantics(
                    label: 'Cantidad del servicio ${servicio.nombre}',
                    child: DropdownButton<int>(
                      value: seleccion[servicio.id] ?? 1,
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
                        final next = Map<String, int>.from(seleccion);
                        next[servicio.id] = cantidad;
                        onChanged(next);
                      },
                    ),
                  )
                : null,
            onChanged: (selected) {
              final next = Map<String, int>.from(seleccion);
              if (selected == true) {
                next[servicio.id] = next[servicio.id] ?? 1;
              } else {
                next.remove(servicio.id);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }

  String _formatBs(double value) {
    return 'Bs. ${value.toStringAsFixed(2)}';
  }
}
