import 'package:flutter_test/flutter_test.dart';
import 'package:pitbox_control/features/configuracion/taller/domain/models/taller_info.dart';
import 'package:pitbox_control/features/configuracion/taller/domain/utils/taller_info_validator.dart';
import 'package:pitbox_control/features/proformas/domain/models/proforma.dart';

void main() {
  test('proforma totalFinal usa subtotal y descuento persistidos', () {
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
          descripcion: 'Servicio',
          cantidad: 1,
          precioUnitario: 100,
        ),
      ],
      facturado: false,
      subtotal: 100,
      descuentoNoFacturado: 16,
      total: 84,
      fechaCreacion: DateTime(2026, 1, 1),
    );

    expect(proforma.subtotalFinal, 100);
    expect(proforma.descuentoNoFacturadoFinal, 16);
    expect(proforma.totalFinal, 84);
  });

  test('validador de taller exige nombre distinto al valor por defecto', () {
    expect(tallerInfoPermiteCrearProformas(null), isFalse);
    expect(
      tallerInfoPermiteCrearProformas(
        TallerInfo(id: '1', nombre: 'Mi Taller', fechaActualizacion: DateTime(2026, 1, 1)),
      ),
      isFalse,
    );
    expect(
      tallerInfoPermiteCrearProformas(
        TallerInfo(id: '1', nombre: 'Pitbox Racing', fechaActualizacion: DateTime(2026, 1, 1)),
      ),
      isTrue,
    );
  });
}
