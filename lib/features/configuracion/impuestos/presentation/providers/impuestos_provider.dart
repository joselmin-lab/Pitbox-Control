import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/providers/repository_providers.dart';
import '../../domain/models/configuracion_impuestos.dart';
import '../../domain/repositories/impuestos_repository.dart';

final impuestosProvider = AsyncNotifierProvider<ImpuestosNotifier, ConfiguracionImpuestos>(() {
  return ImpuestosNotifier();
});

class ImpuestosNotifier extends AsyncNotifier<ConfiguracionImpuestos> {
  ImpuestosRepository get _repository => ref.read(impuestosRepositoryProvider);

  @override
  Future<ConfiguracionImpuestos> build() async {
    return _repository.getInfo();
  }

  Future<void> guardar({
    required double porcentajeIva,
    required double porcentajeIt,
  }) async {
    final saved = await _repository.guardar(
      porcentajeIva: porcentajeIva,
      porcentajeIt: porcentajeIt,
    );
    state = AsyncData(saved);
  }
}
