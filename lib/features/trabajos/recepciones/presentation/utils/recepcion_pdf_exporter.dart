import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../clientes/domain/models/cliente.dart';
import '../../../../configuracion/taller/domain/models/taller_info.dart';
import '../../../../vehiculos/domain/models/vehiculo.dart';
import '../../domain/models/recepcion_vehiculo.dart';
import '../widgets/vehicle_damage_silhouettes.dart';

class RecepcionPdfExporter {
  const RecepcionPdfExporter._();

  static Future<void> exportar({
    required RecepcionVehiculo recepcion,
    required Cliente? cliente,
    required Vehiculo? vehiculo,
    required TallerInfo? taller,
  }) async {
    final bytes = await generarBytes(
      recepcion: recepcion,
      cliente: cliente,
      vehiculo: vehiculo,
      taller: taller,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<Uint8List> generarBytes({
    required RecepcionVehiculo recepcion,
    required Cliente? cliente,
    required Vehiculo? vehiculo,
    required TallerInfo? taller,
  }) async {
    final pdf = pw.Document();
    final logo = await _loadImage(taller?.logoUrl);
    final firmaPrestador = await _loadImage(recepcion.firmaPrestadorUrl);
    final firmaCliente = await _loadImage(recepcion.firmaClienteUrl);
    final fotos = await Future.wait(
      recepcion.fotografias.take(4).map(_loadImage),
    );
    final danosSvgs = await loadVehicleDamageSilhouettesSvg();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.Center(
              child: pw.Text(
                'RECEPCIÓN DE VEHÍCULOS',
                style: pw.TextStyle(
                  color: PdfColors.red700,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            if (logo != null) pw.Center(child: pw.Image(logo, width: 82, height: 82)),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                taller?.nombre.trim().isNotEmpty == true ? taller!.nombre.trim() : 'Pitbox Control',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Center(
              child: pw.Text(
                [taller?.direccion, taller?.telefono, taller?.correo]
                    .where((item) => item != null && item.trim().isNotEmpty)
                    .join(' · '),
                style: const pw.TextStyle(fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 14),
            _band('DATOS DEL CLIENTE'),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: const {
                0: pw.FlexColumnWidth(),
                1: pw.FlexColumnWidth(),
              },
              children: [
                _row('Marca', vehiculo?.marca ?? '—', 'Ingreso', _formatDate(recepcion.fechaIngreso)),
                _row('Modelo', vehiculo?.modelo ?? '—', 'Color', vehiculo?.color ?? '—'),
                _row('Salida', _formatDate(recepcion.fechaSalidaEstimada), 'Kilometraje', recepcion.kilometraje ?? '—'),
                _row('Placas', vehiculo?.placa ?? '—', 'Nombre', cliente?.nombreCompleto ?? '—'),
                _row('Año', vehiculo == null ? '—' : vehiculo.anio.toString(), 'Teléfono', cliente?.telefono ?? '—'),
                _row('Ingreso en grúa', recepcion.ingresoEnGrua ? 'Sí' : 'No', 'Email', cliente?.email ?? '—'),
              ],
            ),
            pw.SizedBox(height: 12),
            _band('TRABAJO A REALIZAR'),
            _multilineValue(recepcion.trabajoARealizar),
            pw.SizedBox(height: 10),
            _band('OBSERVACIONES'),
            _multilineValue(recepcion.observaciones),
            pw.SizedBox(height: 10),
            _band('SISTEMAS'),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in recepcion.checklistSistemas)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: item.marcado ? PdfColors.red700 : PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.Text(
                      item.etiqueta,
                      style: pw.TextStyle(
                        color: item.marcado ? PdfColors.white : PdfColors.black,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 10),
            _band('INVENTARIO'),
            pw.SizedBox(height: 6),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      for (final item in recepcion.inventario)
                        pw.SizedBox(
                          width: 170,
                          child: pw.Row(
                            children: [
                              pw.Text(item.marcado ? '☑' : '☐'),
                              pw.SizedBox(width: 6),
                              pw.Expanded(child: pw.Text(item.item, style: const pw.TextStyle(fontSize: 10))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Combustible', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          for (var index = 0; index < 4; index++) ...[
                            pw.Expanded(
                              child: pw.Container(
                                height: 12,
                                decoration: pw.BoxDecoration(
                                  color: recepcion.nivelCombustible.clamp(0.0, 1.0) >= ((index + 1) / 4)
                                      ? PdfColors.red700
                                      : PdfColors.grey200,
                                  border: pw.Border.all(color: PdfColors.grey500),
                                ),
                              ),
                            ),
                            if (index < 3) pw.SizedBox(width: 4),
                          ],
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('E'),
                          pw.Spacer(),
                          pw.Text('F'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            _band('DAÑOS PREEXISTENTES'),
            pw.SizedBox(height: 6),
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final vista in RecepcionVistaVehiculo.values)
                  _damageBox(
                    vista.label,
                    danosSvgs[vista] ?? '',
                    recepcion.danosPreexistentes.where((item) => item.vista == vista).toList(growable: false),
                  ),
              ],
            ),
            if (fotos.any((item) => item != null)) ...[
              pw.SizedBox(height: 10),
              _band('FOTOGRAFÍAS'),
              pw.SizedBox(height: 6),
              pw.Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final foto in fotos)
                    if (foto != null)
                      pw.Container(
                        width: 120,
                        height: 90,
                        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                        child: pw.Image(foto, fit: pw.BoxFit.cover),
                      ),
                ],
              ),
            ],
            pw.SizedBox(height: 16),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: _signatureBlock('FIRMA DEL PRESTADOR DEL SERVICIO', firmaPrestador)),
                pw.SizedBox(width: 20),
                pw.Expanded(child: _signatureBlock('FIRMA DEL CLIENTE', firmaCliente)),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _band(String title) {
    return pw.Container(
      width: double.infinity,
      color: PdfColors.red700,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.TableRow _row(String label1, String value1, String label2, String value2) {
    return pw.TableRow(
      children: [
        _tableCell(label1, value1),
        _tableCell(label2, value2),
      ],
    );
  }

  static pw.Widget _tableCell(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.RichText(
        text: pw.TextSpan(
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
          children: [
            pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.TextSpan(text: value.trim().isEmpty ? '—' : value.trim()),
          ],
        ),
      ),
    );
  }

  static pw.Widget _multilineValue(String? value) {
    final text = (value == null || value.trim().isEmpty) ? '—' : value.trim();
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
      child: pw.Text(text),
    );
  }

  static pw.Widget _damageBox(String title, String svg, List<DanoVehiculoMarcado> puntos) {
    const width = 120.0;
    const height = 90.0;
    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
          pw.SizedBox(height: 4),
          pw.Container(
            width: width,
            height: height,
            color: PdfColors.grey100,
            child: pw.Stack(
              children: [
                pw.Center(
                  child: svg.trim().isEmpty
                      ? pw.Text(
                          title,
                          style: pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
                          textAlign: pw.TextAlign.center,
                        )
                      : pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.SvgImage(
                            svg: svg,
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                ),
                for (final punto in puntos)
                  pw.Positioned(
                    left: ((punto.x.clamp(0.0, 1.0) * (width - 10)).toDouble()),
                    top: ((punto.y.clamp(0.0, 1.0) * (height - 10)).toDouble()),
                    child: pw.Container(
                      width: 8,
                      height: 8,
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.red700,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _signatureBlock(String title, pw.ImageProvider? signature) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.SizedBox(height: 8),
        pw.Container(
          height: 90,
          decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black))),
          child: signature == null
              ? pw.SizedBox.expand()
              : pw.Align(
                  alignment: pw.Alignment.bottomCenter,
                  child: pw.Image(signature, height: 80, fit: pw.BoxFit.contain),
                ),
        ),
      ],
    );
  }

  static Future<pw.ImageProvider?> _loadImage(String? url) async {
    if (url == null || url.trim().isEmpty) {
      return null;
    }
    try {
      return await networkImage(url.trim());
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static String _formatDate(DateTime? value) {
    if (value == null) {
      return '—';
    }
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}
