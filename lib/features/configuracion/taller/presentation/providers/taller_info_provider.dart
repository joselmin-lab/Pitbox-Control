import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/taller_info.dart';
import '../../domain/repositories/taller_repository.dart';
import '../../../../../shared/providers/repository_providers.dart';

final tallerInfoProvider = AsyncNotifierProvider<TallerInfoNotifier, TallerInfo>(() {
  return TallerInfoNotifier();
});

class TallerInfoNotifier extends AsyncNotifier<TallerInfo> {
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
    final previous = state.valueOrNull ?? await future;
    final saved = await _repository.guardarInfo(
      previous.copyWith(
        nombre: nombre.trim(),
        direccion: _optional(direccion),
        clearDireccion: _optional(direccion) == null,
        telefono: _optional(telefono),
        clearTelefono: _optional(telefono) == null,
        correo: _optional(correo),
        clearCorreo: _optional(correo) == null,
      ),
    );
    state = AsyncData(saved);
  }

  Future<void> actualizarLogo(Uint8List bytes, String nombreArchivo) async {
    final previous = state.valueOrNull ?? await future;
    final logoUrl = await _repository.subirLogo(bytes, nombreArchivo);
    final saved = await _repository.guardarInfo(previous.copyWith(logoUrl: logoUrl));
    state = AsyncData(saved);
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
