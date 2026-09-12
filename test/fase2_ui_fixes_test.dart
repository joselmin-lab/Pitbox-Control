import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pitbox_control/core/config/mock_ids.dart';
import 'package:pitbox_control/features/clientes/data/repositories/in_memory_cliente_repository.dart';
import 'package:pitbox_control/features/clientes/domain/models/cliente.dart';
import 'package:pitbox_control/features/clientes/domain/repositories/cliente_repository.dart';
import 'package:pitbox_control/features/clientes/presentation/screens/cliente_detail_screen.dart';
import 'package:pitbox_control/features/vehiculos/data/repositories/in_memory_vehiculo_repository.dart';
import 'package:pitbox_control/features/vehiculos/domain/models/vehiculo.dart';
import 'package:pitbox_control/features/vehiculos/domain/repositories/vehiculo_repository.dart';
import 'package:pitbox_control/features/vehiculos/presentation/screens/vehiculo_form_screen.dart';
import 'package:pitbox_control/shared/data/in_memory_pitbox_store.dart';
import 'package:pitbox_control/shared/providers/repository_providers.dart';
import 'package:pitbox_control/shared/widgets/app_card.dart';

void main() {
  testWidgets('AppSectionCard evita overflow con contenido alto en altura limitada', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              height: 220,
              child: AppSectionCard(
                title: 'Prueba',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 80, child: Text('Bloque 1')),
                    SizedBox(height: 80, child: Text('Bloque 2')),
                    SizedBox(height: 80, child: Text('Bloque 3')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final scrollable = find.descendant(
      of: find.byType(AppSectionCard),
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);

    final initialOffset = tester.state<ScrollableState>(scrollable).position.pixels;
    await tester.drag(scrollable, const Offset(0, -120));
    await tester.pump();

    expect(tester.state<ScrollableState>(scrollable).position.pixels, greaterThan(initialOffset));
  });

  testWidgets('detalle de cliente no muestra checkbox de selección en tabla de vehículos', (tester) async {
    final store = InMemoryPitboxStore.seeded();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clienteRepositoryProvider.overrideWithValue(InMemoryClienteRepository(store)),
          vehiculoRepositoryProvider.overrideWithValue(InMemoryVehiculoRepository(store)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ClienteDetailScreen(clienteId: MockIds.clienteAna),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('2874-LSC'), findsOneWidget);
  });

  testWidgets('formulario de vehículo permite buscar cliente y asociar su id al guardar', (tester) async {
    final clienteRepository = _TestClienteRepository([
      Cliente(
        id: MockIds.clienteAna,
        nombre: 'Ana',
        apellido: 'Rojas',
        telefono: '70012345',
        fechaRegistro: DateTime(2026, 1, 10),
      ),
      Cliente(
        id: MockIds.clienteMaria,
        nombre: 'María',
        apellido: 'López',
        telefono: '73456789',
        fechaRegistro: DateTime(2026, 3, 4),
      ),
    ]);
    final vehiculoRepository = _RecordingVehiculoRepository();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: VehiculoFormScreen(clienteId: MockIds.clienteMaria),
          ),
        ),
        GoRoute(
          path: '/vehiculos',
          builder: (context, state) => const Scaffold(body: Text('Vehículos')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clienteRepositoryProvider.overrideWithValue(clienteRepository),
          vehiculoRepositoryProvider.overrideWithValue(vehiculoRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('María López'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Ana');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ana Rojas').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), 'ABC-123');
    await tester.enterText(find.byType(TextFormField).at(2), 'Toyota');
    await tester.enterText(find.byType(TextFormField).at(3), 'Corolla');
    await tester.enterText(find.byType(TextFormField).at(4), '2024');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(vehiculoRepository.createdVehiculo?.clienteId, MockIds.clienteAna);
    expect(find.text('Vehículos'), findsOneWidget);
  });

  testWidgets('formulario de vehículo encuentra clientes aunque se omitan tildes', (tester) async {
    final clienteRepository = _TestClienteRepository([
      Cliente(
        id: MockIds.clienteMaria,
        nombre: 'María',
        apellido: 'López',
        telefono: '73456789',
        fechaRegistro: DateTime(2026, 3, 4),
      ),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clienteRepositoryProvider.overrideWithValue(clienteRepository),
          vehiculoRepositoryProvider.overrideWithValue(_RecordingVehiculoRepository()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: VehiculoFormScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Maria');
    await tester.pumpAndSettle();

    expect(find.text('María López'), findsWidgets);
  });

  testWidgets('formulario de vehículo limpia clienteId inválido y exige una selección válida', (tester) async {
    final clienteRepository = _TestClienteRepository([
      Cliente(
        id: MockIds.clienteAna,
        nombre: 'Ana',
        apellido: 'Rojas',
        telefono: '70012345',
        fechaRegistro: DateTime(2026, 1, 10),
      ),
    ]);
    final vehiculoRepository = _RecordingVehiculoRepository();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: VehiculoFormScreen(clienteId: 'cli-inexistente'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clienteRepositoryProvider.overrideWithValue(clienteRepository),
          vehiculoRepositoryProvider.overrideWithValue(vehiculoRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ana Rojas'), findsNothing);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Debes seleccionar un cliente.'), findsOneWidget);
    expect(vehiculoRepository.createdVehiculo, isNull);
  });

  testWidgets('formulario de vehículo exige selección explícita aunque se escriba el nombre completo', (
    tester,
  ) async {
    final clienteRepository = _TestClienteRepository([
      Cliente(
        id: MockIds.clienteAna,
        nombre: 'Ana',
        apellido: 'Rojas',
        telefono: '70012345',
        fechaRegistro: DateTime(2026, 1, 10),
      ),
      Cliente(
        id: MockIds.clienteMaria,
        nombre: 'María',
        apellido: 'López',
        telefono: '73456789',
        fechaRegistro: DateTime(2026, 3, 4),
      ),
    ]);
    final vehiculoRepository = _RecordingVehiculoRepository();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: VehiculoFormScreen()),
        ),
        GoRoute(
          path: '/vehiculos',
          builder: (context, state) => const Scaffold(body: Text('Vehículos')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clienteRepositoryProvider.overrideWithValue(clienteRepository),
          vehiculoRepositoryProvider.overrideWithValue(vehiculoRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Ana Rojas');
    await tester.enterText(find.byType(TextFormField).at(1), 'ABC-999');
    await tester.enterText(find.byType(TextFormField).at(2), 'Kia');
    await tester.enterText(find.byType(TextFormField).at(3), 'Rio');
    await tester.enterText(find.byType(TextFormField).at(4), '2023');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Debes seleccionar un cliente.'), findsOneWidget);
    expect(vehiculoRepository.createdVehiculo, isNull);
  });

  testWidgets('formulario de vehículo no guarda si solo se escribe un nombre parcial sin seleccionar', (
    tester,
  ) async {
    final clienteRepository = _TestClienteRepository([
      Cliente(
        id: MockIds.clienteAna,
        nombre: 'Ana',
        apellido: 'Rojas',
        telefono: '70012345',
        fechaRegistro: DateTime(2026, 1, 10),
      ),
      Cliente(
        id: MockIds.clienteMaria,
        nombre: 'María',
        apellido: 'López',
        telefono: '73456789',
        fechaRegistro: DateTime(2026, 3, 4),
      ),
    ]);
    final vehiculoRepository = _RecordingVehiculoRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clienteRepositoryProvider.overrideWithValue(clienteRepository),
          vehiculoRepositoryProvider.overrideWithValue(vehiculoRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: VehiculoFormScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Ana');
    await tester.enterText(find.byType(TextFormField).at(1), 'XYZ-777');
    await tester.enterText(find.byType(TextFormField).at(2), 'Mazda');
    await tester.enterText(find.byType(TextFormField).at(3), '2');
    await tester.enterText(find.byType(TextFormField).at(4), '2022');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Debes seleccionar un cliente.'), findsOneWidget);
    expect(vehiculoRepository.createdVehiculo, isNull);
  });

  testWidgets('formulario de vehículo no autoasocia nombres completos duplicados sin selección', (
    tester,
  ) async {
    final clienteRepository = _TestClienteRepository([
      Cliente(
        id: 'cli-ana-1',
        nombre: 'Ana',
        apellido: 'Rojas',
        telefono: '70012345',
        fechaRegistro: DateTime(2026, 1, 10),
      ),
      Cliente(
        id: 'cli-ana-2',
        nombre: 'Ana',
        apellido: 'Rojas',
        telefono: '71111111',
        fechaRegistro: DateTime(2026, 2, 10),
      ),
    ]);
    final vehiculoRepository = _RecordingVehiculoRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clienteRepositoryProvider.overrideWithValue(clienteRepository),
          vehiculoRepositoryProvider.overrideWithValue(vehiculoRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: VehiculoFormScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Ana Rojas');
    await tester.enterText(find.byType(TextFormField).at(1), 'DUP-001');
    await tester.enterText(find.byType(TextFormField).at(2), 'Toyota');
    await tester.enterText(find.byType(TextFormField).at(3), 'Etios');
    await tester.enterText(find.byType(TextFormField).at(4), '2021');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Debes seleccionar un cliente.'), findsOneWidget);
    expect(vehiculoRepository.createdVehiculo, isNull);
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
  Future<Cliente?> getById(String id) async {
    for (final cliente in _clientes) {
      if (cliente.id == id) {
        return cliente;
      }
    }
    return null;
  }

  @override
  Future<Cliente> update(Cliente cliente) async => throw UnimplementedError();
}

class _RecordingVehiculoRepository implements VehiculoRepository {
  Vehiculo? createdVehiculo;

  @override
  Future<Vehiculo> create(Vehiculo vehiculo) async {
    createdVehiculo = vehiculo.copyWith(id: 'veh-test');
    return createdVehiculo!;
  }

  @override
  Future<void> delete(String id) async => throw UnimplementedError();

  @override
  Future<void> deleteByClienteId(String clienteId) async => throw UnimplementedError();

  @override
  Future<List<Vehiculo>> getAll() async => const [];

  @override
  Future<List<Vehiculo>> getByClienteId(String clienteId) async => const [];

  @override
  Future<Vehiculo?> getById(String id) async => null;

  @override
  Future<Vehiculo> update(Vehiculo vehiculo) async => throw UnimplementedError();
}
