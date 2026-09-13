import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitbox_control/features/configuracion/servicios/domain/models/servicio.dart';
import 'package:pitbox_control/features/configuracion/servicios/presentation/widgets/servicios_selector.dart';

void main() {
  testWidgets('filtra servicios por nombre o categoría y muestra estado vacío', (tester) async {
    await tester.pumpWidget(
      _TestHost(
        servicios: _serviciosDemo,
      ),
    );

    expect(find.text('Cambio de aceite'), findsOneWidget);
    expect(find.text('Lavado'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'mant');
    await tester.pumpAndSettle();

    expect(find.text('Cambio de aceite'), findsOneWidget);
    expect(find.text('Lavado'), findsNothing);

    await tester.enterText(find.byType(TextField), 'no existe');
    await tester.pumpAndSettle();

    expect(find.text('No se encontraron servicios.'), findsOneWidget);
  });

  testWidgets('mantiene seleccionados aunque queden fuera del filtro', (tester) async {
    await tester.pumpWidget(
      _TestHost(
        servicios: _serviciosDemo,
      ),
    );

    await tester.tap(find.widgetWithText(CheckboxListTile, 'Cambio de aceite'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'lavado');
    await tester.pumpAndSettle();
    expect(find.text('Cambio de aceite'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    final tile = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Cambio de aceite'),
    );
    expect(tile.value, isTrue);
  });
}

class _TestHost extends StatefulWidget {
  const _TestHost({required this.servicios});

  final List<Servicio> servicios;

  @override
  State<_TestHost> createState() => _TestHostState();
}

class _TestHostState extends State<_TestHost> {
  Map<String, int> _seleccion = <String, int>{};

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ServiciosSelector(
          servicios: widget.servicios,
          seleccion: _seleccion,
          onChanged: (next) => setState(() => _seleccion = next),
        ),
      ),
    );
  }
}

final List<Servicio> _serviciosDemo = [
  Servicio(
    id: 's1',
    nombre: 'Cambio de aceite',
    categoria: 'Mantenimiento',
    precio: 100,
    activo: true,
    fechaCreacion: DateTime(2026, 1, 1),
  ),
  Servicio(
    id: 's2',
    nombre: 'Lavado',
    categoria: 'Estética',
    precio: 50,
    activo: true,
    fechaCreacion: DateTime(2026, 1, 2),
  ),
];
