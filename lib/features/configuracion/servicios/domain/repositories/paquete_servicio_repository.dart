import '../models/paquete_servicio.dart';

abstract class PaqueteServicioRepository {
  Future<List<PaqueteServicio>> getAll();
  Future<PaqueteServicio?> getById(String id);
  Future<PaqueteServicio> create(PaqueteServicio paquete);
  Future<PaqueteServicio> update(PaqueteServicio paquete);
  Future<void> delete(String id);

  Future<List<PaqueteServicioItem>> getServiciosByPaquete(String paqueteId);
  Future<PaqueteServicioItem> addServicioToPaquete({
    required String paqueteId,
    required String servicioId,
    int cantidad = 1,
  });
  Future<void> removeServicioDePaquete({
    required String paqueteId,
    required String servicioId,
  });
  Future<void> clearServiciosDePaquete(String paqueteId);
}
