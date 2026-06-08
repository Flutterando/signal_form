import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SignalDateRangePicker', () {
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2099, 12, 31);

    testWidgets('renders an InkWell and InputDecorator', (tester) async {
      final field = Field<DateTimeRange>('vacation');
      await tester.pumpWidget(
        _wrap(
          SignalDateRangePicker(
            field: field,
            firstDate: firstDate,
            lastDate: lastDate,
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
      expect(find.byType(InputDecorator), findsOneWidget);
    });

    testWidgets('empty text shown when no range selected', (tester) async {
      final field = Field<DateTimeRange>('vacation');
      await tester.pumpWidget(
        _wrap(
          SignalDateRangePicker(
            field: field,
            firstDate: firstDate,
            lastDate: lastDate,
          ),
        ),
      );

      final texts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(InputDecorator),
              matching: find.byType(Text),
            ),
          )
          .toList();
      expect(texts.any((t) => t.data == ''), isTrue);
    });

    testWidgets('formatted range shown when field has a value', (tester) async {
      final range = DateTimeRange(
        start: DateTime(2024, 1, 10),
        end: DateTime(2024, 1, 20),
      );
      final field = Field<DateTimeRange>('vacation', range);
      await tester.pumpWidget(
        _wrap(
          SignalDateRangePicker(
            field: field,
            firstDate: firstDate,
            lastDate: lastDate,
          ),
        ),
      );

      expect(find.text('2024-01-10 - 2024-01-20'), findsOneWidget);
    });

    testWidgets('decoration label is rendered', (tester) async {
      final field = Field<DateTimeRange>('vacation');
      await tester.pumpWidget(
        _wrap(
          SignalDateRangePicker(
            field: field,
            firstDate: firstDate,
            lastDate: lastDate,
            decoration: const InputDecoration(labelText: 'Férias'),
          ),
        ),
      );

      expect(find.text('Férias'), findsOneWidget);
    });

    testWidgets('error is hidden before touch', (tester) async {
      final field = Field<DateTimeRange>('vacation')
        ..required(message: 'Range required');
      await tester.pumpWidget(
        _wrap(
          SignalDateRangePicker(
            field: field,
            firstDate: firstDate,
            lastDate: lastDate,
            decoration: const InputDecoration(),
          ),
        ),
      );

      expect(find.text('Range required'), findsNothing);
    });

    testWidgets('error appears after touch with no value', (tester) async {
      final field = Field<DateTimeRange>('vacation')
        ..required(message: 'Range required');
      await tester.pumpWidget(
        _wrap(
          SignalDateRangePicker(
            field: field,
            firstDate: firstDate,
            lastDate: lastDate,
            decoration: const InputDecoration(),
          ),
        ),
      );

      field.validate();
      field.touch();
      await tester.pumpAndSettle();

      expect(find.text('Range required'), findsOneWidget);
    });

    testWidgets('enabled = false — tapping does not open picker', (
      tester,
    ) async {
      final field = Field<DateTimeRange>('vacation');
      await tester.pumpWidget(
        _wrap(
          SignalDateRangePicker(
            field: field,
            firstDate: firstDate,
            lastDate: lastDate,
            enabled: false,
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // The date range dialog should NOT appear
      expect(find.byType(DateRangePickerDialog), findsNothing);
    });

    testWidgets('tapping opens the date range picker dialog', (tester) async {
      final field = Field<DateTimeRange>('vacation');
      await tester.pumpWidget(
        _wrap(
          SignalDateRangePicker(
            field: field,
            firstDate: firstDate,
            lastDate: lastDate,
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.byType(DateRangePickerDialog), findsOneWidget);
    });

    testWidgets('external field value update refreshes displayed range', (
      tester,
    ) async {
      final field = Field<DateTimeRange>('vacation');
      await tester.pumpWidget(
        _wrap(
          SignalDateRangePicker(
            field: field,
            firstDate: firstDate,
            lastDate: lastDate,
          ),
        ),
      );

      field.value = DateTimeRange(
        start: DateTime(2025, 7, 1),
        end: DateTime(2025, 7, 15),
      );
      await tester.pump();

      expect(find.text('2025-07-01 - 2025-07-15'), findsOneWidget);
    });

    testWidgets('submit and toJson with SignalDateRangePicker', (tester) async {
      final form = formCtrl(
        () => (
          vacation: Field<DateTimeRange>(
            'vacation',
          ).required(message: 'Range required'),
        ),
      );

      await tester.pumpWidget(
        _wrap(
          SignalDateRangePicker(
            field: form.fields.vacation,
            firstDate: firstDate,
            lastDate: lastDate,
          ),
        ),
      );

      // Before set / submit
      expect(form.toJson(), {'vacation': null});

      var submitted = false;
      await form.submit((_) async => submitted = true);
      expect(submitted, isFalse); // invalid because of required validator

      // Set value
      final selectedRange = DateTimeRange(
        start: DateTime(2025, 7, 1),
        end: DateTime(2025, 7, 15),
      );
      form.fields.vacation.value = selectedRange;
      await tester.pump();

      // Check toJson
      expect(form.toJson(), {'vacation': selectedRange});

      // Submit should now succeed
      await form.submit((_) async => submitted = true);
      expect(submitted, isTrue);
    });
  });
}
