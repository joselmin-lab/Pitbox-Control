String montoEnLiteralBolivianos(double valor) {
  final totalCentavos = (valor * 100).round();
  final entero = totalCentavos ~/ 100;
  final centavos = totalCentavos % 100;
  final literal = _numeroALetras(entero);
  final centavosTexto = centavos.toString().padLeft(2, '0');
  return '${_capitalizar(literal)} $centavosTexto/100 bolivianos';
}

String _numeroALetras(int numero) {
  if (numero == 0) {
    return 'cero';
  }
  if (numero < 0) {
    return 'menos ${_numeroALetras(numero.abs())}';
  }

  final millones = numero ~/ 1000000;
  final miles = (numero % 1000000) ~/ 1000;
  final resto = numero % 1000;

  final partes = <String>[];
  if (millones > 0) {
    if (millones == 1) {
      partes.add('un millón');
    } else {
      partes.add('${_convertirHasta999(millones)} millones');
    }
  }

  if (miles > 0) {
    if (miles == 1) {
      partes.add('mil');
    } else {
      partes.add('${_convertirHasta999(miles)} mil');
    }
  }

  if (resto > 0) {
    partes.add(_convertirHasta999(resto));
  }

  return partes.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _convertirHasta999(int numero) {
  const unidades = [
    '',
    'uno',
    'dos',
    'tres',
    'cuatro',
    'cinco',
    'seis',
    'siete',
    'ocho',
    'nueve',
  ];
  const especiales = [
    'diez',
    'once',
    'doce',
    'trece',
    'catorce',
    'quince',
    'dieciséis',
    'diecisiete',
    'dieciocho',
    'diecinueve',
  ];
  const decenas = [
    '',
    '',
    'veinte',
    'treinta',
    'cuarenta',
    'cincuenta',
    'sesenta',
    'setenta',
    'ochenta',
    'noventa',
  ];
  const centenas = [
    '',
    'ciento',
    'doscientos',
    'trescientos',
    'cuatrocientos',
    'quinientos',
    'seiscientos',
    'setecientos',
    'ochocientos',
    'novecientos',
  ];

  if (numero == 0) return '';
  if (numero == 100) return 'cien';

  final c = numero ~/ 100;
  final d = (numero % 100) ~/ 10;
  final u = numero % 10;
  final dosDigitos = numero % 100;

  final partes = <String>[];
  if (c > 0) partes.add(centenas[c]);

  if (dosDigitos > 0) {
    if (dosDigitos < 10) {
      partes.add(unidades[dosDigitos]);
    } else if (dosDigitos < 20) {
      partes.add(especiales[dosDigitos - 10]);
    } else if (dosDigitos < 30) {
      if (dosDigitos == 20) {
        partes.add('veinte');
      } else {
        const veintiEspeciales = {
          21: 'veintiuno',
          22: 'veintidós',
          23: 'veintitrés',
          24: 'veinticuatro',
          25: 'veinticinco',
          26: 'veintiséis',
          27: 'veintisiete',
          28: 'veintiocho',
          29: 'veintinueve',
        };
        partes.add(veintiEspeciales[dosDigitos] ?? 'veinti${unidades[u]}');
      }
    } else {
      if (u == 0) {
        partes.add(decenas[d]);
      } else {
        partes.add('${decenas[d]} y ${unidades[u]}');
      }
    }
  }

  return partes.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _capitalizar(String texto) {
  if (texto.isEmpty) return texto;
  return texto[0].toUpperCase() + texto.substring(1);
}
