import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

void main() {
  group('Numeric Validators', () {
    test('num greaterThan and lessThan', () {
      final form = formCtrl(
        () => (
          numGt: Field<num>('numGt').greaterThan(10),
          numLt: Field<num>('numLt').lessThan(10),
        ),
      );

      form.fields.numGt.value = 10;
      expect(form.fields.numGt.validate(), isFalse);
      form.fields.numGt.value = 11;
      expect(form.fields.numGt.validate(), isTrue);

      form.fields.numLt.value = 10;
      expect(form.fields.numLt.validate(), isFalse);
      form.fields.numLt.value = 9;
      expect(form.fields.numLt.validate(), isTrue);
    });

    test('int greaterThan and lessThan', () {
      final form = formCtrl(
        () => (
          intGt: Field<int>('intGt').greaterThan(10),
          intLt: Field<int>('intLt').lessThan(10),
        ),
      );

      form.fields.intGt.value = 10;
      expect(form.fields.intGt.validate(), isFalse);
      form.fields.intGt.value = 11;
      expect(form.fields.intGt.validate(), isTrue);

      form.fields.intLt.value = 10;
      expect(form.fields.intLt.validate(), isFalse);
      form.fields.intLt.value = 9;
      expect(form.fields.intLt.validate(), isTrue);
    });

    test('double greaterThan and lessThan', () {
      final form = formCtrl(
        () => (
          doubleGt: Field<double>('doubleGt').greaterThan(10.0),
          doubleLt: Field<double>('doubleLt').lessThan(10.0),
        ),
      );

      form.fields.doubleGt.value = 10.0;
      expect(form.fields.doubleGt.validate(), isFalse);
      form.fields.doubleGt.value = 10.1;
      expect(form.fields.doubleGt.validate(), isTrue);

      form.fields.doubleLt.value = 10.0;
      expect(form.fields.doubleLt.validate(), isFalse);
      form.fields.doubleLt.value = 9.9;
      expect(form.fields.doubleLt.validate(), isTrue);
    });

    test('nonnegative (num, int, double)', () {
      final form = formCtrl(
        () => (
          numField: Field<num>('numField').nonnegative(),
          intField: Field<int>('intField').nonnegative(),
          doubleField: Field<double>('doubleField').nonnegative(),
        ),
      );

      form.fields.numField.value = -1;
      expect(form.fields.numField.validate(), isFalse);
      form.fields.numField.value = 0;
      expect(form.fields.numField.validate(), isTrue);
      form.fields.numField.value = 1;
      expect(form.fields.numField.validate(), isTrue);

      form.fields.intField.value = -1;
      expect(form.fields.intField.validate(), isFalse);
      form.fields.intField.value = 0;
      expect(form.fields.intField.validate(), isTrue);
      form.fields.intField.value = 5;
      expect(form.fields.intField.validate(), isTrue);

      form.fields.doubleField.value = -0.1;
      expect(form.fields.doubleField.validate(), isFalse);
      form.fields.doubleField.value = 0.0;
      expect(form.fields.doubleField.validate(), isTrue);
      form.fields.doubleField.value = 0.1;
      expect(form.fields.doubleField.validate(), isTrue);
    });

    test('multipleOf and step (num)', () {
      final form = formCtrl(
        () => (
          multipleField: Field<num>('multipleField').multipleOf(3),
          stepField: Field<num>('stepField').step(5),
        ),
      );

      form.fields.multipleField.value = 7;
      expect(form.fields.multipleField.validate(), isFalse);
      form.fields.multipleField.value = 9;
      expect(form.fields.multipleField.validate(), isTrue);
      form.fields.multipleField.value = 0;
      expect(form.fields.multipleField.validate(), isTrue);

      form.fields.stepField.value = 3;
      expect(form.fields.stepField.validate(), isFalse);
      form.fields.stepField.value = 10;
      expect(form.fields.stepField.validate(), isTrue);
      form.fields.stepField.value = 25;
      expect(form.fields.stepField.validate(), isTrue);
    });

    test('multipleOf and step (int)', () {
      final form = formCtrl(
        () => (
          multipleField: Field<int>('multipleField').multipleOf(4),
          stepField: Field<int>('stepField').step(10),
        ),
      );

      form.fields.multipleField.value = 5;
      expect(form.fields.multipleField.validate(), isFalse);
      form.fields.multipleField.value = 8;
      expect(form.fields.multipleField.validate(), isTrue);
      form.fields.multipleField.value = 0;
      expect(form.fields.multipleField.validate(), isTrue);

      form.fields.stepField.value = 7;
      expect(form.fields.stepField.validate(), isFalse);
      form.fields.stepField.value = 20;
      expect(form.fields.stepField.validate(), isTrue);
    });

    test('multipleOf and step (double)', () {
      final form = formCtrl(
        () => (
          multipleField: Field<double>('multipleField').multipleOf(0.5),
          stepField: Field<double>('stepField').step(2.5),
        ),
      );

      form.fields.multipleField.value = 0.3;
      expect(form.fields.multipleField.validate(), isFalse);
      form.fields.multipleField.value = 1.5;
      expect(form.fields.multipleField.validate(), isTrue);
      form.fields.multipleField.value = 2.0;
      expect(form.fields.multipleField.validate(), isTrue);

      form.fields.stepField.value = 1.0;
      expect(form.fields.stepField.validate(), isFalse);
      form.fields.stepField.value = 5.0;
      expect(form.fields.stepField.validate(), isTrue);
    });
  });
}
