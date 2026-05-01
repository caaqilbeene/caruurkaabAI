import 'package:flutter_test/flutter_test.dart';

import 'package:caruurkaab_ai/main.dart';

void main() {
  testWidgets('MyApp shows the first onboarding screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Smart Learning for Kids'), findsOneWidget);
  });
}
