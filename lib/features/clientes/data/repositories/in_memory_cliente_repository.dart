import '../../../../shared/data/in_memory_pitbox_store.dart';
import '../../domain/models/cliente.dart';
import '../../domain/repositories/cliente_repository.dart';

class InMemoryClienteRepository implements ClienteRepository {
  InMemoryClienteRepository(this._store);

  final InMemoryPitboxStore _store;

  @override
  Future<List<Cliente>> getAll() async => List.unmodifiable(_store.clientes);

  @override
  Future<Cliente?> getById(String id) async {
    for (final cliente in _store.clientes) {
      if (cliente.id == id) {
        return cliente;
      }
    }
    return null;
  }

  @override
  Future<Cliente> create(Cliente cliente) async {
    final shouldGenerateId = cliente.id.isEmpty;
    final entity = cliente.copyWith(
      id: shouldGenerateId ? _newId() : cliente.id,
      fechaRegistro: shouldGenerateId ? DateTime.now() : cliente.fechaRegistro,
    );
    _store.clientes.add(entity);
    return entity;
  }

  @override
  Future<Cliente> update(Cliente cliente) async {
    final index = _store.clientes.indexWhere((item) => item.id == cliente.id);
    if (index < 0) {
      throw StateError('Cliente no encontrado: ${cliente.id}');
    }
    _store.clientes[index] = cliente;
    return cliente;
  }

  @override
  Future<void> delete(String id) async {
    _store.clientes.removeWhere((cliente) => cliente.id == id);
  }

  String _newId() => 'cli-${DateTime.now().microsecondsSinceEpoch}';
}
