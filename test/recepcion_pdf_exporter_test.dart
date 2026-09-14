import 'package:flutter_test/flutter_test.dart';
import 'package:pitbox_control/features/trabajos/recepciones/domain/models/recepcion_vehiculo.dart';
import 'package:pitbox_control/features/trabajos/recepciones/presentation/utils/recepcion_pdf_exporter.dart';

void main() {
  test('generarBytes crea un PDF válido con datos mínimos de recepción', () async {
    final recepcion = RecepcionVehiculo(
      id: 'r1',
      numero: '001-2026',
      clienteId: 'c1',
      vehiculoId: 'v1',
      fechaIngreso: DateTime(2026, 1, 5),
      fechaSalidaEstimada: DateTime(2026, 1, 6),
      kilometraje: '120000',
      trabajoARealizar: 'Inspección general',
      observaciones: 'Cliente deja documentos en guantera',
      fechaCreacion: DateTime(2026, 1, 5),
    );

    final bytes = await RecepcionPdfExporter.generarBytes(
      recepcion: recepcion,
      cliente: null,
      vehiculo: null,
      taller: null,
    );

    expect(bytes, isNotEmpty);
  });
}
