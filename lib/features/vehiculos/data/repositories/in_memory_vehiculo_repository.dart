import '../../../../core/config/mock_ids.dart';
import '../../domain/models/vehiculo.dart';
import '../../domain/repositories/vehiculo_repository.dart';

class InMemoryVehiculoRepository implements VehiculoRepository {
  final List<Vehiculo> _vehiculos = [
    Vehiculo(
      id: 'veh-001',
      clienteId: MockIds.clienteAna,
      placa: '2874-LSC',
      marca: 'Toyota',
      modelo: 'Corolla',
      anio: 2018,
      color: 'Plata',
      kilometraje: 64300,
      fechaRegistro: DateTime(2026, 1, 10),
    ),
    Vehiculo(
      id: 'veh-002',
      clienteId: MockIds.clienteAna,
      placa: '4912-KGA',
      marca: 'Kia',
      modelo: 'Rio',
      anio: 2020,
      color: 'Rojo',
      kilometraje: 48200,
      fechaRegistro: DateTime(2026, 1, 18),
    ),
    Vehiculo(
      id: 'veh-003',
      clienteId: MockIds.clienteCarlos,
      placa: '3920-UYR',
      marca: 'Nissan',
      modelo: 'Sentra',
      anio: 2017,
      color: 'Blanco',
      kilometraje: 90350,
      fechaRegistro: DateTime(2026, 2, 19),
    ),
    Vehiculo(
      id: 'veh-004',
      clienteId: MockIds.clienteMaria,
      placa: '6165-HZO',
      marca: 'Suzuki',
      modelo: 'Vitara',
      anio: 2021,
      color: 'Negro',
      kilometraje: 27800,
      fechaRegistro: DateTime(2026, 3, 4),
    ),
    Vehiculo(
      id: 'veh-005',
      clienteId: MockIds.clienteJose,
      placa: '8451-BNP',
      marca: 'Hyundai',
      modelo: 'Accent',
      anio: 2016,
      kilometraje: 112000,
      fechaRegistro: DateTime(2026, 6, 1),
    ),
  ];

  @override
  Future<List<Vehiculo>> getAll() async => List.unmodifiable(_vehiculos);

  @override
  Future<Vehiculo?> getById(String id) async {
    for (final vehiculo in _vehiculos) {
      if (vehiculo.id == id) {
        return vehiculo;
      }
    }
    return null;
  }

  @override
  Future<List<Vehiculo>> getByClienteId(String clienteId) async {
    return _vehiculos.where((vehiculo) => vehiculo.clienteId == clienteId).toList(growable: false);
  }

  @override
  Future<Vehiculo> create(Vehiculo vehiculo) async {
    final shouldGenerateId = vehiculo.id.isEmpty;
    final entity = vehiculo.copyWith(
      id: shouldGenerateId ? _newId() : vehiculo.id,
      fechaRegistro: shouldGenerateId ? DateTime.now() : vehiculo.fechaRegistro,
    );
    _vehiculos.add(entity);
    return entity;
  }

  @override
  Future<Vehiculo> update(Vehiculo vehiculo) async {
    final index = _vehiculos.indexWhere((item) => item.id == vehiculo.id);
    if (index < 0) {
      throw StateError('Vehículo no encontrado: ${vehiculo.id}');
    }
    _vehiculos[index] = vehiculo;
    return vehiculo;
  }

  @override
  Future<void> delete(String id) async {
    _vehiculos.removeWhere((vehiculo) => vehiculo.id == id);
  }

  @override
  Future<void> deleteByClienteId(String clienteId) async {
    _vehiculos.removeWhere((vehiculo) => vehiculo.clienteId == clienteId);
  }

  String _newId() => 'veh-${DateTime.now().microsecondsSinceEpoch}';
}
