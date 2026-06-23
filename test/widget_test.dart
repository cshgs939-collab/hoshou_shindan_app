import 'package:flutter_test/flutter_test.dart';

import 'package:hoshou_shindan_app/main.dart';

void main() {
  testWidgets('Home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const HoshouShindanApp());

    expect(find.text('必要保障額診断'), findsOneWidget);
    expect(find.text('診断をはじめる'), findsOneWidget);
  });
}
