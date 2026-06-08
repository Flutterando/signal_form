import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/simple_form/simple_form_page.dart';
import 'package:example/simple_form/login_form.dart';
import 'package:example/simple_form/register_form.dart';

void main() {
  testWidgets('SimpleFormPage TabBarView switching test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SimpleFormPage()));

    // Initial state: LoginForm should be visible, RegisterForm should not be visible yet
    expect(find.byType(LoginForm), findsOneWidget);
    expect(find.byType(RegisterForm), findsNothing);

    // Tap the 'Cadastrar' tab
    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    // After switching, RegisterForm should be visible, LoginForm should not
    expect(find.byType(RegisterForm), findsOneWidget);
    expect(find.byType(LoginForm), findsNothing);

    // Tap the 'Entrar' tab
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    // Should switch back to LoginForm
    expect(find.byType(LoginForm), findsOneWidget);
    expect(find.byType(RegisterForm), findsNothing);
  });
}
