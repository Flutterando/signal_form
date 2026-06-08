import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

void main() {
  testWidgets('trigger() marks matching fields as touched', (
    WidgetTester tester,
  ) async {
    final form = formCtrl(
      () => (
        email: Field<String>('email').required(message: 'Required'),
        password: Field<String>('password').required(message: 'Required'),
      ),
    );

    // Initial state: not touched, no error displayed
    expect(form.fields.email.isTouched, isFalse);
    expect(form.fields.password.isTouched, isFalse);

    // Trigger validation
    final isValid = await form.trigger();

    expect(isValid, isFalse);
    expect(form.fields.email.isTouched, isTrue);
    expect(form.fields.password.isTouched, isTrue);
    expect(form.fields.email.error, equals('Required'));
  });

  testWidgets('trigger(path) marks only matching step fields as touched', (
    WidgetTester tester,
  ) async {
    final form = formCtrl(
      () => (
        account: formGroup(
          'account',
          () => (email: Field<String>('email').required(message: 'Required')),
        ),
        personal: formGroup(
          'personal',
          () => (name: Field<String>('name').required(message: 'Required')),
        ),
      ),
    );

    // Initial state
    expect(form.fields.account.email.isTouched, isFalse);
    expect(form.fields.personal.name.isTouched, isFalse);

    // Trigger only account
    final isValid = await form.trigger(path: 'account');

    expect(isValid, isFalse);
    expect(form.fields.account.email.isTouched, isTrue);
    expect(form.fields.personal.name.isTouched, isFalse);
  });

  testWidgets(
    'trigger(shouldFocus: true) requests focus on the first invalid field',
    (WidgetTester tester) async {
      final emailFocusNode = FocusNode();
      final passwordFocusNode = FocusNode();

      final form = formCtrl(
        () => (
          email: Field<String>('email').required(message: 'Required'),
          password: Field<String>('password').required(message: 'Required'),
        ),
      );

      form.fields.email.focusNode = emailFocusNode;
      form.fields.password.focusNode = passwordFocusNode;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              Focus(focusNode: emailFocusNode, child: const SizedBox()),
              Focus(focusNode: passwordFocusNode, child: const SizedBox()),
            ],
          ),
        ),
      );

      // Initial state: neither has focus
      expect(emailFocusNode.hasFocus, isFalse);
      expect(passwordFocusNode.hasFocus, isFalse);

      // Trigger validation with shouldFocus: true
      final isValid = await form.trigger(shouldFocus: true);
      await tester.pump();

      expect(isValid, isFalse);
      expect(emailFocusNode.hasFocus, isTrue);
      expect(passwordFocusNode.hasFocus, isFalse);
    },
  );
}
