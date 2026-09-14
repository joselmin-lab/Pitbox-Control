import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../clientes/domain/models/cliente.dart';
import '../../../configuracion/taller/domain/models/taller_info.dart';
import '../../../vehiculos/domain/models/vehiculo.dart';
import '../../domain/models/proforma.dart';
import '../../domain/utils/numero_a_literal_es.dart';

class ProformaPdfExporter {
  const ProformaPdfExporter._();

  static Future<void> exportar({
    required Proforma proforma,
    required Cliente? cliente,
    required Vehiculo? vehiculo,
    required TallerInfo? taller,
  }) async {
    final bytes = await generarBytes(
      proforma: proforma,
      cliente: cliente,
      vehiculo: vehiculo,
      taller: taller,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<Uint8List> generarBytes({
    required Proforma proforma,
    required Cliente? cliente,
    required Vehiculo? vehiculo,
    required TallerInfo? taller,
  }) async {
    final pdf = pw.Document();
    final logo = await _loadLogo(taller?.logoUrl);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.Center(
              child: pw.Text(
                '★ PROFORMA ★',
                style: pw.TextStyle(color: PdfColors.red700, fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 8),
            if (logo != null) pw.Center(child: pw.Image(logo, width: 90, height: 90, fit: pw.BoxFit.contain)),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                [taller?.direccion, taller?.telefono, taller?.correo].where((item) => item != null && item!.isNotEmpty).join(' · '),
                style: const pw.TextStyle(fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _label('CLIENTE'),
                      pw.Text('${cliente?.nombreCompleto ?? '—'}'),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        vehiculo == null
                            ? 'Vehículo: —'
                            : 'Vehículo: ${vehiculo.placa} / ${vehiculo.marca} ${vehiculo.modelo} (${vehiculo.anio})',
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _label('N° PROFORMA'),
                    pw.Text(proforma.numero),
                    pw.SizedBox(height: 6),
                    _label('FECHA'),
                    pw.Text(_formatDate(proforma.fecha)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: const {
                0: pw.FixedColumnWidth(45),
                1: pw.FlexColumnWidth(),
                2: pw.FixedColumnWidth(90),
                3: pw.FixedColumnWidth(80),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.red700),
                  children: [
                    _cellHeader('Cant.'),
                    _cellHeader('Descripción'),
                    _cellHeader('Precio unitario'),
                    _cellHeader('Total'),
                  ],
                ),
                ...proforma.items.map(
                  (item) => pw.TableRow(
                    children: [
                      _cell(item.cantidad.toStringAsFixed(2)),
                      _cell(item.descripcion),
                      _cell(_formatBs(item.precioUnitario)),
                      _cell(_formatBs(item.total)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                montoEnLiteralBolivianos(proforma.totalFinal),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    color: PdfColors.red700,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: pw.Text('TOTAL', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                    child: pw.Text(_formatBs(proforma.totalFinal), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            _section('CONDICIONES Y FORMA DE PAGO:', proforma.condicionesPago),
            _section('VALIDEZ DE LA PROFORMA:', proforma.validez),
            _section('TIEMPO DE ENTREGA:', proforma.tiempoEntrega),
            _section('TIEMPO DE GARANTÍA:', proforma.tiempoGarantia),
            _section('FORMA DE PAGO:', proforma.formaPago),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _label(String value) {
    return pw.Text(value, style: pw.TextStyle(color: PdfColors.red700, fontWeight: pw.FontWeight.bold));
  }

  static pw.Widget _cellHeader(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(value, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _cell(String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  static pw.Widget _section(String label, String? content) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: '$label ', style: pw.TextStyle(color: PdfColors.red700, fontWeight: pw.FontWeight.bold)),
            pw.TextSpan(text: content?.trim().isNotEmpty == true ? content!.trim() : '—'),
          ],
        ),
      ),
    );
  }

  static Future<pw.ImageProvider?> _loadLogo(String? logoUrl) async {
    if (logoUrl == null || logoUrl.trim().isEmpty) {
      return null;
    }
    try {
      return await networkImage(logoUrl.trim());
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  static String _formatBs(double value) => 'Bs. ${value.toStringAsFixed(2)}';
}
