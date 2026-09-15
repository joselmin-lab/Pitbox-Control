import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitbox_control/features/trabajos/recepciones/presentation/widgets/signature_pad.dart';

void main() {
  testWidgets('SignatureThumbnail muestra placeholder cuando no hay firma', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SignatureThumbnail(trazos: <List<Offset>>[]),
        ),
      ),
    );

    expect(find.text('Sin firma'), findsOneWidget);
  });

  testWidgets('SignaturePad refleja firma capturada cuando recibe trazos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SignaturePad(
            title: 'Firma',
            helperText: 'Firma de prueba',
            trazos: const [
              [Offset(1, 1), Offset(2, 2)],
            ],
            onChanged: (_) {},
            repaintBoundaryKey: GlobalKey(),
          ),
        ),
      ),
    );

    expect(find.text('Estado: firma capturada.'), findsOneWidget);
    expect(find.text('Firma aquí'), findsNothing);
  });
}
