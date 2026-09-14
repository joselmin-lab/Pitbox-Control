import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitbox_control/features/trabajos/recepciones/domain/models/recepcion_vehiculo.dart';
import 'package:pitbox_control/features/trabajos/recepciones/domain/repositories/recepcion_repository.dart';
import 'package:pitbox_control/features/trabajos/recepciones/presentation/providers/recepciones_provider.dart';
import 'package:pitbox_control/shared/providers/repository_providers.dart';

void main() {
  test('recepcionesProvider carga recepciones iniciales', () async {
    final container = _buildContainer(
      _RecepcionRepositoryFake([
        _sampleRecepcion(id: 'r1', numero: '001-2026'),
      ]),
    );
    addTearDown(container.dispose);

    final recepciones = await container.read(recepcionesProvider.future);
    expect(recepciones, hasLength(1));
    expect(recepciones.first.numero, '001-2026');
  });

  test('crear agrega recepción y recarga listado', () async {
    final repository = _RecepcionRepositoryFake([]);
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container.read(recepcionesProvider.future);
    final created = await container.read(recepcionesProvider.notifier).crear(
          _sampleRecepcion(id: '', numero: ''),
        );

    final recepciones = container.read(recepcionesProvider).valueOrNull!;
    expect(created.numero, '001-2026');
    expect(recepciones, hasLength(1));
    expect(repository.generatedYears, [2026]);
  });

  test('crear conserva número manual y no genera consecutivo nuevo', () async {
    final repository = _RecepcionRepositoryFake([]);
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container.read(recepcionesProvider.future);
    final created = await container.read(recepcionesProvider.notifier).crear(
          _sampleRecepcion(id: '', numero: '999-2026'),
        );

    expect(created.numero, '999-2026');
    expect(repository.generatedYears, isEmpty);
  });

  test('cambiarEstado persiste actualización', () async {
    final original = _sampleRecepcion(id: 'r1', numero: '001-2026');
    final repository = _RecepcionRepositoryFake([original]);
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container.read(recepcionesProvider.future);
    final updated = await container.read(recepcionesProvider.notifier).cambiarEstado(
          recepcion: original,
          estado: RecepcionEstado.vehiculoEntregado,
        );

    expect(updated.estado, RecepcionEstado.vehiculoEntregado);
    expect(container.read(recepcionesProvider).valueOrNull!.single.estado, RecepcionEstado.vehiculoEntregado);
  });

  test('editar actualiza recepción y recarga listado', () async {
    final original = _sampleRecepcion(id: 'r1', numero: '001-2026');
    final repository = _RecepcionRepositoryFake([original]);
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container.read(recepcionesProvider.future);
    final updated = await container.read(recepcionesProvider.notifier).editar(
          original.copyWith(
            observaciones: 'Actualizado',
            kilometraje: '125000',
          ),
        );

    expect(updated.observaciones, 'Actualizado');
    expect(updated.kilometraje, '125000');
    expect(container.read(recepcionesProvider).valueOrNull!.single.observaciones, 'Actualizado');
  });

  test('recepcionFormProvider administra daños y firmas locales', () {
    final container = _buildContainer(_RecepcionRepositoryFake([]));
    addTearDown(container.dispose);

    final notifier = container.read(recepcionFormProvider.notifier);
    notifier.initialize(null);
    notifier.addDano(
      vista: RecepcionVistaVehiculo.frente,
      puntoRelativo: const Offset(0.25, 0.75),
    );
    notifier.setFirmaCliente([
      const [Offset(1, 1), Offset(2, 2)],
    ]);

    final draft = container.read(recepcionFormProvider);
    expect(draft.danosPreexistentes, hasLength(1));
    expect(draft.danosPreexistentes.single.vista, RecepcionVistaVehiculo.frente);
    expect(draft.tieneFirmaCliente, isTrue);
  });

  test('recepcionFormProvider agrega y remueve fotografías pendientes', () {
    final container = _buildContainer(_RecepcionRepositoryFake([]));
    addTearDown(container.dispose);

    final notifier = container.read(recepcionFormProvider.notifier);
    notifier.initialize(null);
    notifier.addFotografiasPendientes([
      RecepcionArchivoLocal(
        id: 'foto-1',
        nombreArchivo: 'vehiculo.png',
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
    ]);
    expect(container.read(recepcionFormProvider).fotografiasPendientes, hasLength(1));

    notifier.removeFotografiaPendiente('foto-1');
    expect(container.read(recepcionFormProvider).fotografiasPendientes, isEmpty);
  });
}

ProviderContainer _buildContainer(RecepcionRepository repository) {
  return ProviderContainer(
    overrides: [
      recepcionRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

RecepcionVehiculo _sampleRecepcion({
  required String id,
  required String numero,
}) {
  return RecepcionVehiculo(
    id: id,
    numero: numero,
    clienteId: 'c1',
    vehiculoId: 'v1',
    fechaIngreso: DateTime(2026, 1, 5),
    fechaSalidaEstimada: DateTime(2026, 1, 6),
    kilometraje: '120000',
    trabajoARealizar: 'Cambio de aceite',
    observaciones: 'Sin observaciones',
    firmaPrestadorUrl: 'https://example.com/firma-prestador.png',
    firmaClienteUrl: 'https://example.com/firma-cliente.png',
    fechaCreacion: DateTime(2026, 1, 5),
  );
}

class _RecepcionRepositoryFake implements RecepcionRepository {
  _RecepcionRepositoryFake(List<RecepcionVehiculo> initial)
      : _items = initial.toList(growable: true);

  final List<RecepcionVehiculo> _items;
  final List<int> generatedYears = <int>[];

  @override
  Future<RecepcionVehiculo> create(RecepcionVehiculo recepcion) async {
    final numero = recepcion.numero.trim().isNotEmpty
        ? recepcion.numero
        : await generarSiguienteNumero(anio: recepcion.fechaIngreso.year);
    final created = recepcion.copyWith(
      id: recepcion.id.isEmpty ? 'r${_items.length + 1}' : recepcion.id,
      numero: numero,
    );
    _items.add(created);
    return created;
  }

  @override
  Future<String> generarSiguienteNumero({required int anio}) async {
    generatedYears.add(anio);
    return '${(_items.length + 1).toString().padLeft(3, '0')}-$anio';
  }

  @override
  Future<List<RecepcionVehiculo>> getAll({
    RecepcionEstado? estado,
    String? clienteId,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    return _items.toList(growable: false);
  }

  @override
  Future<RecepcionVehiculo?> getById(String id) async {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<String> subirFirma(Uint8List bytes, String nombreArchivo) async {
    return 'https://example.com/recepciones-firmas/$nombreArchivo';
  }

  @override
  Future<String> subirFotografia(Uint8List bytes, String nombreArchivo) async {
    return 'https://example.com/recepciones-fotos/$nombreArchivo';
  }

  @override
  Future<RecepcionVehiculo> update(RecepcionVehiculo recepcion) async {
    final index = _items.indexWhere((item) => item.id == recepcion.id);
    if (index < 0) {
      throw StateError('not found');
    }
    _items[index] = recepcion;
    return recepcion;
  }
}
