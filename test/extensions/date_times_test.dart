import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

void main() {
  group('DateTime Validators', () {
    final base = DateTime(2026, 6, 5);

    test('greaterThanOrEqualTo and greaterThan', () {
      final form = formCtrl(
        () => (
          gte: Field<DateTime>(
            'gte',
          ).greaterThanOrEqualTo(base, message: 'message'),
          gt: Field<DateTime>('gt').greaterThan(base, message: 'message'),
        ),
      );

      form.fields.gte.value = base.subtract(const Duration(days: 1));
      expect(form.fields.gte.validate(), isFalse);
      form.fields.gte.value = base;
      expect(form.fields.gte.validate(), isTrue);

      form.fields.gt.value = base;
      expect(form.fields.gt.validate(), isFalse);
      form.fields.gt.value = base.add(const Duration(days: 1));
      expect(form.fields.gt.validate(), isTrue);
    });

    test('lessThanOrEqualTo and lessThan', () {
      final form = formCtrl(
        () => (
          lte: Field<DateTime>(
            'lte',
          ).lessThanOrEqualTo(base, message: 'message'),
          lt: Field<DateTime>('lt').lessThan(base, message: 'message'),
        ),
      );

      form.fields.lte.value = base.add(const Duration(days: 1));
      expect(form.fields.lte.validate(), isFalse);
      form.fields.lte.value = base;
      expect(form.fields.lte.validate(), isTrue);

      form.fields.lt.value = base;
      expect(form.fields.lt.validate(), isFalse);
      form.fields.lt.value = base.subtract(const Duration(days: 1));
      expect(form.fields.lt.validate(), isTrue);
    });

    test('inclusiveBetween and exclusiveBetween', () {
      final start = DateTime(2026, 6, 1);
      final end = DateTime(2026, 6, 10);
      final form = formCtrl(
        () => (
          inc: Field<DateTime>('inc').inclusiveBetween(start, end),
          exc: Field<DateTime>('exc').exclusiveBetween(start, end),
        ),
      );

      form.fields.inc.value = start.subtract(const Duration(days: 1));
      expect(form.fields.inc.validate(), isFalse);
      form.fields.inc.value = start;
      expect(form.fields.inc.validate(), isTrue);
      form.fields.inc.value = end;
      expect(form.fields.inc.validate(), isTrue);

      form.fields.exc.value = start;
      expect(form.fields.exc.validate(), isFalse);
      form.fields.exc.value = end;
      expect(form.fields.exc.validate(), isFalse);
      form.fields.exc.value = DateTime(2026, 6, 5);
      expect(form.fields.exc.validate(), isTrue);
    });
  });
}
