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
