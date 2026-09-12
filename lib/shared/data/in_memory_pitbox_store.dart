import '../../core/config/mock_ids.dart';
import '../../features/clientes/domain/models/cliente.dart';
import '../../features/vehiculos/domain/models/vehiculo.dart';

class InMemoryPitboxStore {
  InMemoryPitboxStore._({
    required this.clientes,
    required this.vehiculos,
  });

  final List<Cliente> clientes;
  final List<Vehiculo> vehiculos;

  factory InMemoryPitboxStore.seeded() {
    return InMemoryPitboxStore._(
      clientes: [
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
      ],
      vehiculos: [
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
      ],
    );
  }
}
