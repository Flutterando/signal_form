import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('Signal Form Example Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our home page loaded with the correct navigation cards.
    expect(find.text('Explore Signal Form'), findsOneWidget);
    expect(find.text('Simple Login & Signup'), findsOneWidget);
    expect(find.text('Multi-Step Wizard'), findsOneWidget);
  });
}
