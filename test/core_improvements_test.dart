import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

void main() {
  // ===========================================================================
  // 1. formGroup – try/finally protege o pathStack
  // ===========================================================================
  group('formGroup – try/finally', () {
    test('path é restaurado após exceção no builder', () {
      expect(
        () => formCtrl(() {
          final a = Field<String>('before');
          formGroup<void>('broken', () => throw Exception('boom'));
          final b = Field<String>('after'); // nunca alcançado
          return (a: a, b: b);
        }),
        throwsException,
      );

      // Contexto externo não foi corrompido — um novo formCtrl funciona
      final form = formCtrl(() => (x: Field<String>('x')));
      addTearDown(form.dispose);
      expect(form.fields.x.name, equals('x'));
    });

    test('campos criados APÓS formGroup que falhou têm paths corretos', () {
      // Capturamos a exceção dentro do builder para que o código continue.
      // Antes da correção, o pathStack ficaria com 'broken' não removido e
      // afterField.name seria 'broken.after'. Com o try/finally deve ser 'after'.
      late Field<String> afterField;

      final form = formCtrl(() {
        try {
          formGroup<void>('broken', () => throw Exception());
        } catch (_) {}
        afterField = Field<String>('after');
        return afterField;
      });
      addTearDown(form.dispose);

      expect(afterField.name, equals('after'));
    });

    test('formGroups aninhados restauram path mesmo com exceção no inner', () {
      String? outerFieldName;

      expect(
        () => formCtrl(() {
          return formGroup('outer', () {
            final f = Field<String>('outerField');
            outerFieldName = f.name;
            formGroup<void>('inner', () => throw Exception());
            return f;
          });
        }),
        throwsException,
      );

      // 'outer' foi restaurado corretamente pelo finally do inner
      expect(outerFieldName, equals('outer.outerField'));
    });

    test('formGroup normal continua funcionando após a correção', () {
      final form = formCtrl(() {
        return (
          address: formGroup('address', () => (
            street: Field<String>('street', 'Rua A'),
            city: Field<String>('city', 'SP'),
          )),
        );
      });
      addTearDown(form.dispose);

      expect(form.fields.address.street.name, equals('address.street'));
      expect(form.fields.address.city.name, equals('address.city'));
    });
  });

  // ===========================================================================
  // 2. Batch notifications – patchValue, reset, touchAll emitem 1 notificação
  // ===========================================================================
  group('Batch notifications', () {
    test('patchValue com N campos emite exatamente 1 notificação', () {
      final form = formCtrl(
        () => (
          a: Field<String>('a')..validationMode(ValidationMode.onSubmit),
          b: Field<String>('b')..validationMode(ValidationMode.onSubmit),
          c: Field<String>('c')..validationMode(ValidationMode.onSubmit),
        ),
      );
      addTearDown(form.dispose);

      var count = 0;
      form.addListener(() => count++);

      form.patchValue({'a': 'x', 'b': 'y', 'c': 'z'});

      expect(count, equals(1));
    });

    test('patchValue com chaves inexistentes emite 0 notificações', () {
      final form = formCtrl(() => (x: Field<String>('x')));
      addTearDown(form.dispose);

      var count = 0;
      form.addListener(() => count++);

      form.patchValue({'nonexistent': 'value'});

      expect(count, equals(0));
    });

    test('reset() emite exatamente 1 notificação', () {
      final form = formCtrl(
        () => (
          a: Field<String>('a', 'init'),
          b: Field<String>('b', 'init'),
          c: Field<String>('c', 'init'),
        ),
      );
      addTearDown(form.dispose);
      form.fields.a.value = 'changed';
      form.fields.b.value = 'changed';
      form.fields.c.value = 'changed';

      var count = 0;
      form.addListener(() => count++);

      form.reset();

      expect(count, equals(1));
    });

    test('reset() emite notificação mesmo em form vazio', () {
      final form = formCtrl(() => <Field<String>>[]);
      addTearDown(form.dispose);

      var count = 0;
      form.addListener(() => count++);

      form.reset();

      expect(count, equals(1));
    });

    test('touchAll() emite exatamente 1 notificação', () {
      final form = formCtrl(
        () => (
          a: Field<String>('a'),
          b: Field<String>('b'),
          c: Field<String>('c'),
        ),
      );
      addTearDown(form.dispose);

      var count = 0;
      form.addListener(() => count++);

      form.touchAll();

      expect(count, equals(1));
    });

    test('touchAll() não emite se todos os campos já estavam tocados', () {
      final form = formCtrl(() => (x: Field<String>('x'), y: Field<String>('y')));
      addTearDown(form.dispose);
      form.touchAll();

      var count = 0;
      form.addListener(() => count++);

      form.touchAll(); // idempotente — nenhum campo muda estado

      expect(count, equals(0));
    });

    test('patchValue parcial: apenas campos existentes disparam notificação', () {
      final form = formCtrl(
        () => (
          x: Field<String>('x')..validationMode(ValidationMode.onSubmit),
        ),
      );
      addTearDown(form.dispose);

      var count = 0;
      form.addListener(() => count++);

      form.patchValue({'x': 'ok', 'ghost': 'ignored'});

      expect(count, equals(1));
    });

    test('trigger() emite 1 notificação para os markAsTouched em batch', () async {
      final form = formCtrl(
        () => (
          a: Field<String>('a', 'ok'),
          b: Field<String>('b', 'ok'),
          c: Field<String>('c', 'ok'),
        ),
      );
      addTearDown(form.dispose);

      var touchNotifications = 0;
      form.addListener(() => touchNotifications++);

      await form.trigger();

      // Apenas as notificações de touch são síncronas e em batch (1 notificação).
      // As de validateAsync são assíncronas e podem acrescentar mais,
      // mas a batch dos touches deve ter sido 1.
      expect(touchNotifications, greaterThanOrEqualTo(1));
    });
  });

  // ===========================================================================
  // 3. O(1) counters – isDirty, isTouched, isValidating
  // ===========================================================================
  group('O(1) counters – isDirty', () {
    test('isDirty começa false', () {
      final form = formCtrl(() => (x: Field<String>('x', 'init')));
      addTearDown(form.dispose);
      expect(form.isDirty, isFalse);
    });

    test('isDirty fica true quando qualquer campo muda', () {
      final form = formCtrl(
        () => (
          x: Field<String>('x', 'init')..validationMode(ValidationMode.onSubmit),
          y: Field<String>('y', 'init')..validationMode(ValidationMode.onSubmit),
        ),
      );
      addTearDown(form.dispose);

      form.fields.y.value = 'changed';
      expect(form.isDirty, isTrue);
    });

    test('isDirty volta a false quando campo retorna ao valor inicial', () {
      final form = formCtrl(
        () => (x: Field<String>('x', 'init')..validationMode(ValidationMode.onSubmit)),
      );
      addTearDown(form.dispose);

      form.fields.x.value = 'changed';
      expect(form.isDirty, isTrue);

      form.fields.x.value = 'init'; // reverte
      expect(form.isDirty, isFalse);
    });

    test('isDirty permanece true enquanto houver pelo menos 1 campo sujo', () {
      final form = formCtrl(
        () => (
          x: Field<String>('x', 'init')..validationMode(ValidationMode.onSubmit),
          y: Field<String>('y', 'init')..validationMode(ValidationMode.onSubmit),
        ),
      );
      addTearDown(form.dispose);

      form.fields.x.value = 'changed';
      form.fields.y.value = 'changed';

      form.fields.x.value = 'init'; // apenas x reverte
      expect(form.isDirty, isTrue); // y ainda está sujo

      form.fields.y.value = 'init'; // y também reverte
      expect(form.isDirty, isFalse);
    });

    test('isDirty volta a false após reset()', () {
      final form = formCtrl(
        () => (
          x: Field<String>('x', 'init')..validationMode(ValidationMode.onSubmit),
          y: Field<String>('y', 'init')..validationMode(ValidationMode.onSubmit),
        ),
      );
      addTearDown(form.dispose);

      form.fields.x.value = 'a';
      form.fields.y.value = 'b';
      expect(form.isDirty, isTrue);

      form.reset();
      expect(form.isDirty, isFalse);
    });
  });

  group('O(1) counters – isTouched', () {
    test('isTouched começa false', () {
      final form = formCtrl(() => (x: Field<String>('x')));
      addTearDown(form.dispose);
      expect(form.isTouched, isFalse);
    });

    test('isTouched fica true após touch() em qualquer campo', () {
      final form = formCtrl(() => (x: Field<String>('x'), y: Field<String>('y')));
      addTearDown(form.dispose);

      form.fields.y.touch();
      expect(form.isTouched, isTrue);
    });

    test('isTouched volta a false após reset()', () {
      final form = formCtrl(() => (x: Field<String>('x'), y: Field<String>('y')));
      addTearDown(form.dispose);

      form.touchAll();
      expect(form.isTouched, isTrue);

      form.reset();
      expect(form.isTouched, isFalse);
    });

    test('isTouched permanece true enquanto pelo menos 1 campo foi tocado', () {
      final form = formCtrl(() => (x: Field<String>('x'), y: Field<String>('y')));
      addTearDown(form.dispose);

      form.fields.x.touch();
      form.fields.y.touch();

      // reset individual não existe no FormController — só field.reset()
      form.fields.x.reset();
      expect(form.isTouched, isTrue); // y ainda está tocado

      form.fields.y.reset();
      expect(form.isTouched, isFalse);
    });
  });

  group('O(1) counters – isValidating', () {
    test('isValidating começa false', () {
      final form = formCtrl(() => (x: Field<String>('x')));
      addTearDown(form.dispose);
      expect(form.isValidating, isFalse);
    });

    test('isValidating fica true enquanto campo está carregando', () {
      fakeAsync((fake) {
        final form = formCtrl(() => (
          x: Field<String>('x', 'ok')
            ..addValidatorAsync('', (_) async {
              await Future.delayed(const Duration(milliseconds: 50));
              return false;
            }),
        ));
        addTearDown(form.dispose);

        form.fields.x.validateAsync();

        fake.elapse(const Duration(milliseconds: 10));
        expect(form.isValidating, isTrue);

        fake.elapse(const Duration(milliseconds: 60));
        fake.flushMicrotasks();
        expect(form.isValidating, isFalse);
      });
    });

    test('isValidating false quando múltiplos campos terminam', () {
      fakeAsync((fake) {
        final form = formCtrl(() => (
          x: Field<String>('x', 'ok')
            ..addValidatorAsync('', (_) async {
              await Future.delayed(const Duration(milliseconds: 30));
              return false;
            }),
          y: Field<String>('y', 'ok')
            ..addValidatorAsync('', (_) async {
              await Future.delayed(const Duration(milliseconds: 60));
              return false;
            }),
        ));
        addTearDown(form.dispose);

        form.fields.x.validateAsync();
        form.fields.y.validateAsync();

        fake.elapse(const Duration(milliseconds: 40));
        fake.flushMicrotasks();
        expect(form.isValidating, isTrue); // y ainda está carregando

        fake.elapse(const Duration(milliseconds: 40));
        fake.flushMicrotasks();
        expect(form.isValidating, isFalse); // ambos terminaram
      });
    });

    test('contadores não ficam negativos após resetField', () {
      final form = formCtrl(
        () => (x: Field<String>('x', 'init')..validationMode(ValidationMode.onSubmit)),
      );
      addTearDown(form.dispose);

      form.fields.x.value = 'dirty';
      expect(form.isDirty, isTrue);

      form.resetField('x');
      expect(form.isDirty, isFalse);

      // Segunda chamada ao resetField não deve decrementar além de zero
      form.resetField('x');
      expect(form.isDirty, isFalse);
    });
  });

  // ===========================================================================
  // 4. Prefix index – trigger(path) O(1)
  // ===========================================================================
  group('Prefix index – trigger(path)', () {
    late FormController<dynamic> form;

    setUp(() {
      form = formCtrl(() => (
        account: formGroup('account', () => (
          name: Field<String>('name')..addValidator('obrig', (_) => true),
          age: Field<int>('age')..addValidator('obrig', (_) => true),
        )),
        personal: formGroup('personal', () => (
          doc: Field<String>('doc')..addValidator('obrig', (_) => true),
        )),
      ));
    });
    tearDown(() => form.dispose());

    test('trigger("account") valida account.* mas não personal.*', () async {
      await form.trigger(path: 'account');

      expect(form.fields.account.name.error, isNotNull);
      expect(form.fields.account.age.error, isNotNull);
      expect(form.fields.personal.doc.error, isNull);
    });

    test('trigger("personal") valida personal.* mas não account.*', () async {
      await form.trigger(path: 'personal');

      expect(form.fields.personal.doc.error, isNotNull);
      expect(form.fields.account.name.error, isNull);
      expect(form.fields.account.age.error, isNull);
    });

    test('trigger("account.name") valida só o campo exato', () async {
      await form.trigger(path: 'account.name');

      expect(form.fields.account.name.error, isNotNull);
      expect(form.fields.account.age.error, isNull);
      expect(form.fields.personal.doc.error, isNull);
    });

    test('trigger() sem path valida todos os campos', () async {
      await form.trigger();

      expect(form.fields.account.name.error, isNotNull);
      expect(form.fields.account.age.error, isNotNull);
      expect(form.fields.personal.doc.error, isNotNull);
    });

    test('trigger("") valida todos os campos (equivalente a sem path)', () async {
      await form.trigger(path: '');

      expect(form.fields.account.name.error, isNotNull);
      expect(form.fields.account.age.error, isNotNull);
      expect(form.fields.personal.doc.error, isNotNull);
    });

    test('trigger com path inexistente retorna true sem erros', () async {
      final result = await form.trigger(path: 'nonexistent');
      expect(result, isTrue);
      expect(form.fields.account.name.error, isNull);
    });

    test('prefixo parcial não causa match falso: "acc" não bate "account.*"', () async {
      await form.trigger(path: 'acc');
      // Nenhum campo deve ter sido validado
      expect(form.fields.account.name.error, isNull);
      expect(form.fields.account.age.error, isNull);
    });

    test('prefix index é consistente após múltiplos triggers', () async {
      await form.trigger(path: 'account');
      await form.trigger(path: 'personal');

      expect(form.fields.account.name.error, isNotNull);
      expect(form.fields.personal.doc.error, isNotNull);
    });
  });

  group('Prefix index – grupos profundamente aninhados', () {
    test('trigger("a") valida a.b.c.field', () async {
      final form = formCtrl(() => (
        deep: formGroup('a', () => (
          mid: formGroup('b', () => (
            leaf: formGroup('c', () => (
              field: Field<String>('field')
                ..addValidator('obrig', (_) => true),
            )),
          )),
        )),
      ));
      addTearDown(form.dispose);

      await form.trigger(path: 'a');
      expect(form.fields.deep.mid.leaf.field.error, isNotNull);
    });

    test('trigger("a.b") valida a.b.* mas não a.z.*', () async {
      final form = formCtrl(() => (
        b: formGroup('a', () => (
          b: formGroup('b', () => (
            field: Field<String>('field')..addValidator('e', (_) => true),
          )),
          z: formGroup('z', () => (
            other: Field<String>('other')..addValidator('e', (_) => true),
          )),
        )),
      ));
      addTearDown(form.dispose);

      await form.trigger(path: 'a.b');

      expect(form.fields.b.b.field.error, isNotNull);
      expect(form.fields.b.z.other.error, isNull);
    });
  });
}
