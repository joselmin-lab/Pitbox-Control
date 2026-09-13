import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitbox_control/features/configuracion/taller/domain/models/taller_info.dart';
import 'package:pitbox_control/features/configuracion/taller/domain/repositories/taller_repository.dart';
import 'package:pitbox_control/features/configuracion/taller/presentation/providers/taller_info_provider.dart';
import 'package:pitbox_control/shared/providers/repository_providers.dart';

void main() {
  test('tallerInfoProvider carga info inicial', () async {
    final repository = _TallerRepositoryFake(
      TallerInfo(
        id: 'taller-1',
        nombre: 'Taller Central',
        fechaActualizacion: DateTime(2026, 1, 1),
      ),
    );
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    final info = await container.read(tallerInfoProvider.future);
    expect(info.nombre, 'Taller Central');
  });

  test('guardar actualiza campos de texto y limpia opcionales vacíos', () async {
    final repository = _TallerRepositoryFake(TallerInfo.vacio());
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container.read(tallerInfoProvider.future);
    await container.read(tallerInfoProvider.notifier).guardar(
          nombre: '  Pitbox Norte ',
          direccion: '',
          telefono: ' 70000000 ',
          correo: ' contacto@pitbox.com ',
        );

    final info = container.read(tallerInfoProvider).valueOrNull!;
    expect(info.nombre, 'Pitbox Norte');
    expect(info.direccion, isNull);
    expect(info.telefono, '70000000');
    expect(info.correo, 'contacto@pitbox.com');
  });

  test('actualizarLogo sube archivo y persiste logoUrl', () async {
    final repository = _TallerRepositoryFake(TallerInfo.vacio());
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container.read(tallerInfoProvider.future);
    await container.read(tallerInfoProvider.notifier).actualizarLogo(
          Uint8List.fromList([1, 2, 3]),
          'logo.png',
        );

    final info = container.read(tallerInfoProvider).valueOrNull!;
    expect(info.logoUrl, 'https://example.com/taller-logos/logo.png');
    expect(repository.lastUploadFileName, 'logo.png');
  });
}

ProviderContainer _buildContainer(TallerRepository repository) {
  return ProviderContainer(
    overrides: [
      tallerRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

class _TallerRepositoryFake implements TallerRepository {
  _TallerRepositoryFake(this._info);

  TallerInfo _info;
  String? lastUploadFileName;

  @override
  Future<TallerInfo> getInfo() async => _info;

  @override
  Future<TallerInfo> guardarInfo(TallerInfo info) async {
    _info = info.copyWith(
      id: info.id.isEmpty ? 'taller-1' : info.id,
      fechaActualizacion: DateTime(2026, 1, 2),
    );
    return _info;
  }

  @override
  Future<String> subirLogo(Uint8List bytes, String nombreArchivo) async {
    lastUploadFileName = nombreArchivo;
    return 'https://example.com/taller-logos/$nombreArchivo';
  }
}
