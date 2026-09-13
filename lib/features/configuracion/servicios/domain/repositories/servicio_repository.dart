import '../models/servicio.dart';

abstract class ServicioRepository {
  Future<List<Servicio>> getAll();
  Future<Servicio?> getById(String id);
  Future<List<Servicio>> search({String? query, String? categoria});
  Future<Servicio> create(Servicio servicio);
  Future<Servicio> update(Servicio servicio);
  Future<void> delete(String id);
}
