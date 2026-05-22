import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:caruurkaab_ai/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('MyApp shows the first onboarding screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    // Wait for the AuthGate splash delay to finish (2 seconds)
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Smart Learning for Kids'), findsOneWidget);
  });
}
