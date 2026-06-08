import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SignalFormField', () {
    testWidgets('builder is called with the field', (tester) async {
      final field = Field<String>('name', 'hello');
      String? receivedValue;

      await tester.pumpWidget(_wrap(SignalFormField<String>(
        field: field,
        builder: (context, f) {
          receivedValue = f.value;
          return Text(f.value ?? '');
        },
      )));

      expect(receivedValue, 'hello');
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('rebuilds when field value changes', (tester) async {
      final field = Field<String>('name', 'initial');

      await tester.pumpWidget(_wrap(SignalFormField<String>(
        field: field,
        builder: (context, f) => Text(f.value ?? ''),
      )));

      expect(find.text('initial'), findsOneWidget);

      field.value = 'updated';
      await tester.pump();

      expect(find.text('updated'), findsOneWidget);
      expect(find.text('initial'), findsNothing);
    });

    testWidgets('rebuilds when field is touched', (tester) async {
      final field = Field<String>('name').required(message: 'Obrigatório');
      bool touched = false;

      await tester.pumpWidget(_wrap(SignalFormField<String>(
        field: field,
        builder: (context, f) {
          touched = f.isTouched;
          return Text(f.isTouched ? 'touched' : 'not touched');
        },
      )));

      expect(find.text('not touched'), findsOneWidget);

      field.validate();


      field.touch();
      await tester.pumpAndSettle();

      expect(find.text('touched'), findsOneWidget);
      expect(touched, isTrue);
    });

    testWidgets('builder has access to field.error after touch', (tester) async {
      final field = Field<String>('name').required(message: 'Required');

      await tester.pumpWidget(_wrap(SignalFormField<String>(
        field: field,
        builder: (context, f) {
          return Text(f.isTouched && f.error != null ? f.error! : 'no error');
        },
      )));

      expect(find.text('no error'), findsOneWidget);

      field.validate();


      field.touch();
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('accepts arbitrary widget trees from builder', (tester) async {
      final field = Field<int>('count', 42);

      await tester.pumpWidget(_wrap(SignalFormField<int>(
        field: field,
        builder: (context, f) => Column(
          children: [
            Text('Value: ${f.value}'),
            const Icon(Icons.star),
          ],
        ),
      )));

      expect(find.text('Value: 42'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------

  group('SignalFieldOption', () {
    test('label shorthand creates a Text widget', () {
      const option = SignalFieldOption<String>(value: 'a', label: 'Alpha');
      expect(option.widget, isA<Text>());
      expect((option.widget as Text).data, 'Alpha');
    });

    test('child overrides label widget', () {
      final icon = const Icon(Icons.star);
      final option = SignalFieldOption<String>(value: 'b', child: icon);
      expect(option.widget, same(icon));
    });

    test('asserts at construction when neither label nor child is provided',
        () {
      expect(
        () => SignalFieldOption<String>(value: 'c'),
        throwsAssertionError,
      );
    });

    test('value is stored correctly for various types', () {
      const intOpt = SignalFieldOption<int>(value: 99, label: 'Ninety nine');
      expect(intOpt.value, 99);

      const boolOpt = SignalFieldOption<bool>(value: true, label: 'Yes');
      expect(boolOpt.value, true);
    });
  });
}
