import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SignalDateTimePicker', () {
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2099, 12, 31);

    testWidgets('renders an InkWell and InputDecorator', (tester) async {
      final field = Field<DateTime>('birthDate');
      await tester.pumpWidget(_wrap(SignalDateTimePicker(
        field: field,
        firstDate: firstDate,
        lastDate: lastDate,
      )));

      expect(find.byType(InkWell), findsOneWidget);
      expect(find.byType(InputDecorator), findsOneWidget);
    });

    testWidgets('empty text shown when no date selected', (tester) async {
      final field = Field<DateTime>('birthDate');
      await tester.pumpWidget(_wrap(SignalDateTimePicker(
        field: field,
        firstDate: firstDate,
        lastDate: lastDate,
      )));

      // The Text widget inside InputDecorator shows ''
      final texts = tester
          .widgetList<Text>(find.descendant(
            of: find.byType(InputDecorator),
            matching: find.byType(Text),
          ))
          .toList();
      expect(texts.any((t) => t.data == ''), isTrue);
    });

    testWidgets('formatted date shown when field has a value', (tester) async {
      final date = DateTime(2023, 6, 15);
      final field = Field<DateTime>('birthDate', date);
      await tester.pumpWidget(_wrap(SignalDateTimePicker(
        field: field,
        firstDate: firstDate,
        lastDate: lastDate,
      )));

      expect(find.text('2023-06-15'), findsOneWidget);
    });

    testWidgets('decoration label is rendered', (tester) async {
      final field = Field<DateTime>('birthDate');
      await tester.pumpWidget(_wrap(SignalDateTimePicker(
        field: field,
        firstDate: firstDate,
        lastDate: lastDate,
        decoration: const InputDecoration(labelText: 'Data de nascimento'),
      )));

      expect(find.text('Data de nascimento'), findsOneWidget);
    });

    testWidgets('error is hidden before touch', (tester) async {
      final field =
          Field<DateTime>('birthDate').required(message: 'Date required');
      await tester.pumpWidget(_wrap(SignalDateTimePicker(
        field: field,
        firstDate: firstDate,
        lastDate: lastDate,
        decoration: const InputDecoration(),
      )));

      expect(find.text('Date required'), findsNothing);
    });

    testWidgets('error appears after touch with no value', (tester) async {
      final field =
          Field<DateTime>('birthDate').required(message: 'Date required');
      await tester.pumpWidget(_wrap(SignalDateTimePicker(
        field: field,
        firstDate: firstDate,
        lastDate: lastDate,
        decoration: const InputDecoration(),
      )));

      field.validate();


      field.touch();
      await tester.pumpAndSettle();

      expect(find.text('Date required'), findsOneWidget);
    });

    testWidgets('enabled = false — tapping does not open picker',
        (tester) async {
      final field = Field<DateTime>('birthDate');
      await tester.pumpWidget(_wrap(SignalDateTimePicker(
        field: field,
        firstDate: firstDate,
        lastDate: lastDate,
        enabled: false,
      )));

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Dialog should NOT appear
      expect(find.byType(DatePickerDialog), findsNothing);
    });

    testWidgets('tapping opens the date picker dialog', (tester) async {
      final field = Field<DateTime>('birthDate');
      await tester.pumpWidget(_wrap(SignalDateTimePicker(
        field: field,
        firstDate: firstDate,
        lastDate: lastDate,
      )));

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('external field value update refreshes displayed date',
        (tester) async {
      final field = Field<DateTime>('birthDate');
      await tester.pumpWidget(_wrap(SignalDateTimePicker(
        field: field,
        firstDate: firstDate,
        lastDate: lastDate,
      )));

      field.value = DateTime(2024, 3, 22);
      await tester.pump();

      expect(find.text('2024-03-22'), findsOneWidget);
    });
  });
}
