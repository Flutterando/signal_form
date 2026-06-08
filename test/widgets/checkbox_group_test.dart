import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

const _options = [
  SignalFieldOption<String>(value: 'dart', label: 'Dart'),
  SignalFieldOption<String>(value: 'flutter', label: 'Flutter'),
  SignalFieldOption<String>(value: 'firebase', label: 'Firebase'),
];

void main() {
  group('SignalCheckboxGroup', () {
    testWidgets('renders one Checkbox per option', (tester) async {
      final field = Field<List<String>>('skills', []);
      await tester.pumpWidget(_wrap(SignalCheckboxGroup<String>(
        field: field,
        options: _options,
      )));

      expect(find.byType(Checkbox), findsNWidgets(3));
    });

    testWidgets('renders option labels', (tester) async {
      final field = Field<List<String>>('skills', []);
      await tester.pumpWidget(_wrap(SignalCheckboxGroup<String>(
        field: field,
        options: _options,
      )));

      expect(find.text('Dart'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Firebase'), findsOneWidget);
    });

    testWidgets('initially selected values are checked', (tester) async {
      final field = Field<List<String>>('skills', ['dart']);
      await tester.pumpWidget(_wrap(SignalCheckboxGroup<String>(
        field: field,
        options: _options,
      )));

      final checkboxes =
          tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      // Dart is the first option -> first Checkbox
      expect(checkboxes[0].value, true);
      expect(checkboxes[1].value, false);
      expect(checkboxes[2].value, false);
    });

    testWidgets('tapping an unchecked option adds value to field',
        (tester) async {
      final field = Field<List<String>>('skills', []);
      await tester.pumpWidget(_wrap(SignalCheckboxGroup<String>(
        field: field,
        options: _options,
      )));

      await tester.tap(find.text('Flutter'));
      await tester.pump();

      expect(field.value, contains('flutter'));
    });

    testWidgets('tapping a checked option removes value from field',
        (tester) async {
      final field = Field<List<String>>('skills', ['flutter']);
      await tester.pumpWidget(_wrap(SignalCheckboxGroup<String>(
        field: field,
        options: _options,
      )));

      await tester.tap(find.text('Flutter'));
      await tester.pump();

      expect(field.value, isNot(contains('flutter')));
    });

    testWidgets('multiple selections are accumulated', (tester) async {
      final field = Field<List<String>>('skills', []);
      await tester.pumpWidget(_wrap(SignalCheckboxGroup<String>(
        field: field,
        options: _options,
      )));

      await tester.tap(find.text('Dart'));
      await tester.pump();
      await tester.tap(find.text('Firebase'));
      await tester.pump();

      expect(field.value, containsAll(['dart', 'firebase']));
    });

    testWidgets('error is hidden before touch', (tester) async {
      final field =
          Field<List<String>>('skills', []).minItems(1, message: 'Choose one');
      await tester.pumpWidget(_wrap(SignalCheckboxGroup<String>(
        field: field,
        options: _options,
        decoration: const InputDecoration(),
      )));

      expect(find.text('Choose one'), findsNothing);
    });

    testWidgets('error appears after touch with empty selection',
        (tester) async {
      final field =
          Field<List<String>>('skills', []).minItems(1, message: 'Choose one');
      await tester.pumpWidget(_wrap(SignalCheckboxGroup<String>(
        field: field,
        options: _options,
        decoration: const InputDecoration(),
      )));

      field.validate();


      field.touch();
      await tester.pumpAndSettle();

      expect(find.text('Choose one'), findsOneWidget);
    });

    testWidgets('enabled = false disables all checkboxes', (tester) async {
      final field = Field<List<String>>('skills', []);
      await tester.pumpWidget(_wrap(SignalCheckboxGroup<String>(
        field: field,
        options: _options,
        enabled: false,
      )));

      for (final cb in tester.widgetList<Checkbox>(find.byType(Checkbox))) {
        expect(cb.onChanged, isNull);
      }
    });

    testWidgets('horizontal orientation wraps chips in Wrap', (tester) async {
      final field = Field<List<String>>('skills', []);
      await tester.pumpWidget(_wrap(SignalCheckboxGroup<String>(
        field: field,
        options: _options,
        orientation: Axis.horizontal,
      )));

      expect(find.byType(Wrap), findsWidgets);
    });
  });
}
