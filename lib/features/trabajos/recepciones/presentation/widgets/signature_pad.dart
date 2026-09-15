import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';

class SignaturePad extends StatelessWidget {
  const SignaturePad({
    required this.title,
    required this.trazos,
    required this.onChanged,
    required this.repaintBoundaryKey,
    this.enabled = true,
    this.helperText,
    this.canvasHeight = 180,
    super.key,
  });

  final String title;
  final List<List<Offset>> trazos;
  final ValueChanged<List<List<Offset>>> onChanged;
  final GlobalKey repaintBoundaryKey;
  final bool enabled;
  final String? helperText;
  final double canvasHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (helperText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(helperText!, style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          trazos.any((stroke) => stroke.isNotEmpty) ? 'Estado: firma capturada.' : 'Estado: pendiente de firma.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          label: title,
          value: trazos.any((stroke) => stroke.isNotEmpty) ? 'Firma capturada' : 'Sin firma',
          hint: enabled
              ? 'Área para firmar con mouse o pantalla táctil. Usa el botón limpiar para volver a capturar.'
              : 'Vista previa de firma.',
          child: GestureDetector(
            onPanStart: enabled
                ? (details) {
                    onChanged([
                      ..._copyTrazos(trazos),
                      [details.localPosition],
                    ]);
                  }
                : null,
            onPanUpdate: enabled
                ? (details) {
                    final updated = _copyTrazos(trazos);
                    if (updated.isEmpty) {
                      updated.add([details.localPosition]);
                    } else {
                      updated.last = [...updated.last, details.localPosition];
                    }
                    onChanged(updated);
                  }
                : null,
            child: RepaintBoundary(
              key: repaintBoundaryKey,
              child: Container(
                height: canvasHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: CustomPaint(
                  painter: _SignaturePainter(trazos),
                  child: trazos.any((stroke) => stroke.isNotEmpty)
                      ? const SizedBox.expand()
                      : Center(
                          child: Text(
                            enabled ? 'Firma aquí' : 'Sin firma',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<List<Offset>> _copyTrazos(List<List<Offset>> source) {
    return source.map((stroke) => stroke.toList(growable: true)).toList(growable: true);
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.trazos);

  final List<List<Offset>> trazos;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = Colors.black87;

    for (final stroke in trazos) {
      if (stroke.isEmpty) {
        continue;
      }

      class SignatureThumbnail extends StatelessWidget {
        const SignatureThumbnail({
          required this.trazos,
          this.height = 110,
          super.key,
        });

        final List<List<Offset>> trazos;
        final double height;

        @override
        Widget build(BuildContext context) {
          return Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: CustomPaint(
              painter: _SignaturePainter(trazos),
              child: trazos.any((stroke) => stroke.isNotEmpty)
                  ? const SizedBox.expand()
                  : Center(
                      child: Text(
                        'Sin firma',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
            ),
          );
        }
      }
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
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return oldDelegate.trazos != trazos;
  }
}
