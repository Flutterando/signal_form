import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

void main() {
  group('Generic Validators', () {
    test('must', () {
      final form = formCtrl(
        () => (
          field: Field<int>(
            'field',
          ).must((val) => val != null && val >= 18, message: 'Underage'),
        ),
      );
      form.fields.field.value = 17;
      expect(form.fields.field.validate(), isFalse);
      expect(form.fields.field.error, equals('Underage'));

      form.fields.field.value = 18;
      expect(form.fields.field.validate(), isTrue);
      expect(form.fields.field.error, isNull);
    });

    test('mustWith', () {
      final form = formCtrl(
        () => (
          age: Field<int>('age'),
          consent: Field<bool>('consent').mustWith((val, valueOf) {
            final ageVal = valueOf<int>('age').value;
            if (ageVal != null && ageVal < 18) {
              return val == true;
            }
            return true;
          }, message: 'Underage requires consent'),
        ),
      );

      form.fields.age.value = 16;
      form.fields.consent.value = false;
      expect(form.fields.consent.validate(), isFalse);

      form.fields.consent.value = true;
      expect(form.fields.consent.validate(), isTrue);
    });

    test('equalTo', () {
      final form = formCtrl(
        () => (field: Field<String>('field').equalTo('secret')),
      );
      form.fields.field.value = 'wrong';
      expect(form.fields.field.validate(), isFalse);

      form.fields.field.value = 'secret';
      expect(form.fields.field.validate(), isTrue);
    });

    test('isNull', () {
      final form = formCtrl(() => (field: Field<String>('field').isNull()));
      form.fields.field.value = 'not null';
      expect(form.fields.field.validate(), isFalse);

      form.fields.field.value = null;
      expect(form.fields.field.validate(), isTrue);
    });

    test('isNotNull', () {
      final form = formCtrl(() => (field: Field<String>('field').isNotNull()));
      form.fields.field.value = null;
      expect(form.fields.field.validate(), isFalse);

      form.fields.field.value = 'value';
      expect(form.fields.field.validate(), isTrue);
    });
  });
}
