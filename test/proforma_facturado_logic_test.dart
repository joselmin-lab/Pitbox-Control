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

  test('proforma totalFinal usa fallback subtotal - descuento cuando total no existe', () {
    final proforma = Proforma(
      id: 'p2',
      numero: '002-2026',
      clienteId: 'c1',
      vehiculoId: 'v1',
      fecha: DateTime(2026, 1, 1),
      items: const [],
      facturado: false,
      subtotal: 200,
      descuentoNoFacturado: 32,
      total: null,
      fechaCreacion: DateTime(2026, 1, 1),
    );

    expect(proforma.totalFinal, 168);
  });

  test('subtotalFinal usa suma de items cuando subtotal es null', () {
    final proforma = Proforma(
      id: 'p3',
      numero: '003-2026',
      clienteId: 'c1',
      vehiculoId: 'v1',
      fecha: DateTime(2026, 1, 1),
      items: const [
        ProformaItem(
          id: 'i1',
          tipoItem: ProformaItemTipo.repuestoInsumo,
          descripcion: 'Repuesto',
          cantidad: 2,
          precioUnitario: 50,
        ),
      ],
      facturado: true,
      subtotal: null,
      descuentoNoFacturado: null,
      total: null,
      fechaCreacion: DateTime(2026, 1, 1),
    );

    expect(proforma.subtotalFinal, 100);
    expect(proforma.totalFinal, 100);
  });

  test('validador de taller exige nombre y al menos teléfono o correo', () {
    expect(tallerInfoPermiteCrearProformas(null), isFalse);
    expect(
      tallerInfoPermiteCrearProformas(
        TallerInfo(id: '1', nombre: '   ', telefono: '70000000', fechaActualizacion: DateTime(2026, 1, 1)),
      ),
      isFalse,
    );
    expect(
      tallerInfoPermiteCrearProformas(
        TallerInfo(id: '1', nombre: 'Taller A', fechaActualizacion: DateTime(2026, 1, 1)),
      ),
      isFalse,
    );
    expect(
      tallerInfoPermiteCrearProformas(
        TallerInfo(
          id: '1',
          nombre: 'Pitbox Racing',
          telefono: '   ',
          fechaActualizacion: DateTime(2026, 1, 1),
        ),
      ),
      isFalse,
    );
    expect(
      tallerInfoPermiteCrearProformas(
        TallerInfo(
          id: '1',
          nombre: 'Pitbox Racing',
          telefono: '70000000',
          fechaActualizacion: DateTime(2026, 1, 1),
        ),
      ),
      isTrue,
    );
    expect(
      tallerInfoPermiteCrearProformas(
        TallerInfo(
          id: '1',
          nombre: 'Pitbox Racing',
          correo: '   ',
          fechaActualizacion: DateTime(2026, 1, 1),
        ),
      ),
      isFalse,
    );
    expect(
      tallerInfoPermiteCrearProformas(
        TallerInfo(
          id: '1',
          nombre: 'Pitbox Racing',
          correo: 'taller@pitbox.com',
          fechaActualizacion: DateTime(2026, 1, 1),
        ),
      ),
      isTrue,
    );
  });
}
