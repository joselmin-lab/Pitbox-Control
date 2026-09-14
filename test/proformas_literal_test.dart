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
  });
}
