import '../models/proforma.dart';

abstract class ProformaRepository {
  Future<List<Proforma>> getAll({
    ProformaEstado? estado,
    String? clienteId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  });

  Future<Proforma?> getById(String id);

  Future<Proforma> create(Proforma proforma);

  Future<Proforma> update(Proforma proforma);

  Future<void> delete(String id);

  Future<String> generarSiguienteNumero({required int anio});
}
