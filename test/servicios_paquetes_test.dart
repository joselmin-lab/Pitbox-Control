import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitbox_control/features/configuracion/servicios/domain/models/paquete_servicio.dart';
import 'package:pitbox_control/features/configuracion/servicios/domain/models/servicio.dart';
import 'package:pitbox_control/features/configuracion/servicios/domain/repositories/paquete_servicio_repository.dart';
import 'package:pitbox_control/features/configuracion/servicios/domain/repositories/servicio_repository.dart';
import 'package:pitbox_control/features/configuracion/servicios/presentation/providers/paquetes_servicios_provider.dart';
import 'package:pitbox_control/features/configuracion/servicios/presentation/providers/servicios_provider.dart';
import 'package:pitbox_control/shared/providers/repository_providers.dart';

void main() {
  test('paquete calcula precio total por suma o precio manual', () {
    final servicioA = Servicio(
      id: 'srv-a',
      nombre: 'Cambio de aceite',
      precio: 100,
      activo: true,
      fechaCreacion: DateTime(2026, 1, 1),
    );
    final servicioB = servicioA.copyWith(id: 'srv-b', nombre: 'Alineado', precio: 50);

    final paqueteAuto = PaqueteServicio(
      id: 'paq-1',
      nombre: 'Pack básico',
      activo: true,
      fechaCreacion: DateTime(2026, 1, 1),
      items: [
        PaqueteServicioItem(id: 'it-1', paqueteId: 'paq-1', servicioId: 'srv-a', servicio: servicioA, cantidad: 1),
        PaqueteServicioItem(id: 'it-2', paqueteId: 'paq-1', servicioId: 'srv-b', servicio: servicioB, cantidad: 2),
      ],
    );

    expect(paqueteAuto.precioTotalCalculado, 200);

    final paqueteManual = paqueteAuto.copyWith(precioManual: 170);
    expect(paqueteManual.precioTotalCalculado, 170);
  });

  test('serviciosFiltradosProvider filtra por nombre y categoría', () async {
    final container = ProviderContainer(
      overrides: [
        servicioRepositoryProvider.overrideWithValue(
          _ServicioRepositoryFake([
            Servicio(
              id: 'srv-1',
              nombre: 'Cambio de aceite',
              categoria: 'Mantenimiento',
              precio: 120,
              activo: true,
              fechaCreacion: DateTime(2026, 1, 1),
            ),
            Servicio(
              id: 'srv-2',
              nombre: 'Lavado',
              categoria: 'Estética',
              precio: 40,
              activo: true,
              fechaCreacion: DateTime(2026, 1, 2),
            ),
          ]),
        ),
        paqueteServicioRepositoryProvider.overrideWithValue(_PaqueteRepositoryFake()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(serviciosProvider.future);

    container.read(serviciosSearchQueryProvider.notifier).state = 'aceite';
    var filtrados = container.read(serviciosFiltradosProvider);
    expect(filtrados.map((item) => item.id).toList(), ['srv-1']);

    container.read(serviciosSearchQueryProvider.notifier).state = '';
    container.read(serviciosCategoriaFilterProvider.notifier).state = 'Estética';
    filtrados = container.read(serviciosFiltradosProvider);
    expect(filtrados.map((item) => item.id).toList(), ['srv-2']);
  });

  test('importarCsv valida encabezado inválido', () async {
    final container = _buildContainer(_ServicioRepositoryFake(const []));
    addTearDown(container.dispose);

    await container.read(serviciosProvider.future);

    final result = await container.read(serviciosProvider.notifier).importarCsv(
          'nombre,precio,activo\nCambio de aceite,120,true',
        );

    expect(result.created, 0);
    expect(result.updated, 0);
    expect(result.errors, isNotEmpty);
    expect(result.errors.first, contains('Encabezado inválido'));
  });



  test('importarCsv reporta CSV inválido y contabiliza filas vacías como omitidas', () async {
    final container = _buildContainer(_ServicioRepositoryFake(const []));
    addTearDown(container.dispose);

    await container.read(serviciosProvider.future);

    final invalid = await container.read(serviciosProvider.notifier).importarCsv(
          '"nombre,descripcion,precio,categoria,activo\n"fila rota',
        );
    expect(invalid.errors.first, contains('CSV inválido'));

    final withEmptyRows = await container.read(serviciosProvider.notifier).importarCsv(
          'nombre,descripcion,precio,categoria,activo\n\n\nLavado,,40,Estética,true',
        );
    expect(withEmptyRows.created, 1);
    expect(withEmptyRows.skipped, 2);
  });




  test('importarCsv reporta claves duplicadas dentro del mismo archivo', () async {
    final container = _buildContainer(_ServicioRepositoryFake(const []));
    addTearDown(container.dispose);

    await container.read(serviciosProvider.future);

    final result = await container.read(serviciosProvider.notifier).importarCsv(
          'nombre,descripcion,precio,categoria,activo\n'
          'Lavado,Primera fila,40,Estética,true\n'
          'Lavado,Duplicada,45,Estética,false',
        );

    expect(result.created, 1);
    expect(result.updated, 0);
    expect(result.skipped, 0);
    expect(result.errors.length, 1);
    expect(result.errors.first, contains('clave duplicada'));
  });
  test('importarCsv reindexa claves cuando cambia nombre o categoría', () async {
    final repository = _ServicioRepositoryFake([
      Servicio(
        id: 'srv-1',
        nombre: 'Cambio de aceite',
        categoria: 'Mantenimiento',
        precio: 120,
        activo: true,
        fechaCreacion: DateTime(2026, 1, 1),
      ),
    ]);
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container.read(serviciosProvider.future);

    final result = await container.read(serviciosProvider.notifier).importarCsv(
          'nombre,descripcion,precio,categoria,activo\n'
          'Cambio premium,Renombrado,140,Mantenimiento,true\n'
          'Cambio de aceite,Nuevo servicio,110,Mantenimiento,true',
        );

    expect(result.updated, 1);
    expect(result.created, 1);

    final servicios = await repository.getAll();
    expect(servicios.where((item) => item.nombre == 'Cambio premium').length, 1);
    expect(servicios.where((item) => item.nombre == 'Cambio de aceite').length, 1);
  });
  test('importarCsv actualiza existentes y reporta errores por fila inválida', () async {
    final repository = _ServicioRepositoryFake([
      Servicio(
        id: 'srv-1',
        nombre: 'Cambio de aceite',
        categoria: 'Mantenimiento',
        precio: 120,
        activo: true,
        fechaCreacion: DateTime(2026, 1, 1),
      ),
    ]);
    final container = _buildContainer(repository);
    addTearDown(container.dispose);

    await container.read(serviciosProvider.future);

    final result = await container.read(serviciosProvider.notifier).importarCsv(
          'nombre,descripcion,precio,categoria,activo\n'
          'Cambio de aceite,Actualizado,150,Mantenimiento,false\n'
          'Lavado,,40,Estética,si\n'
          'Engrase,,30,Mantenimiento,no\n'
          'Servicio inválido,,abc,General,true',
        );

    expect(result.updated, 1);
    expect(result.created, 2);
    expect(result.errors.length, 1);

    final servicios = await repository.getAll();
    final actualizado = servicios.firstWhere((item) => item.nombre == 'Cambio de aceite');
    expect(actualizado.precio, 150);
    expect(actualizado.activo, isFalse);

    final creado = servicios.firstWhere((item) => item.nombre == 'Lavado');
    expect(creado.activo, isTrue);

    final engrase = servicios.firstWhere((item) => item.nombre == 'Engrase');
    expect(engrase.activo, isFalse);
  });

}


ProviderContainer _buildContainer(ServicioRepository servicioRepository) {
  return ProviderContainer(
    overrides: [
      servicioRepositoryProvider.overrideWithValue(servicioRepository),
      paqueteServicioRepositoryProvider.overrideWithValue(_PaqueteRepositoryFake()),
    ],
  );
}

class _ServicioRepositoryFake implements ServicioRepository {
  _ServicioRepositoryFake(this._items);

  final List<Servicio> _items;

  @override
  Future<Servicio> create(Servicio servicio) async {
    _items.add(servicio.copyWith(id: servicio.id.isEmpty ? 'srv-${_items.length + 1}' : servicio.id));
    return _items.last;
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<Servicio>> getAll() async => List.unmodifiable(_items);

  @override
  Future<Servicio?> getById(String id) async {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<List<Servicio>> search({String? query, String? categoria}) async => getAll();

  @override
  Future<Servicio> update(Servicio servicio) async {
    final index = _items.indexWhere((item) => item.id == servicio.id);
    _items[index] = servicio;
    return servicio;
  }
}

class _PaqueteRepositoryFake implements PaqueteServicioRepository {
  @override
  Future<PaqueteServicioItem> addServicioToPaquete({
    required String paqueteId,
    required String servicioId,
    int cantidad = 1,
  }) async {
    return PaqueteServicioItem(id: 'i', paqueteId: paqueteId, servicioId: servicioId, cantidad: cantidad);
  }

  @override
  Future<void> clearServiciosDePaquete(String paqueteId) async {}

  @override
  Future<PaqueteServicio> create(PaqueteServicio paquete) async => paquete;

  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<PaqueteServicio>> getAll() async => const [];

  @override
  Future<PaqueteServicio?> getById(String id) async => null;

  @override
  Future<List<PaqueteServicioItem>> getServiciosByPaquete(String paqueteId) async => const [];

  @override
  Future<void> removeServicioDePaquete({required String paqueteId, required String servicioId}) async {}

  @override
  Future<PaqueteServicio> update(PaqueteServicio paquete) async => paquete;
}
