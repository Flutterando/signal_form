import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

const _options = [
  SignalFieldOption<String>(value: 'sports', label: 'Esportes'),
  SignalFieldOption<String>(value: 'music', label: 'Música'),
  SignalFieldOption<String>(value: 'tech', label: 'Tecnologia'),
];

void main() {
  group('SignalFilterChip', () {
    testWidgets('renders one FilterChip per option', (tester) async {
      final field = Field<List<String>>('interests', []);
      await tester.pumpWidget(_wrap(SignalFilterChip<String>(
        field: field,
        options: _options,
      )));

      expect(find.byType(FilterChip), findsNWidgets(3));
    });

    testWidgets('renders option labels', (tester) async {
      final field = Field<List<String>>('interests', []);
      await tester.pumpWidget(_wrap(SignalFilterChip<String>(
        field: field,
        options: _options,
      )));

      expect(find.text('Esportes'), findsOneWidget);
      expect(find.text('Música'), findsOneWidget);
      expect(find.text('Tecnologia'), findsOneWidget);
    });

    testWidgets('initially selected values show chips as selected',
        (tester) async {
      final field = Field<List<String>>('interests', ['music']);
      await tester.pumpWidget(_wrap(SignalFilterChip<String>(
        field: field,
        options: _options,
      )));

      final chips =
          tester.widgetList<FilterChip>(find.byType(FilterChip)).toList();
      // options order: sports, music, tech
      expect(chips[0].selected, false);
      expect(chips[1].selected, true);
      expect(chips[2].selected, false);
    });

    testWidgets('tapping an unselected chip adds value to field',
        (tester) async {
      final field = Field<List<String>>('interests', []);
      await tester.pumpWidget(_wrap(SignalFilterChip<String>(
        field: field,
        options: _options,
      )));

      await tester.tap(find.text('Tecnologia'));
      await tester.pump();

      expect(field.value, contains('tech'));
    });

    testWidgets('tapping a selected chip removes value from field',
        (tester) async {
      final field = Field<List<String>>('interests', ['sports']);
      await tester.pumpWidget(_wrap(SignalFilterChip<String>(
        field: field,
        options: _options,
      )));

      await tester.tap(find.text('Esportes'));
      await tester.pump();

      expect(field.value, isNot(contains('sports')));
    });

    testWidgets('field is touched after interaction', (tester) async {
      final field = Field<List<String>>('interests', []);
      await tester.pumpWidget(_wrap(SignalFilterChip<String>(
        field: field,
        options: _options,
      )));

      await tester.tap(find.text('Música'));
      await tester.pump();

      expect(field.isTouched, true);
    });

    testWidgets('error is hidden before touch', (tester) async {
      final field = Field<List<String>>('interests', [])
          .minItems(1, message: 'Select at least one');
      await tester.pumpWidget(_wrap(SignalFilterChip<String>(
        field: field,
        options: _options,
        decoration: const InputDecoration(),
      )));

      expect(find.text('Select at least one'), findsNothing);
    });

    testWidgets('error appears after touch with empty selection', (tester) async {
      final field = Field<List<String>>('interests', [])
          .minItems(1, message: 'Select at least one');
      await tester.pumpWidget(_wrap(SignalFilterChip<String>(
        field: field,
        options: _options,
        decoration: const InputDecoration(),
      )));

      field.validate();


      field.touch();
      await tester.pumpAndSettle();

      expect(find.text('Select at least one'), findsOneWidget);
    });

    testWidgets('enabled = false disables all chips', (tester) async {
      final field = Field<List<String>>('interests', []);
      await tester.pumpWidget(_wrap(SignalFilterChip<String>(
        field: field,
        options: _options,
        enabled: false,
      )));

      for (final chip in tester.widgetList<FilterChip>(find.byType(FilterChip))) {
        expect(chip.onSelected, isNull);
      }
    });
  });
}
