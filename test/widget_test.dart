import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pitbox_control/features/clientes/domain/models/cliente.dart';
import 'package:pitbox_control/features/clientes/domain/repositories/cliente_repository.dart';
import 'package:pitbox_control/features/vehiculos/domain/models/vehiculo.dart';
import 'package:pitbox_control/features/vehiculos/domain/repositories/vehiculo_repository.dart';
import 'package:pitbox_control/main.dart';
import 'package:pitbox_control/shared/providers/repository_providers.dart';
import 'package:pitbox_control/shared/widgets/kpi_card.dart';

void main() {
  testWidgets('muestra el dashboard inicial y el branding principal', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PitboxControlApp()));
    await tester.pumpAndSettle();

    expect(find.text('Pitbox Control'), findsOneWidget);
    expect(find.text('Dashboard general'), findsOneWidget);
    expect(find.text('Total clientes'), findsOneWidget);
    expect(find.text('Total vehículos'), findsOneWidget);
    expect(
      find.descendant(of: find.widgetWithText(KpiCard, 'Total clientes'), matching: find.text('4')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.widgetWithText(KpiCard, 'Total vehículos'), matching: find.text('5')),
      findsOneWidget,
    );
    expect(find.text('Nueva proforma'), findsOneWidget);
  });

  testWidgets('dashboard refleja totales según repositorios inyectados', (tester) async {
    final clienteRepo = _TestClienteRepository([
      Cliente(
        id: 'c1',
        nombre: 'Uno',
        apellido: 'Prueba',
        telefono: '70000001',
        fechaRegistro: DateTime(2026, 1, 1),
      ),
    ]);
    final vehiculoRepo = _TestVehiculoRepository([
      Vehiculo(
        id: 'v1',
        clienteId: 'c1',
        placa: 'AAA-111',
        marca: 'Kia',
        modelo: 'Rio',
        anio: 2020,
        fechaRegistro: DateTime(2026, 1, 1),
      ),
      Vehiculo(
        id: 'v2',
        clienteId: 'c1',
        placa: 'BBB-222',
        marca: 'Toyota',
        modelo: 'Corolla',
        anio: 2019,
        fechaRegistro: DateTime(2026, 1, 1),
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clienteRepositoryProvider.overrideWithValue(clienteRepo),
          vehiculoRepositoryProvider.overrideWithValue(vehiculoRepo),
        ],
        child: const PitboxControlApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.widgetWithText(KpiCard, 'Total clientes'), matching: find.text('1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.widgetWithText(KpiCard, 'Total vehículos'), matching: find.text('2')),
      findsOneWidget,
    );
  });
}

class _TestClienteRepository implements ClienteRepository {
  _TestClienteRepository(this._clientes);

  final List<Cliente> _clientes;

  @override
  Future<Cliente> create(Cliente cliente) async => throw UnimplementedError();

  @override
  Future<void> delete(String id) async => throw UnimplementedError();

  @override
  Future<List<Cliente>> getAll() async => _clientes;

  @override
  Future<Cliente?> getById(String id) async => _clientes.firstWhere((item) => item.id == id);

  @override
  Future<Cliente> update(Cliente cliente) async => throw UnimplementedError();
}

class _TestVehiculoRepository implements VehiculoRepository {
  _TestVehiculoRepository(this._vehiculos);

  final List<Vehiculo> _vehiculos;

  @override
  Future<Vehiculo> create(Vehiculo vehiculo) async => throw UnimplementedError();

  @override
  Future<void> delete(String id) async => throw UnimplementedError();

  @override
  Future<void> deleteByClienteId(String clienteId) async => throw UnimplementedError();

  @override
  Future<List<Vehiculo>> getAll() async => _vehiculos;

  @override
  Future<List<Vehiculo>> getByClienteId(String clienteId) async =>
      _vehiculos.where((item) => item.clienteId == clienteId).toList(growable: false);

  @override
  Future<Vehiculo?> getById(String id) async => _vehiculos.firstWhere((item) => item.id == id);

  @override
  Future<Vehiculo> update(Vehiculo vehiculo) async => throw UnimplementedError();
}
