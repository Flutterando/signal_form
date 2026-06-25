import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

void main() {
  // ===========================================================================
  // Feature 1 – field.parse(fn)
  // ===========================================================================
  group('Field – parse(fn)', () {
    test('string value is parsed to typed value on Field<int>', () {
      final field = Field<int>('age').parse(int.tryParse);
      addTearDown(field.dispose);
      field.value = '25';
      expect(field.value, equals(25));
    });

    test('invalid string stores null', () {
      final field = Field<int>('age').parse(int.tryParse);
      addTearDown(field.dispose);
      field.value = 'abc';
      expect(field.value, isNull);
    });

    test('parse + validate works together on Field<int>', () {
      final field = Field<int>('age')
          .parse(int.tryParse)
          .addValidator('Obrigatório', (v) => v == null)
          .addValidator('Maior de 18', (v) => v != null && v < 18);
      addTearDown(field.dispose);

      field.value = '25';
      expect(field.validate(), isTrue);
      expect(field.value, equals(25));

      field.value = '10';
      expect(field.validate(), isFalse);
      expect(field.error, equals('Maior de 18'));
    });

    test('mask runs before parse on Field<DateTime>', () {
      DateTime? parseDate(String s) {
        final parts = s.split('/');
        if (parts.length != 3) return null;
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d == null || m == null || y == null) return null;
        return DateTime(y, m, d);
      }

      final field = Field<DateTime>(
        'birth',
      ).mask('##/##/####').parse(parseDate);
      addTearDown(field.dispose);

      field.value = '25121990';
      expect(field.value, equals(DateTime(1990, 12, 25)));
    });

    test('typed assignment still works without parse', () {
      final field = Field<int>('age');
      addTearDown(field.dispose);
      field.value = 99;
      expect(field.value, equals(99));
    });
  });

  // ===========================================================================
  // Feature 2 – field.transform(fn)
  // ===========================================================================
  group('Field – transform(fn)', () {
    test('value is normalized before storing (trim)', () {
      final field = Field<String>('email').transform((v) => v?.trim());
      addTearDown(field.dispose);
      field.value = '  alice@example.com  ';
      expect(field.value, equals('alice@example.com'));
    });

    test('transform runs on every assignment', () {
      final field = Field<String>('tag').transform((v) => v?.toLowerCase());
      addTearDown(field.dispose);
      field.value = 'Flutter';
      expect(field.value, equals('flutter'));
      field.value = 'DART';
      expect(field.value, equals('dart'));
    });

    test('transform with trim and lowercase combined', () {
      final field = Field<String>(
        'name',
      ).transform((v) => v?.trim().toLowerCase());
      addTearDown(field.dispose);
      field.value = '  Alice  ';
      expect(field.value, equals('alice'));
    });

    test('transform applied after parse', () {
      final field = Field<dynamic>('score')
          .parse((s) => int.tryParse(s))
          .transform((v) => v == null ? null : (v as int) * 2);
      addTearDown(field.dispose);
      field.value = '5';
      expect(field.value, equals(10));
    });

    test('transform receiving null returns null gracefully', () {
      final field = Field<String>(
        'name',
      ).required().transform((v) => v?.trim());
      addTearDown(field.dispose);
      field.value = null;
      expect(field.value, isNull);
    });
  });

  // ===========================================================================
  // Feature 3 – field.reset({to})
  // ===========================================================================
  group('Field – reset({to})', () {
    test('reset() without args restores to initialValue', () {
      final field = Field<String>('name', 'Alice');
      addTearDown(field.dispose);
      field.value = 'Bob';
      field.reset();
      expect(field.value, equals('Alice'));
      expect(field.isDirty, isFalse);
    });

    test('reset(to: value) sets to given value', () {
      final field = Field<String>('name', 'Alice');
      addTearDown(field.dispose);
      field.reset(to: 'Charlie');
      expect(field.value, equals('Charlie'));
    });

    test('reset(to: value) isDirty reflects comparison to initialValue', () {
      final field = Field<String>('name', 'Alice');
      addTearDown(field.dispose);
      field.reset(to: 'Bob'); // Bob != Alice → dirty
      expect(field.isDirty, isTrue);

      field.reset(to: 'Alice'); // Alice == Alice → not dirty
      expect(field.isDirty, isFalse);
    });

    test('reset(to: null) sets value to null', () {
      final field = Field<String>('name', 'Alice');
      addTearDown(field.dispose);
      field.value = 'Bob';
      field.reset(to: null);
      expect(field.value, isNull);
    });

    test('reset(to: null) is dirty when initialValue is non-null', () {
      final field = Field<String>('name', 'Alice');
      addTearDown(field.dispose);
      field.reset(to: null);
      expect(field.isDirty, isTrue);
    });

    test('reset(to:) clears error and isTouched', () {
      final field = Field<String>('name', 'Alice');
      addTearDown(field.dispose);
      field.touch();
      field.invalidate('some error');
      field.reset(to: 'Bob');
      expect(field.error, isNull);
      expect(field.isTouched, isFalse);
    });
  });

  // ===========================================================================
  // Feature 4 – Field.computed
  // ===========================================================================
  group('Field.computed', () {
    test('value is computed from other fields', () {
      final form = formCtrl(
        () => (
          qty: Field<int>('qty', 2),
          price: Field<double>('price', 10.0),
          total: Field.computed<double>('total', (valueOf) {
            final q = valueOf<int>('qty').value ?? 0;
            final p = valueOf<double>('price').value ?? 0.0;
            return q * p;
          }),
        ),
      );
      addTearDown(form.dispose);

      expect(form.fields.total.value, equals(20.0));
    });

    test('value updates when dependency changes', () {
      final form = formCtrl(
        () => (
          qty: Field<int>('qty', 1),
          price: Field<double>('price', 5.0),
          total: Field.computed<double>('total', (valueOf) {
            final q = valueOf<int>('qty').value ?? 0;
            final p = valueOf<double>('price').value ?? 0.0;
            return q * p;
          }),
        ),
      );
      addTearDown(form.dispose);

      form.fields.qty.value = 3;
      expect(form.fields.total.value, equals(15.0));

      form.fields.price.value = 10.0;
      expect(form.fields.total.value, equals(30.0));
    });

    test('setter throws UnsupportedError', () {
      final form = formCtrl(
        () => (
          x: Field<int>('x', 1),
          doubled: Field.computed<int>('doubled', (valueOf) {
            return (valueOf<int>('x').value ?? 0) * 2;
          }),
        ),
      );
      addTearDown(form.dispose);

      expect(
        () => form.fields.doubled.value = 99,
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('isDirty is always false', () {
      final form = formCtrl(
        () => (
          x: Field<int>('x', 1),
          doubled: Field.computed<int>('doubled', (valueOf) {
            return (valueOf<int>('x').value ?? 0) * 2;
          }),
        ),
      );
      addTearDown(form.dispose);

      form.fields.x.value = 5;
      expect(form.fields.doubled.isDirty, isFalse);
    });

    test('reset is a no-op', () {
      final form = formCtrl(
        () => (
          x: Field<int>('x', 3),
          doubled: Field.computed<int>('doubled', (valueOf) {
            return (valueOf<int>('x').value ?? 0) * 2;
          }),
        ),
      );
      addTearDown(form.dispose);

      form.fields.x.value = 10;
      expect(form.fields.doubled.value, equals(20));
      form.fields.doubled.reset(); // no-op
      expect(form.fields.doubled.value, equals(20)); // still recomputed
    });

    test('appears in toJson', () {
      final form = formCtrl(
        () => (
          qty: Field<int>('qty', 4),
          price: Field<double>('price', 2.5),
          total: Field.computed<double>('total', (valueOf) {
            final q = valueOf<int>('qty').value ?? 0;
            final p = valueOf<double>('price').value ?? 0.0;
            return q * p;
          }),
        ),
      );
      addTearDown(form.dispose);

      final json = form.toJson();
      expect(json['total'], equals(10.0));
    });
  });

  // ===========================================================================
  // Feature 5 – form.setErrors(Map<String, String>)
  // ===========================================================================
  group('FormController – setErrors', () {
    test('sets errors on matching fields', () {
      final form = formCtrl(
        () => (email: Field<String>('email'), cpf: Field<String>('cpf')),
      );
      addTearDown(form.dispose);

      form.setErrors({'email': 'Already taken', 'cpf': 'Invalid'});
      expect(form.fields.email.error, equals('Already taken'));
      expect(form.fields.cpf.error, equals('Invalid'));
    });

    test('unknown keys are silently ignored', () {
      final form = formCtrl(() => (name: Field<String>('name')));
      addTearDown(form.dispose);

      // Should not throw
      form.setErrors({'name': 'Required', 'nonexistent': 'ignored'});
      expect(form.fields.name.error, equals('Required'));
    });

    test('emits exactly one notification for multiple errors', () {
      final form = formCtrl(
        () => (
          a: Field<String>('a'),
          b: Field<String>('b'),
          c: Field<String>('c'),
        ),
      );
      addTearDown(form.dispose);

      var notifyCount = 0;
      form.addListener(() => notifyCount++);

      form.setErrors({'a': 'err1', 'b': 'err2', 'c': 'err3'});
      expect(notifyCount, equals(1));
    });

    test('shouldFocusFirst flag is accepted without throwing', () {
      final form = formCtrl(
        () => (email: Field<String>('email'), name: Field<String>('name')),
      );
      addTearDown(form.dispose);

      // No focusNode attached, but should not throw
      expect(
        () => form.setErrors({
          'email': 'Error',
          'name': 'Error2',
        }, shouldFocusFirst: true),
        returnsNormally,
      );
    });
  });

  // ===========================================================================
  // Feature 6 – form.toQueryString()
  // ===========================================================================
  group('FormController – toQueryString', () {
    test('produces correct query string', () {
      final form = formCtrl(
        () =>
            (name: Field<String>('name', 'Alice'), age: Field<int>('age', 30)),
      );
      addTearDown(form.dispose);

      final qs = form.toQueryString();
      expect(qs, contains('name=Alice'));
      expect(qs, contains('age=30'));
    });

    test('omitNulls:true skips null fields', () {
      final form = formCtrl(
        () => (
          name: Field<String>('name', 'Alice'),
          note: Field<String>('note'), // null
        ),
      );
      addTearDown(form.dispose);

      final qs = form.toQueryString(omitNulls: true);
      expect(qs, contains('name=Alice'));
      expect(qs, isNot(contains('note')));
    });

    test('omitNulls:false includes null fields as empty string', () {
      final form = formCtrl(
        () => (
          name: Field<String>('name', 'Alice'),
          note: Field<String>('note'), // null
        ),
      );
      addTearDown(form.dispose);

      final qs = form.toQueryString(omitNulls: false);
      expect(qs, contains('note='));
    });

    test('nested fields use dot notation key', () {
      late Field<String> city;
      final form = formCtrl(() {
        final addr = formGroup('address', () {
          city = Field<String>('city', 'SP');
          return city;
        });
        return addr;
      });
      addTearDown(form.dispose);

      final qs = form.toQueryString();
      expect(qs, contains('address.city=SP'));
    });

    test('special characters are URL-encoded', () {
      final form = formCtrl(
        () => (q: Field<String>('q', 'hello world & more')),
      );
      addTearDown(form.dispose);

      final qs = form.toQueryString();
      expect(qs, isNot(contains(' ')));
      expect(qs, contains('hello+world'));
    });
  });

  // ===========================================================================
  // Feature 7 – form.completionPercent
  // ===========================================================================
  group('FormController – completionPercent', () {
    test('0.0 when all fields are empty', () {
      final form = formCtrl(
        () => (name: Field<String>('name'), email: Field<String>('email')),
      );
      addTearDown(form.dispose);

      expect(form.completionPercent, equals(0.0));
    });

    test('1.0 when all fields are filled', () {
      final form = formCtrl(
        () => (
          name: Field<String>('name', 'Alice'),
          email: Field<String>('email', 'a@b.com'),
        ),
      );
      addTearDown(form.dispose);

      expect(form.completionPercent, equals(1.0));
    });

    test('partial fill returns correct fraction', () {
      final form = formCtrl(
        () => (
          a: Field<String>('a', 'filled'),
          b: Field<String>('b'),
          c: Field<String>('c'),
          d: Field<String>('d', 'filled'),
        ),
      );
      addTearDown(form.dispose);

      expect(form.completionPercent, equals(0.5));
    });

    test('excludes disabled fields', () {
      final form = formCtrl(
        () => (
          name: Field<String>('name', 'Alice'),
          hidden: Field<String>('hidden'), // null but disabled
        ),
      );
      addTearDown(form.dispose);

      form.fields.hidden.disable();
      // only 'name' counts → 1/1 = 1.0
      expect(form.completionPercent, equals(1.0));
    });

    test('excludes computed fields', () {
      final form = formCtrl(
        () => (
          qty: Field<int>('qty', 2),
          price: Field<double>('price', 5.0),
          total: Field.computed<double>('total', (valueOf) {
            final q = valueOf<int>('qty').value ?? 0;
            final p = valueOf<double>('price').value ?? 0.0;
            return q * p;
          }),
        ),
      );
      addTearDown(form.dispose);

      // total is computed → not counted; qty and price filled → 2/2 = 1.0
      expect(form.completionPercent, equals(1.0));
    });

    test('empty string counts as unfilled', () {
      final form = formCtrl(
        () => (
          name: Field<String>('name', ''),
          email: Field<String>('email', 'a@b.com'),
        ),
      );
      addTearDown(form.dispose);

      expect(form.completionPercent, equals(0.5));
    });

    test('returns 1.0 when there are no active fields', () {
      // A form with only computed fields has no active fields
      final form = formCtrl(
        () => (total: Field.computed<int>('total', (valueOf) => 0)),
      );
      addTearDown(form.dispose);

      expect(form.completionPercent, equals(1.0));
    });
  });
}
