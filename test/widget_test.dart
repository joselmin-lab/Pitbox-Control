import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pitbox_control/main.dart';
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
}
