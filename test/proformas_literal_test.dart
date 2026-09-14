import 'package:flutter_test/flutter_test.dart';
import 'package:pitbox_control/features/proformas/domain/utils/numero_a_literal_es.dart';

void main() {
  group('montoEnLiteralBolivianos', () {
    test('convierte monto con centavos', () {
      expect(
        montoEnLiteralBolivianos(998),
        'Novecientos noventa y ocho 00/100 bolivianos',
      );
    });

    test('convierte miles con centavos', () {
      expect(
        montoEnLiteralBolivianos(1523.5),
        'Mil quinientos veintitrés 50/100 bolivianos',
      );
    });

    test('redondea y acarrea centavos al entero', () {
      expect(
        montoEnLiteralBolivianos(1.999),
        'Dos 00/100 bolivianos',
      );
    });

    test('aplica apocope monetario con uno y compuestos', () {
      expect(montoEnLiteralBolivianos(1), 'Un 00/100 bolivianos');
      expect(montoEnLiteralBolivianos(21), 'Veintiún 00/100 bolivianos');
      expect(montoEnLiteralBolivianos(31), 'Treinta y un 00/100 bolivianos');
      expect(montoEnLiteralBolivianos(121), 'Ciento veintiún 00/100 bolivianos');
    });
  });
}
