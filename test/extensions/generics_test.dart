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

    group('required() genérico', () {
      test('falha quando valor é null em Field<int>', () {
        final form = formCtrl(
          () => (age: Field<int>('age').required(message: 'Obrigatório')),
        );
        addTearDown(form.dispose);
        form.fields.age.value = null;
        expect(form.fields.age.validate(), isFalse);
        expect(form.fields.age.error, equals('Obrigatório'));
      });

      test('passa quando valor não é null em Field<int>', () {
        final form = formCtrl(
          () => (age: Field<int>('age').required(message: 'Obrigatório')),
        );
        addTearDown(form.dispose);
        form.fields.age.value = 18;
        expect(form.fields.age.validate(), isTrue);
        expect(form.fields.age.error, isNull);
      });

      test('falha quando valor é null em Field<bool>', () {
        final form = formCtrl(
          () => (flag: Field<bool>('flag').required(message: 'Selecione')),
        );
        addTearDown(form.dispose);
        expect(form.fields.flag.validate(), isFalse);
        expect(form.fields.flag.error, equals('Selecione'));
      });

      test('false passa em Field<bool> pois false != null', () {
        final form = formCtrl(
          () => (flag: Field<bool>('flag').required(message: 'Selecione')),
        );
        addTearDown(form.dispose);
        form.fields.flag.value = false;
        expect(form.fields.flag.validate(), isTrue);
      });

      test('exposed:true expõe a regra em exposedRules', () {
        final form = formCtrl(
          () => (age: Field<int>('age').required(message: 'Obrigatório', exposed: true)),
        );
        addTearDown(form.dispose);
        expect(
          form.fields.age.exposedRules.any((r) => r.message == 'Obrigatório'),
          isTrue,
        );
      });
    });

    group('oneOf – mensagem sem concatenação', () {
      test('mensagem de erro é exatamente o message fornecido', () {
        final form = formCtrl(
          () => (
            role: Field<String>('role').oneOf(['admin', 'editor'], message: 'Perfil inválido'),
          ),
        );
        addTearDown(form.dispose);
        form.fields.role.value = 'hacker';
        form.fields.role.validate();
        expect(form.fields.role.error, equals('Perfil inválido'));
      });

      test('mensagem NÃO contém os valores permitidos concatenados', () {
        final form = formCtrl(
          () => (
            role: Field<String>('role').oneOf(['a', 'b'], message: 'Inválido'),
          ),
        );
        addTearDown(form.dispose);
        form.fields.role.value = 'x';
        form.fields.role.validate();
        expect(form.fields.role.error, isNot(contains('a, b')));
      });

      test('valor null passa em oneOf', () {
        final form = formCtrl(
          () => (role: Field<String>('role').oneOf(['a', 'b'], message: 'e')),
        );
        addTearDown(form.dispose);
        form.fields.role.value = null;
        expect(form.fields.role.validate(), isTrue);
      });

      test('valor vazio passa em oneOf', () {
        final form = formCtrl(
          () => (role: Field<String>('role').oneOf(['a', 'b'], message: 'e')),
        );
        addTearDown(form.dispose);
        form.fields.role.value = '';
        expect(form.fields.role.validate(), isTrue);
      });

      test('valor permitido passa em oneOf', () {
        final form = formCtrl(
          () => (
            role: Field<String>('role').oneOf(['admin', 'editor'], message: 'e'),
          ),
        );
        addTearDown(form.dispose);
        form.fields.role.value = 'admin';
        expect(form.fields.role.validate(), isTrue);
      });
    });
  });
}
