import 'package:flutter_test/flutter_test.dart';
import 'package:pitbox_control/features/configuracion/impuestos/domain/utils/impuestos_validator.dart';

void main() {
  test('parsePorcentajeImpuesto acepta coma decimal', () {
    expect(parsePorcentajeImpuesto('13,5'), 13.5);
  });

  test('validarPorcentajeImpuesto rechaza vacio e invalido', () {
    expect(validarPorcentajeImpuesto(''), isNotNull);
    expect(validarPorcentajeImpuesto('abc'), isNotNull);
  });

  test('validarPorcentajeImpuesto rechaza fuera de rango', () {
    expect(validarPorcentajeImpuesto('-1'), isNotNull);
    expect(validarPorcentajeImpuesto('101'), isNotNull);
  });

  test('validarPorcentajeImpuesto acepta valores validos', () {
    expect(validarPorcentajeImpuesto('0'), isNull);
    expect(validarPorcentajeImpuesto('100'), isNull);
    expect(validarPorcentajeImpuesto('16.5'), isNull);
  });

  test('validarSumaImpuestos rechaza suma mayor a 100', () {
    expect(
      validarSumaImpuestos(
        porcentajeIva: 80,
        porcentajeIt: 30,
      ),
      isNotNull,
    );
    expect(
      validarSumaImpuestos(
        porcentajeIva: 13,
        porcentajeIt: 3,
      ),
      isNull,
    );
  });
}
