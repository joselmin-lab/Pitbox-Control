import '../models/vehiculo.dart';

abstract class VehiculoRepository {
  Future<List<Vehiculo>> getAll();
  Future<Vehiculo?> getById(String id);
  Future<List<Vehiculo>> getByClienteId(String clienteId);
  Future<Vehiculo> create(Vehiculo vehiculo);
  Future<Vehiculo> update(Vehiculo vehiculo);
  Future<void> delete(String id);
  Future<void> deleteByClienteId(String clienteId);
}
