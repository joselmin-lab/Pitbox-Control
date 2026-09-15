import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pitbox_control/features/configuracion/taller/domain/utils/logo_image_validator.dart';

void main() {
  test('acepta firmas válidas png/jpg/webp', () {
    final png = <int>[0x89, 0x50, 0x4E, 0x47, 0x00];
    final jpg = <int>[0xFF, 0xD8, 0xFF, 0x00];
    final webp = <int>[
      0x52,
      0x49,
      0x46,
      0x46,
      0x00,
      0x00,
      0x00,
      0x00,
      0x57,
      0x45,
      0x42,
      0x50,
    ];

    expect(detectLogoImageType(Uint8List.fromList(png)), LogoImageType.png);
    expect(detectLogoImageType(Uint8List.fromList(jpg)), LogoImageType.jpeg);
    expect(detectLogoImageType(Uint8List.fromList(webp)), LogoImageType.webp);
  });

  test('rechaza extensión o firma inválida', () {
    final bytes = <int>[0x25, 0x50, 0x44, 0x46];
    expect(detectLogoImageType(Uint8List.fromList(bytes)), isNull);
  });

  test('rechaza archivos vacíos antes de intentar subirlos', () {
    expect(
      () => validateImageBytesNotEmpty(Uint8List(0)),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          emptyImageUploadErrorMessage,
        ),
      ),
    );
  });

  test('valida coincidencia entre extensión y tipo detectado', () {
    expect(doesLogoExtensionMatchType('png', LogoImageType.png), isTrue);
    expect(doesLogoExtensionMatchType('png', LogoImageType.webp), isFalse);
    expect(doesLogoExtensionMatchType('jpeg', LogoImageType.jpeg), isTrue);
    expect(doesLogoExtensionMatchType('jpg', LogoImageType.jpeg), isTrue);
  });

  test('extrae extensión de nombre de archivo', () {
    expect(extractLogoExtension('logo.png'), 'png');
    expect(extractLogoExtension('logo.final.jpeg'), 'jpeg');
    expect(extractLogoExtension('logo'), isNull);
    expect(extractLogoExtension('logo.'), isNull);
  });
}
