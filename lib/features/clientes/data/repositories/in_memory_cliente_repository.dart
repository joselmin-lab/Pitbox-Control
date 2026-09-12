import '../../../../core/config/mock_ids.dart';
import '../../domain/models/cliente.dart';
import '../../domain/repositories/cliente_repository.dart';

class InMemoryClienteRepository implements ClienteRepository {
  final List<Cliente> _clientes = [
    Cliente(
      id: MockIds.clienteAna,
      nombre: 'Ana',
      apellido: 'Rojas',
      telefono: '70012345',
      email: 'ana.rojas@gmail.com',
      direccion: 'Av. Blanco Galindo #123',
      fechaRegistro: DateTime(2026, 1, 10),
    ),
    Cliente(
      id: MockIds.clienteCarlos,
      nombre: 'Carlos',
      apellido: 'Pérez',
      telefono: '72123456',
      email: 'carlos.perez@hotmail.com',
      direccion: 'Zona Norte, Calle 7',
      fechaRegistro: DateTime(2026, 2, 18),
    ),
    Cliente(
      id: MockIds.clienteMaria,
      nombre: 'María',
      apellido: 'López',
      telefono: '73456789',
      email: 'maria.lopez@gmail.com',
      direccion: 'Av. América km 4',
      fechaRegistro: DateTime(2026, 3, 4),
    ),
    Cliente(
      id: MockIds.clienteJose,
      nombre: 'José',
      apellido: 'Quispe',
      telefono: '71234567',
      direccion: 'Pacata Alta, lote 21',
      fechaRegistro: DateTime(2026, 5, 30),
    ),
  ];

  @override
  Future<List<Cliente>> getAll() async => List.unmodifiable(_clientes);

  @override
  Future<Cliente?> getById(String id) async {
    for (final cliente in _clientes) {
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
    _clientes.add(entity);
    return entity;
  }

  @override
  Future<Cliente> update(Cliente cliente) async {
    final index = _clientes.indexWhere((item) => item.id == cliente.id);
    if (index < 0) {
      throw StateError('Cliente no encontrado: ${cliente.id}');
    }
    _clientes[index] = cliente;
    return cliente;
  }

  @override
  Future<void> delete(String id) async {
    _clientes.removeWhere((cliente) => cliente.id == id);
  }

  String _newId() => 'cli-${DateTime.now().microsecondsSinceEpoch}';
}
