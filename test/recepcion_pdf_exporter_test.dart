import 'package:pitbox_control/features/configuracion/taller/domain/models/taller_info.dart';
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

  test('generarBytes tolera logo, firmas y fotos remotas inválidas sin fallar', () async {
    final recepcion = RecepcionVehiculo(
      id: 'r1',
      numero: '002-2026',
      clienteId: 'c1',
      vehiculoId: 'v1',
      fechaIngreso: DateTime(2026, 1, 5),
      fechaSalidaEstimada: DateTime(2026, 1, 6),
      kilometraje: '120000',
      trabajoARealizar: 'Inspección general',
      observaciones: 'Con fotografías y firmas remotas',
      fotografias: const ['not-a-valid-image-url'],
      firmaPrestadorUrl: 'not-a-valid-signature-url',
      firmaClienteUrl: 'not-a-valid-signature-url-2',
      fechaCreacion: DateTime(2026, 1, 5),
    );

    final bytes = await RecepcionPdfExporter.generarBytes(
      recepcion: recepcion,
      cliente: null,
      vehiculo: null,
      taller: TallerInfo(
        id: 't1',
        nombre: 'Pitbox Control',
        logoUrl: 'not-a-valid-logo-url',
        fechaActualizacion: DateTime(2026, 1, 5),
      ),
    );

    expect(bytes, isNotEmpty);
  });
}
