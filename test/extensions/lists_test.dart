import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

void main() {
  group('List Validators', () {
    test('required, minItems, maxItems, itemCount', () {
      final form = formCtrl(
        () => (
          tags: Field<List<String>>('tags')
              .required(message: 'Tags required')
              .minItems(2, message: 'At least 2')
              .maxItems(4, message: 'Max 4')
              .itemCount(3, message: 'Exactly 3'),
        ),
      );

      // Required check
      form.fields.tags.value = null;
      expect(form.fields.tags.validate(), isFalse);

      form.fields.tags.value = [];
      expect(form.fields.tags.validate(), isFalse);

      // minItems check (1 item)
      form.fields.tags.value = ['a'];
      expect(form.fields.tags.validate(), isFalse);
      expect(form.fields.tags.error, equals('At least 2'));

      // itemCount check (2 items but expects 3)
      form.fields.tags.value = ['a', 'b'];
      expect(form.fields.tags.validate(), isFalse);
      expect(form.fields.tags.error, equals('Exactly 3'));

      // 3 items - passes all
      form.fields.tags.value = ['a', 'b', 'c'];
      expect(form.fields.tags.validate(), isTrue);

      // maxItems check (5 items but max is 4)
      form.fields.tags.value = ['a', 'b', 'c', 'd', 'e'];
      expect(form.fields.tags.validate(), isFalse);
      expect(form.fields.tags.error, equals('Max 4'));
    });

    test('contains, addItem, removeItem, clear', () {
      final form = formCtrl(
        () => (
          roles: Field<List<String>>(
            'roles',
          ).contains('admin', message: 'Must contain admin'),
        ),
      );

      form.fields.roles.value = ['user', 'guest'];
      expect(form.fields.roles.validate(), isFalse);
      expect(form.fields.roles.error, equals('Must contain admin'));

      // addItem
      form.fields.roles.addItem('admin');
      expect(form.fields.roles.value, equals(['user', 'guest', 'admin']));
      expect(form.fields.roles.validate(), isTrue);

      // removeItem
      form.fields.roles.removeItem('user');
      expect(form.fields.roles.value, equals(['guest', 'admin']));

      // clear
      form.fields.roles.clear();
      expect(form.fields.roles.value, equals([]));
    });
  });
}
