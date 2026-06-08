import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';
import 'package:example/wizard_form/pages/wizard_page.dart';
import 'package:example/wizard_form/steps/account_step.dart';
import 'package:example/wizard_form/steps/personal_step.dart';
import 'package:example/wizard_form/steps/preferences_step.dart';
import 'package:example/wizard_form/steps/payment_step.dart';

void main() {
  testWidgets('WizardPage full multi-step navigation test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WizardPage()));

    // 1. Account Step
    expect(find.byType(AccountStep), findsOneWidget);

    // Fill out Account Step fields to pass validation
    await tester.enterText(
      find.widgetWithText(TextField, 'E-mail'),
      'test@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Senha'),
      'Password123',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirmar Senha'),
      'Password123',
    );
    await tester.pumpAndSettle();

    // Tap Next
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();

    // 2. Personal Step
    expect(find.byType(PersonalStep), findsOneWidget);

    // Fill out Personal Step fields
    await tester.enterText(
      find.widgetWithText(TextField, 'Nome Completo'),
      'John Doe',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Telefone'),
      '11999999999',
    );

    // Set a valid birth date (must be 18+)
    final datePicker = tester.widget<SignalDateTimePicker>(
      find.byType(SignalDateTimePicker),
    );
    datePicker.field.value = DateTime(2000, 1, 1);
    await tester.pumpAndSettle();

    // Tap Next
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();

    // 3. Preferences Step
    expect(find.byType(PreferencesStep), findsOneWidget);

    // Tap on an interest chip
    await tester.tap(find.text('Tecnologia'));
    await tester.pumpAndSettle();

    // Select referral source
    await tester.tap(find.text('Pesquisa no Google'));
    await tester.pumpAndSettle();

    // Accept terms
    final termsFinder = find.text('Aceito os Termos de Uso');
    await tester.ensureVisible(termsFinder);
    await tester.tap(termsFinder);
    await tester.pumpAndSettle();

    // Tap Next
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();

    // 4. Payment Step (New step!)
    expect(find.byType(PaymentStep), findsOneWidget);

    // Fill card details
    await tester.enterText(
      find.widgetWithText(TextField, 'Nome Impresso no Cartão'),
      'JOHN DOE',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Número do Cartão'),
      '4242424242424242',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Validade (MM/AA)'),
      '1229',
    );
    await tester.enterText(find.widgetWithText(TextField, 'CVV'), '123');
    await tester.pumpAndSettle();

    // Tap Finalize
    await tester.tap(find.text('Finalizar'));
    // Pump virtual time to allow debounce (800ms) and async validation (1200ms) to complete
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Check that success dialog appears
    expect(find.text('Cadastro Realizado!'), findsOneWidget);
  });
}
