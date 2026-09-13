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

  test('actualizarLogo mantiene nombre y contacto existentes', () async {
    final repository = _TallerRepositoryFake(
      TallerInfo(
        id: 'taller-1',
        nombre: 'Pitbox Centro',
        direccion: 'Av. Principal 123',
        telefono: '70012345',
        correo: 'info@pitbox.com',
        logoUrl: 'https://example.com/taller-logos/old-logo.png',
        fechaActualizacion: DateTime(2026, 1, 1),
      ),
    );
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container.read(tallerInfoProvider.future);
    await container.read(tallerInfoProvider.notifier).actualizarLogo(
          Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]),
          'logo.png',
        );

    final info = container.read(tallerInfoProvider).valueOrNull!;
    expect(info.nombre, 'Pitbox Centro');
    expect(info.direccion, 'Av. Principal 123');
    expect(info.telefono, '70012345');
    expect(info.correo, 'info@pitbox.com');
    expect(info.logoUrl, 'https://example.com/taller-logos/logo.png');
    expect(repository.lastDeletedLogoUrl, 'https://example.com/taller-logos/old-logo.png');
  });

  test('actualizarLogo propaga error si falla subirLogo sin alterar estado', () async {
    final repository = _TallerRepositoryFake(TallerInfo.vacio(), failOnUpload: true);
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    final before = await container.read(tallerInfoProvider.future);

    await expectLater(
      container.read(tallerInfoProvider.notifier).actualizarLogo(
            Uint8List.fromList([1, 2, 3]),
            'logo.png',
          ),
      throwsA(isA<StateError>()),
    );

    final after = container.read(tallerInfoProvider).valueOrNull!;
    expect(after.logoUrl, before.logoUrl);
    expect(after.nombre, before.nombre);
    expect(repository.lastDeletedLogoUrl, isNull);
  });

  test('actualizarLogo propaga error si falla guardarInfo sin alterar estado', () async {
    final repository = _TallerRepositoryFake(TallerInfo.vacio(), failOnSave: true);
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    final before = await container.read(tallerInfoProvider.future);

    await expectLater(
      container.read(tallerInfoProvider.notifier).actualizarLogo(
            Uint8List.fromList([1, 2, 3]),
            'logo.png',
          ),
      throwsA(isA<StateError>()),
    );

    final after = container.read(tallerInfoProvider).valueOrNull!;
    expect(after.logoUrl, before.logoUrl);
    expect(after.nombre, before.nombre);
    expect(repository.lastDeletedLogoUrl, 'https://example.com/taller-logos/logo.png');
  });

  test('serializa guardar y actualizarLogo para evitar pisar estado', () async {
    final repository = _TallerRepositoryFake(
      TallerInfo.vacio(),
      uploadDelay: const Duration(milliseconds: 10),
      saveDelay: const Duration(milliseconds: 10),
    );
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container.read(tallerInfoProvider.future);

    final updateFuture = container.read(tallerInfoProvider.notifier).actualizarLogo(
          Uint8List.fromList([1, 2, 3]),
          'logo.png',
        );
    final saveFuture = container.read(tallerInfoProvider.notifier).guardar(
          nombre: 'Pitbox Serializado',
          direccion: 'Zona Norte',
          telefono: '',
          correo: '',
        );

    await Future.wait([updateFuture, saveFuture]);

    final info = container.read(tallerInfoProvider).valueOrNull!;
    expect(info.logoUrl, 'https://example.com/taller-logos/logo.png');
    expect(info.nombre, 'Pitbox Serializado');
    expect(repository.calls, ['upload:logo.png', 'save:Mi Taller', 'save:Pitbox Serializado']);
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
  _TallerRepositoryFake(
    this._info, {
    this.failOnUpload = false,
    this.failOnSave = false,
    this.uploadDelay = Duration.zero,
    this.saveDelay = Duration.zero,
  });

  TallerInfo _info;
  final bool failOnUpload;
  final bool failOnSave;
  final Duration uploadDelay;
  final Duration saveDelay;
  String? lastUploadFileName;
  String? lastDeletedLogoUrl;
  final List<String> calls = <String>[];

  @override
  Future<TallerInfo> getInfo() async => _info;

  @override
  Future<TallerInfo> guardarInfo(TallerInfo info) async {
    if (saveDelay > Duration.zero) {
      await Future<void>.delayed(saveDelay);
    }
    if (failOnSave) {
      throw StateError('save failed');
    }
    calls.add('save:${info.nombre}');
    _info = info.copyWith(
      id: info.id.isEmpty ? 'taller-1' : info.id,
      fechaActualizacion: DateTime(2026, 1, 2),
    );
    return _info;
  }

  @override
  Future<String> subirLogo(Uint8List bytes, String nombreArchivo) async {
    if (uploadDelay > Duration.zero) {
      await Future<void>.delayed(uploadDelay);
    }
    if (failOnUpload) {
      throw StateError('upload failed');
    }
    calls.add('upload:$nombreArchivo');
    lastUploadFileName = nombreArchivo;
    return 'https://example.com/taller-logos/$nombreArchivo';
  }

  @override
  Future<void> eliminarLogoPorUrl(String logoUrl) async {
    lastDeletedLogoUrl = logoUrl;
  }
}
