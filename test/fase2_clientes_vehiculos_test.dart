import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitbox_control/features/clientes/presentation/providers/clientes_provider.dart';
import 'package:pitbox_control/features/vehiculos/presentation/providers/vehiculos_provider.dart';

void main() {
  test('carga datos semilla de clientes y vehículos', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final clientes = await container.read(clientesProvider.future);
    final vehiculos = await container.read(vehiculosProvider.future);

    expect(clientes.length, 4);
    expect(vehiculos.length, 5);
  });

  test('al eliminar cliente se eliminan sus vehículos asociados', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(clientesProvider.future);
    await container.read(vehiculosProvider.future);

    final clienteId = container.read(clientesProvider).value!.first.id;
    final vehiculosAntes = container.read(vehiculosByClienteIdProvider(clienteId));
    expect(vehiculosAntes, isNotEmpty);

    await container.read(clientesProvider.notifier).delete(clienteId);

    final clienteEliminado = container.read(clienteByIdProvider(clienteId));
    final vehiculosDespues = container.read(vehiculosByClienteIdProvider(clienteId));

    expect(clienteEliminado, isNull);
    expect(vehiculosDespues, isEmpty);
  });
}
