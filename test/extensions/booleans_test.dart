import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

void main() {
  group('Boolean Validators', () {
    test('mustBeTrue', () {
      final form = formCtrl(
        () => (terms: Field<bool>('terms').mustBeTrue(message: 'Accept terms')),
      );

      form.fields.terms.value = false;
      expect(form.fields.terms.validate(), isFalse);
      expect(form.fields.terms.error, equals('Accept terms'));

      form.fields.terms.value = true;
      expect(form.fields.terms.validate(), isTrue);
    });

    test('mustBeFalse', () {
      final form = formCtrl(
        () => (
          blocked: Field<bool>(
            'blocked',
          ).mustBeFalse(message: 'Must not be blocked'),
        ),
      );

      form.fields.blocked.value = true;
      expect(form.fields.blocked.validate(), isFalse);
      expect(form.fields.blocked.error, equals('Must not be blocked'));

      form.fields.blocked.value = false;
      expect(form.fields.blocked.validate(), isTrue);
    });

    test('required', () {
      final form = formCtrl(
        () => (
          choice: Field<bool>('choice').required(message: 'Choose yes or no'),
        ),
      );

      form.fields.choice.value = null;
      expect(form.fields.choice.validate(), isFalse);

      form.fields.choice.value = false;
      expect(form.fields.choice.validate(), isTrue);
    });
  });
}
