import 'package:flutter_test/flutter_test.dart';
import 'package:pitbox_control/features/proformas/domain/models/proforma.dart';
import 'package:pitbox_control/features/proformas/presentation/utils/proforma_pdf_exporter.dart';

void main() {
  test('generarBytes crea un PDF válido con datos mínimos', () async {
    final proforma = Proforma(
      id: 'p1',
      numero: '001-2026',
      clienteId: 'c1',
      vehiculoId: 'v1',
      fecha: DateTime(2026, 1, 1),
      items: const [
        ProformaItem(
          id: 'i1',
          tipoItem: ProformaItemTipo.servicio,
          descripcion: 'Cambio de aceite',
          cantidad: 1,
          precioUnitario: 100,
        ),
      ],
      estado: ProformaEstado.borrador,
      fechaCreacion: DateTime(2026, 1, 1),
    );

    final bytes = await ProformaPdfExporter.generarBytes(
      proforma: proforma,
      cliente: null,
      vehiculo: null,
      taller: null,
    );

    expect(bytes, isNotEmpty);
  });
}
