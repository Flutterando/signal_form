import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

void main() {
  group('Optimizations & Bug Fixes', () {
    test('errors cache works and returns identical map when unmodified', () {
      final form = formCtrl(
        () => (field: Field<String>('field')..invalidate('Some error')),
      );

      final errors1 = form.errors;
      final errors2 = form.errors;

      // In the optimized version, accessing errors twice returns the cached identical instance
      expect(identical(errors1, errors2), isTrue);

      // Mutating a field invalidates cache
      form.fields.field.value = 'newValue';
      final errors3 = form.errors;
      expect(identical(errors1, errors3), isFalse);
    });

    test('applyEach works safely with Set values', () {
      final form = formCtrl(
        () => (
          field: Field<Set<String>>(
            'field',
          ).applyEach<String>((f) => f.notEmpty()),
        ),
      );

      // With our fix, Set should be processed safely as Iterable and not crash with TypeError
      form.fields.field.value = {'a', 'b'};
      expect(form.fields.field.validate(), isTrue);

      form.fields.field.value = {'', 'b'};
      expect(form.fields.field.validate(), isFalse);
    });

    test('applyWhen is safe during builder execution when form is null', () {
      // In the builder, form is not yet set on fields, but changing a value shouldn't crash on activeCondition
      final form = formCtrl(() {
        final f1 = Field<String>('f1', 'no');
        final f2 = Field<String>('f2').applyWhen(
          (valueOf) => valueOf<String>('f1').value == 'yes',
          (f) => f.notEmpty(),
        );

        // Update value of f2 which triggers validation
        f2.value = '';
        expect(() => f2.validate(), returnsNormally);
        return (f1: f1, f2: f2);
      });

      expect(form.fields.f2.value, equals(''));
    });

    test(
      'validateAsync cancels active debounce timer to prevent version mismatches',
      () async {
        final field = Field<String>(
          'field',
        ).debounce(const Duration(milliseconds: 100));

        field.value = 'new_value'; // schedules validation

        // Call validateAsync explicitly (e.g. during submit)
        final validationFuture = field.validateAsync();

        // Wait for everything to complete
        await Future.delayed(const Duration(milliseconds: 150));

        final result = await validationFuture;
        // Since validateAsync cancelled the debounce timer, no extra validation should have triggered
        // and validationFuture should succeed without version mismatch aborts.
        expect(result, isTrue);
      },
    );
  });
}
