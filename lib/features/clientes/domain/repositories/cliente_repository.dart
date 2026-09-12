import '../models/cliente.dart';

abstract class ClienteRepository {
  Future<List<Cliente>> getAll();
  Future<Cliente?> getById(String id);
  Future<Cliente> create(Cliente cliente);
  Future<Cliente> update(Cliente cliente);
  Future<void> delete(String id);
}
