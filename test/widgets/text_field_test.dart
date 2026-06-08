import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Field<String> _field([String? initial]) =>
    Field<String>('name', initial).required(message: 'Required');

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SignalTextField', () {
    testWidgets('renders a TextField', (tester) async {
      final field = _field();
      await tester.pumpWidget(_wrap(SignalTextField(field: field)));
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('initial value is displayed', (tester) async {
      final field = _field('hello');
      await tester.pumpWidget(_wrap(SignalTextField(field: field)));
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('typing updates field.value', (tester) async {
      final field = Field<String>('name');
      await tester.pumpWidget(_wrap(SignalTextField(field: field)));

      await tester.enterText(find.byType(TextField), 'flutter');
      expect(field.value, 'flutter');
    });

    testWidgets('onChanged callback is invoked', (tester) async {
      final field = Field<String>('name');
      String? received;
      await tester.pumpWidget(_wrap(SignalTextField(
        field: field,
        onChanged: (v) => received = v,
      )));

      await tester.enterText(find.byType(TextField), 'dart');
      expect(received, 'dart');
    });

    testWidgets('error is hidden before touch', (tester) async {
      final field = _field();
      await tester.pumpWidget(_wrap(SignalTextField(field: field)));

      expect(find.text('Required'), findsNothing);
    });

    testWidgets('error appears after losing focus', (tester) async {
      // Use onBlur mode so validation fires automatically on touch/blur
      final field = Field<String>('name')
          .required(message: 'Required')
          .validationMode(ValidationMode.onBlur);
      final otherFocus = FocusNode();

      await tester.pumpWidget(_wrap(Column(children: [
        SignalTextField(field: field),
        Focus(focusNode: otherFocus, child: const SizedBox()),
      ])));

      // Focus the text field then move focus away to trigger touch+validation
      await tester.tap(find.byType(TextField));
      await tester.pump();
      otherFocus.requestFocus();
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('error is hidden when field has a value after touch',
        (tester) async {
      final field = _field();
      await tester.pumpWidget(_wrap(SignalTextField(field: field)));

      await tester.enterText(find.byType(TextField), 'typed');
      field.touch();
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsNothing);
    });

    testWidgets('decoration label is rendered', (tester) async {
      final field = Field<String>('name');
      await tester.pumpWidget(_wrap(SignalTextField(
        field: field,
        decoration: const InputDecoration(labelText: 'Full name'),
      )));

      expect(find.text('Full name'), findsOneWidget);
    });

    testWidgets('enabled = false disables the TextField', (tester) async {
      final field = Field<String>('name');
      await tester.pumpWidget(
          _wrap(SignalTextField(field: field, enabled: false)));

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.enabled, false);
    });

    testWidgets('external field value change updates displayed text',
        (tester) async {
      final field = Field<String>('name', 'initial');
      await tester.pumpWidget(_wrap(SignalTextField(field: field)));

      field.value = 'updated';
      await tester.pump();

      expect(find.text('updated'), findsOneWidget);
    });

    testWidgets('obscureText is passed through', (tester) async {
      final field = Field<String>('password');
      await tester.pumpWidget(_wrap(
          SignalTextField(field: field, obscureText: true)));

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.obscureText, true);
    });

    testWidgets('uses provided focusNode', (tester) async {
      final field = Field<String>('name');
      final focusNode = FocusNode();
      await tester.pumpWidget(
          _wrap(SignalTextField(field: field, focusNode: focusNode)));

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.focusNode, focusNode);

      focusNode.dispose();
    });
  });
}
