import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

void main() {
  group('DateTimeRange Validators', () {
    final baseStart = DateTime(2026, 6, 5);
    final baseEnd = DateTime(2026, 6, 10);
    final baseRange = DateTimeRange(start: baseStart, end: baseEnd);

    test('required', () {
      final form = formCtrl(
        () => (
          range: Field<DateTimeRange>('range').required(message: 'Required'),
        ),
      );

      expect(form.fields.range.validate(), isFalse);
      form.fields.range.value = baseRange;
      expect(form.fields.range.validate(), isTrue);
    });

    test('minDuration and maxDuration', () {
      final form = formCtrl(
        () => (
          min: Field<DateTimeRange>('min')
              .minDuration(const Duration(days: 4), message: 'Too short'),
          max: Field<DateTimeRange>('max')
              .maxDuration(const Duration(days: 6), message: 'Too long'),
        ),
      );

      // Duration: 2 days (< 4) -> fails min, passes max
      form.fields.min.value = DateTimeRange(
        start: baseStart,
        end: baseStart.add(const Duration(days: 2)),
      );
      form.fields.max.value = DateTimeRange(
        start: baseStart,
        end: baseStart.add(const Duration(days: 2)),
      );
      expect(form.fields.min.validate(), isFalse);
      expect(form.fields.max.validate(), isTrue);

      // Duration: 5 days (>= 4 and <= 6) -> both pass
      form.fields.min.value = baseRange;
      form.fields.max.value = baseRange;
      expect(form.fields.min.validate(), isTrue);
      expect(form.fields.max.validate(), isTrue);

      // Duration: 8 days (> 6) -> passes min, fails max
      form.fields.min.value = DateTimeRange(
        start: baseStart,
        end: baseStart.add(const Duration(days: 8)),
      );
      form.fields.max.value = DateTimeRange(
        start: baseStart,
        end: baseStart.add(const Duration(days: 8)),
      );
      expect(form.fields.min.validate(), isTrue);
      expect(form.fields.max.validate(), isFalse);
    });

    test('startsAfter and startsBefore', () {
      final dateLimit = DateTime(2026, 6, 4);
      final form = formCtrl(
        () => (
          after: Field<DateTimeRange>('after')
              .startsAfter(dateLimit, message: 'After'),
          before: Field<DateTimeRange>('before')
              .startsBefore(dateLimit, message: 'Before'),
        ),
      );

      // Range starts on 2026-06-05 (> 2026-06-04) -> passes after, fails before
      form.fields.after.value = baseRange;
      form.fields.before.value = baseRange;
      expect(form.fields.after.validate(), isTrue);
      expect(form.fields.before.validate(), isFalse);

      // Range starts on 2026-06-03 (< 2026-06-04) -> fails after, passes before
      final earlyRange = DateTimeRange(
        start: DateTime(2026, 6, 3),
        end: DateTime(2026, 6, 6),
      );
      form.fields.after.value = earlyRange;
      form.fields.before.value = earlyRange;
      expect(form.fields.after.validate(), isFalse);
      expect(form.fields.before.validate(), isTrue);
    });

    test('endsAfter and endsBefore', () {
      final dateLimit = DateTime(2026, 6, 9);
      final form = formCtrl(
        () => (
          after: Field<DateTimeRange>('after')
              .endsAfter(dateLimit, message: 'After'),
          before: Field<DateTimeRange>('before')
              .endsBefore(dateLimit, message: 'Before'),
        ),
      );

      // Range ends on 2026-06-10 (> 2026-06-09) -> passes after, fails before
      form.fields.after.value = baseRange;
      form.fields.before.value = baseRange;
      expect(form.fields.after.validate(), isTrue);
      expect(form.fields.before.validate(), isFalse);

      // Range ends on 2026-06-08 (< 2026-06-09) -> fails after, passes before
      final earlyRange = DateTimeRange(
        start: DateTime(2026, 6, 3),
        end: DateTime(2026, 6, 8),
      );
      form.fields.after.value = earlyRange;
      form.fields.before.value = earlyRange;
      expect(form.fields.after.validate(), isFalse);
      expect(form.fields.before.validate(), isTrue);
    });
  });
}
