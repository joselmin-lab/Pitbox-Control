import '../models/configuracion_impuestos.dart';

abstract class ImpuestosRepository {
  Future<ConfiguracionImpuestos> getInfo();
  Future<ConfiguracionImpuestos> guardar({
    required double porcentajeIva,
    required double porcentajeIt,
  });
}
