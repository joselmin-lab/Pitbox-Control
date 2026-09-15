import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/models/recepcion_vehiculo.dart';
import 'vehicle_damage_silhouettes.dart';

class DamageDiagram extends StatelessWidget {
  const DamageDiagram({
    required this.title,
    required this.vista,
    required this.puntos,
    this.onTapPunto,
    this.onClear,
    this.onUndo,
    super.key,
  });

  final String title;
  final RecepcionVistaVehiculo vista;
  final List<DanoVehiculoMarcado> puntos;
  final ValueChanged<Offset>? onTapPunto;
  final VoidCallback? onClear;
  final VoidCallback? onUndo;

  bool get _interactive => onTapPunto != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (_interactive && onUndo != null)
                IconButton(
                  tooltip: 'Quitar último punto',
                  onPressed: onUndo,
                  icon: const Icon(Icons.undo_rounded),
                ),
              if (_interactive && onTapPunto != null)
                IconButton(
                  tooltip: 'Agregar punto centrado',
                  onPressed: () => onTapPunto?.call(const Offset(0.5, 0.5)),
                  icon: const Icon(Icons.add_location_alt_rounded),
                ),
              if (_interactive && onClear != null)
                IconButton(
                  tooltip: 'Limpiar vista',
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_sweep_rounded),
                ),
            ],
          ),
          Text(
            _interactive ? 'Toca para marcar daños preexistentes.' : 'Vista registrada.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              const height = 160.0;
              final content = SizedBox(
                width: width,
                height: height,
                child: Stack(
                  children: [
                    Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: SvgPicture.asset(
                          vehicleDamageSilhouetteAssetFor(vista),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    for (final punto in puntos)
                      Positioned(
                        left: (punto.x.clamp(0.0, 1.0) * (width - 14)).toDouble(),
                        top: (punto.y.clamp(0.0, 1.0) * (height - 14)).toDouble(),
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.close_rounded, size: 10, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              );

              if (!_interactive) {
                return content;
              }

              return Semantics(
                label: 'Diagrama de daños $title',
                value: puntos.isEmpty ? 'Sin puntos marcados' : '${puntos.length} puntos marcados',
                hint: 'Toca el diagrama para registrar un daño o usa el botón agregar punto centrado.',
                child: GestureDetector(
                  onTapDown: (details) {
                    final dx = (details.localPosition.dx / width).clamp(0.0, 1.0);
                    final dy = (details.localPosition.dy / height).clamp(0.0, 1.0);
                    onTapPunto?.call(Offset(dx.toDouble(), dy.toDouble()));
                  },
                  child: content,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

}
