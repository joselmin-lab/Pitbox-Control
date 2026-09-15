import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/taller_info.dart';
import '../../domain/repositories/taller_repository.dart';
import '../../domain/utils/logo_image_validator.dart';
import '../../../../../shared/providers/repository_providers.dart';

final tallerInfoProvider = AsyncNotifierProvider<TallerInfoNotifier, TallerInfo>(() {
  return TallerInfoNotifier();
});

class TallerInfoNotifier extends AsyncNotifier<TallerInfo> {
  Future<void> _mutationQueue = Future<void>.value();

  TallerRepository get _repository => ref.read(tallerRepositoryProvider);

  @override
  Future<TallerInfo> build() async {
    return _repository.getInfo();
  }

  Future<void> guardar({
    required String nombre,
    String? direccion,
    String? telefono,
    String? correo,
  }) async {
    await _enqueueMutation(() => _guardarInternal(
          nombre: nombre,
          direccion: direccion,
          telefono: telefono,
          correo: correo,
        ));
  }

  Future<void> _guardarInternal({
    required String nombre,
    String? direccion,
    String? telefono,
    String? correo,
  }) async {
    final previous = state.valueOrNull ?? await future;
    final direccionNormalizada = _optional(direccion);
    final telefonoNormalizado = _optional(telefono);
    final correoNormalizado = _optional(correo);
    final saved = await _repository.guardarInfo(
      previous.copyWith(
        nombre: nombre.trim(),
        direccion: direccionNormalizada,
        clearDireccion: direccionNormalizada == null,
        telefono: telefonoNormalizado,
        clearTelefono: telefonoNormalizado == null,
        correo: correoNormalizado,
        clearCorreo: correoNormalizado == null,
      ),
    );
    state = AsyncData(saved);
  }

  Future<void> actualizarLogo(Uint8List bytes, String nombreArchivo) async {
    await _enqueueMutation(() => _actualizarLogoInternal(bytes, nombreArchivo));
  }

  Future<void> _actualizarLogoInternal(Uint8List bytes, String nombreArchivo) async {
    if (bytes.isEmpty) {
      throw StateError(
        'No se pudo subir el logo del taller: el archivo está vacío o no es válido. Intenta seleccionar la imagen nuevamente.',
      );
    }
    final current = state.valueOrNull ?? await future;
    final previousLogoUrl = current.logoUrl?.trim();
    try {
      final logoUrl = await _repository.subirLogo(bytes, nombreArchivo);
      try {
        final saved = await _repository.guardarInfo(current.copyWith(logoUrl: logoUrl));
        state = AsyncData(saved);
        if (previousLogoUrl != null && previousLogoUrl.isNotEmpty && previousLogoUrl != logoUrl) {
          await _repository.eliminarLogoPorUrl(previousLogoUrl);
        }
      } catch (_) {
        await _repository.eliminarLogoPorUrl(logoUrl);
        rethrow;
      }
    } on StateError catch (error) {
      if (error.message == emptyImageUploadErrorMessage ||
          error.message == 'Solo se permiten imágenes PNG, JPG/JPEG o WEBP.' ||
          error.message == 'La extensión del archivo no coincide con su formato real.') {
        throw StateError(
          'No se pudo subir el logo del taller: el archivo está vacío o no es válido. Intenta seleccionar la imagen nuevamente.',
        );
      }
      rethrow;
    }
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  Future<void> _enqueueMutation(Future<void> Function() action) async {
    final operation = _mutationQueue.then((_) => action());
    _mutationQueue = operation.catchError((_) {});
    await operation;
  }
}
