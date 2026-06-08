import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

const _options = [
  SignalFieldOption<String>(value: 'male', label: 'Masculino'),
  SignalFieldOption<String>(value: 'female', label: 'Feminino'),
  SignalFieldOption<String>(value: 'other', label: 'Outro'),
];

void main() {
  group('SignalRadioGroup', () {
    testWidgets('renders one Radio per option', (tester) async {
      final field = Field<String>('gender');
      await tester.pumpWidget(_wrap(SignalRadioGroup<String>(
        field: field,
        options: _options,
      )));

      expect(find.byType(Radio<String>), findsNWidgets(3));
    });

    testWidgets('renders option labels', (tester) async {
      final field = Field<String>('gender');
      await tester.pumpWidget(_wrap(SignalRadioGroup<String>(
        field: field,
        options: _options,
      )));

      expect(find.text('Masculino'), findsOneWidget);
      expect(find.text('Feminino'), findsOneWidget);
      expect(find.text('Outro'), findsOneWidget);
    });

    testWidgets('tapping label updates field value', (tester) async {
      final field = Field<String>('gender');
      await tester.pumpWidget(_wrap(SignalRadioGroup<String>(
        field: field,
        options: _options,
      )));

      await tester.tap(find.text('Feminino'));
      await tester.pump();

      expect(field.value, 'female');
    });

    testWidgets('field is touched after tapping', (tester) async {
      final field = Field<String>('gender');
      await tester.pumpWidget(_wrap(SignalRadioGroup<String>(
        field: field,
        options: _options,
      )));

      await tester.tap(find.text('Outro'));
      await tester.pump();

      expect(field.isTouched, true);
    });

    testWidgets('selecting a different option updates field value',
        (tester) async {
      final field = Field<String>('gender', 'male');
      await tester.pumpWidget(_wrap(SingleChildScrollView(
        child: SignalRadioGroup<String>(
          field: field,
          options: _options,
        ),
      )));

      await tester.tap(find.text('Outro'));
      await tester.pump();

      expect(field.value, 'other');
    });

    testWidgets('error is hidden before touch', (tester) async {
      final field =
          Field<String>('gender').required(message: 'Select one');
      await tester.pumpWidget(_wrap(SignalRadioGroup<String>(
        field: field,
        options: _options,
        decoration: const InputDecoration(),
      )));

      expect(find.text('Select one'), findsNothing);
    });

    testWidgets('error appears after touch with no value', (tester) async {
      final field =
          Field<String>('gender').required(message: 'Select one');
      await tester.pumpWidget(_wrap(SignalRadioGroup<String>(
        field: field,
        options: _options,
        decoration: const InputDecoration(),
      )));

      field.validate();


      field.touch();
      await tester.pumpAndSettle();

      expect(find.text('Select one'), findsOneWidget);
    });

    testWidgets('enabled = false disables all radios', (tester) async {
      final field = Field<String>('gender');
      await tester.pumpWidget(_wrap(SignalRadioGroup<String>(
        field: field,
        options: _options,
        enabled: false,
      )));

      for (final r in tester.widgetList<Radio<String>>(find.byType(Radio<String>))) {
        expect(r.enabled, false);
      }
    });

    testWidgets('horizontal orientation wraps radios in Wrap', (tester) async {
      final field = Field<String>('gender');
      await tester.pumpWidget(_wrap(SignalRadioGroup<String>(
        field: field,
        options: _options,
        orientation: Axis.horizontal,
      )));

      expect(find.byType(Wrap), findsWidgets);
    });
  });
}
