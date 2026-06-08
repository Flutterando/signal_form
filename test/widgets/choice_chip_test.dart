import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

const _options = [
  SignalFieldOption<String>(value: 'basic', label: 'Básico'),
  SignalFieldOption<String>(value: 'pro', label: 'Pro'),
  SignalFieldOption<String>(value: 'enterprise', label: 'Enterprise'),
];

void main() {
  group('SignalChoiceChip', () {
    testWidgets('renders one ChoiceChip per option', (tester) async {
      final field = Field<String>('plan');
      await tester.pumpWidget(_wrap(SignalChoiceChip<String>(
        field: field,
        options: _options,
      )));

      expect(find.byType(ChoiceChip), findsNWidgets(3));
    });

    testWidgets('renders option labels', (tester) async {
      final field = Field<String>('plan');
      await tester.pumpWidget(_wrap(SignalChoiceChip<String>(
        field: field,
        options: _options,
      )));

      expect(find.text('Básico'), findsOneWidget);
      expect(find.text('Pro'), findsOneWidget);
      expect(find.text('Enterprise'), findsOneWidget);
    });

    testWidgets('initial value marks the matching chip as selected',
        (tester) async {
      final field = Field<String>('plan', 'pro');
      await tester.pumpWidget(_wrap(SignalChoiceChip<String>(
        field: field,
        options: _options,
      )));

      final chips =
          tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
      // options order: basic, pro, enterprise
      expect(chips[0].selected, false);
      expect(chips[1].selected, true);
      expect(chips[2].selected, false);
    });

    testWidgets('tapping a chip writes its value to the field', (tester) async {
      final field = Field<String>('plan');
      await tester.pumpWidget(_wrap(SignalChoiceChip<String>(
        field: field,
        options: _options,
      )));

      await tester.tap(find.text('Enterprise'));
      await tester.pump();

      expect(field.value, 'enterprise');
    });

    testWidgets('tapping the already-selected chip deselects (null)',
        (tester) async {
      final field = Field<String>('plan', 'pro');
      await tester.pumpWidget(_wrap(SignalChoiceChip<String>(
        field: field,
        options: _options,
      )));

      await tester.tap(find.text('Pro'));
      await tester.pump();

      expect(field.value, isNull);
    });

    testWidgets('field is touched after tap', (tester) async {
      final field = Field<String>('plan');
      await tester.pumpWidget(_wrap(SignalChoiceChip<String>(
        field: field,
        options: _options,
      )));

      await tester.tap(find.text('Básico'));
      await tester.pump();

      expect(field.isTouched, true);
    });

    testWidgets('error is hidden before touch', (tester) async {
      final field =
          Field<String>('plan').required(message: 'Required plan');
      await tester.pumpWidget(_wrap(SignalChoiceChip<String>(
        field: field,
        options: _options,
        decoration: const InputDecoration(),
      )));

      expect(find.text('Required plan'), findsNothing);
    });

    testWidgets('error appears after touch with no value', (tester) async {
      final field =
          Field<String>('plan').required(message: 'Required plan');
      await tester.pumpWidget(_wrap(SignalChoiceChip<String>(
        field: field,
        options: _options,
        decoration: const InputDecoration(),
      )));

      field.validate();


      field.touch();
      await tester.pumpAndSettle();

      expect(find.text('Required plan'), findsOneWidget);
    });

    testWidgets('enabled = false disables all chips', (tester) async {
      final field = Field<String>('plan');
      await tester.pumpWidget(_wrap(SignalChoiceChip<String>(
        field: field,
        options: _options,
        enabled: false,
      )));

      for (final chip in tester.widgetList<ChoiceChip>(find.byType(ChoiceChip))) {
        expect(chip.onSelected, isNull);
      }
    });

    testWidgets('selecting a new chip replaces the previous value',
        (tester) async {
      final field = Field<String>('plan', 'basic');
      await tester.pumpWidget(_wrap(SignalChoiceChip<String>(
        field: field,
        options: _options,
      )));

      await tester.tap(find.text('Pro'));
      await tester.pump();

      expect(field.value, 'pro');
    });
  });
}
