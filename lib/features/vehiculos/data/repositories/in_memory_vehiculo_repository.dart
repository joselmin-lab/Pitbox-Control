import '../../../../shared/data/in_memory_pitbox_store.dart';
import '../../domain/models/vehiculo.dart';
import '../../domain/repositories/vehiculo_repository.dart';

class InMemoryVehiculoRepository implements VehiculoRepository {
  InMemoryVehiculoRepository(this._store);

  final InMemoryPitboxStore _store;

  @override
  Future<List<Vehiculo>> getAll() async => List.unmodifiable(_store.vehiculos);

  @override
  Future<Vehiculo?> getById(String id) async {
    for (final vehiculo in _store.vehiculos) {
      if (vehiculo.id == id) {
        return vehiculo;
      }
    }
    return null;
  }

  @override
  Future<List<Vehiculo>> getByClienteId(String clienteId) async {
    return _store.vehiculos.where((vehiculo) => vehiculo.clienteId == clienteId).toList(growable: false);
  }

  @override
  Future<Vehiculo> create(Vehiculo vehiculo) async {
    final shouldGenerateId = vehiculo.id.isEmpty;
    final entity = vehiculo.copyWith(
      id: shouldGenerateId ? _newId() : vehiculo.id,
      fechaRegistro: shouldGenerateId ? DateTime.now() : vehiculo.fechaRegistro,
    );
    _store.vehiculos.add(entity);
    return entity;
  }

  @override
  Future<Vehiculo> update(Vehiculo vehiculo) async {
    final index = _store.vehiculos.indexWhere((item) => item.id == vehiculo.id);
    if (index < 0) {
      throw StateError('Vehículo no encontrado: ${vehiculo.id}');
    }
    _store.vehiculos[index] = vehiculo;
    return vehiculo;
  }

  @override
  Future<void> delete(String id) async {
    _store.vehiculos.removeWhere((vehiculo) => vehiculo.id == id);
  }

  @override
  Future<void> deleteByClienteId(String clienteId) async {
    _store.vehiculos.removeWhere((vehiculo) => vehiculo.clienteId == clienteId);
  }

  String _newId() => 'veh-${DateTime.now().microsecondsSinceEpoch}';
}
