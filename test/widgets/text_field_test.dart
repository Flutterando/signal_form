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

    testWidgets('works with typed and masked fields (e.g. Field<DateTime>)', (tester) async {
      DateTime? parseDate(String s) {
        final parts = s.split('/');
        if (parts.length != 3) return null;
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d == null || m == null || y == null) return null;
        return DateTime(y, m, d);
      }

      final field = Field<DateTime>('birth')
          .mask('##/##/####')
          .parse(parseDate);
      addTearDown(field.dispose);

      await tester.pumpWidget(_wrap(SignalTextField(field: field)));

      // Type an incomplete date
      await tester.enterText(find.byType(TextField), '2512');
      await tester.pump();
      expect(find.text('25/12'), findsOneWidget);
      expect(field.value, isNull);

      // Complete the date
      await tester.enterText(find.byType(TextField), '25121990');
      await tester.pump();
      expect(find.text('25/12/1990'), findsOneWidget);
      expect(field.value, equals(DateTime(1990, 12, 25)));
    });

    testWidgets('works end-to-end with computed and masked field (vacation schema)', (tester) async {
      final form = formCtrl(
        () => (
          startDate: Field<DateTime>('startDate')
            .mask('##/##/####')
            .parse((s) {
              final p = s.split('/');
              if (p.length != 3) return null;
              final year = int.tryParse(p[2]);
              final month = int.tryParse(p[1]);
              final day = int.tryParse(p[0]);
              if (year == null || month == null || day == null) return null;
              return DateTime(year, month, day);
            }),
          daysRequested: Field<int>('daysRequested', 15),
          returnDate: Field.computed<DateTime>('returnDate', (valueOf) {
            final start = valueOf<DateTime>('startDate').value;
            final days = valueOf<int>('daysRequested').value ?? 0;
            if (start == null) return null;
            return start.add(Duration(days: days));
          }).mask('##/##/####'),
        ),
      );
      addTearDown(form.dispose);

      await tester.pumpWidget(_wrap(Column(
        children: [
          SignalTextField(field: form.fields.startDate, key: const Key('start')),
          SignalTextField(field: form.fields.returnDate, key: const Key('return')),
        ],
      )));

      // Initially, return date is empty
      expect(find.byKey(const Key('return')), findsOneWidget);
      final returnTextField = tester.widget<TextField>(
        find.descendant(of: find.byKey(const Key('return')), matching: find.byType(TextField)),
      );
      expect(returnTextField.controller!.text, equals(''));

      // Enter start date
      await tester.enterText(
        find.descendant(of: find.byKey(const Key('start')), matching: find.byType(TextField)),
        '10082026',
      );
      await tester.pump();

      // Return date should be updated to 25/08/2026 (startDate: 10/08/2026 + 15 days)
      expect(returnTextField.controller!.text, equals('25/08/2026'));
      expect(form.fields.returnDate.value, equals(DateTime(2026, 8, 25)));

      // Change daysRequested
      form.fields.daysRequested.value = 30;
      await tester.pump();

      // Return date should be updated to 09/09/2026 (startDate: 10/08/2026 + 30 days)
      expect(returnTextField.controller!.text, equals('09/09/2026'));
      expect(form.fields.returnDate.value, equals(DateTime(2026, 9, 9)));
    });
  });
}
