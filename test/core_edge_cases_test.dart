import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

sealed class Jurisdicao {
  const Jurisdicao();
}

final class Brasil extends Jurisdicao {
  const Brasil();
}

final class EUA extends Jurisdicao {
  const EUA();
}

final class UE extends Jurisdicao {
  const UE();
}

void main() {
  // ===========================================================================
  // FormTracker – isolamento de contexto
  // ===========================================================================
  group('FormTracker – isolamento de contexto', () {
    test('formCtrl aninhados não vazam campos entre si', () {
      late FormController<dynamic> inner;

      final outer = formCtrl(() {
        final a = Field<String>('a');
        inner = formCtrl(() => (x: Field<String>('x')));
        final b = Field<String>('b');
        return (a: a, b: b);
      });
      addTearDown(outer.dispose);
      addTearDown(inner.dispose);

      expect(outer.debugFields.length, equals(2));
      expect(outer.tryGetField('x'), isNull);
      expect(inner.debugFields.length, equals(1));
      expect(inner.tryGetField('x'), isNotNull);
    });

    test('exceção dentro do builder não corrompe contexto externo', () {
      final outer = formCtrl(() {
        final a = Field<String>('a');
        try {
          formCtrl<void>(() => throw Exception('inner fail'));
        } catch (_) {}
        final b = Field<String>('b');
        return (a: a, b: b);
      });
      addTearDown(outer.dispose);

      expect(outer.debugFields.length, equals(2));
    });
  });

  // ===========================================================================
  // Field – null como valor explícito
  // ===========================================================================
  group('Field – null como valor explícito', () {
    test('setar null em campo com initialValue não-null marca isDirty', () {
      final field = Field<String>('name', 'Wellington');
      addTearDown(field.dispose);
      field.value = null;
      expect(field.isDirty, isTrue);
      expect(field.value, isNull);
    });

    test('setar null em campo com initialValue null não marca isDirty', () {
      final field = Field<String>('name');
      addTearDown(field.dispose);
      var notified = false;
      field.addListener(() => notified = true);
      field.value = null;
      expect(field.isDirty, isFalse);
      expect(notified, isFalse);
    });

    test('toJson inclui null para campos sem valor', () {
      final form = formCtrl(() => (name: Field<String>('name')));
      addTearDown(form.dispose);
      final json = form.toJson();
      expect(json.containsKey('name'), isTrue);
      expect(json['name'], isNull);
    });
  });

  // ===========================================================================
  // Field – mask em borda
  // ===========================================================================
  group('Field – mask em borda', () {
    test('mask não é aplicada quando val não é String', () {
      final field = Field<int>('qty');
      addTearDown(field.dispose);
      field.value = 42;
      expect(field.value, equals(42));
    });

    test('mask aplicada retroativamente re-formata valor já existente', () {
      final field = Field<String>('phone', '11999998888');
      addTearDown(field.dispose);
      field.mask('(##) #####-####');
      expect(field.value, equals('(11) 99999-8888'));
    });

    test('mask com input vazio resulta em valor vazio', () {
      final field = Field<String>('doc')..mask('###.###.###-##');
      addTearDown(field.dispose);
      field.value = '';
      expect(field.value, equals(''));
    });

    test('mask ignora caracteres não-alfanuméricos do input', () {
      final field = Field<String>('cpf')..mask('###.###.###-##');
      addTearDown(field.dispose);
      field.value = '123.456.789-09';
      expect(field.value, equals('123.456.789-09'));
    });
  });

  // ===========================================================================
  // Field – debounce cancelado pelo reset
  // ===========================================================================
  group('Field – debounce cancelado pelo reset', () {
    test('reset() cancela timer de debounce pendente', () {
      fakeAsync((fake) {
        var validationCount = 0;
        final field = Field<String>('name')
          ..debounce(const Duration(milliseconds: 100))
          ..addValidatorAsync('', (_) async {
            validationCount++;
            return false;
          });
        addTearDown(field.dispose);

        field.value = 'trigger';
        field.reset();

        fake.elapse(const Duration(milliseconds: 150));
        fake.flushMicrotasks();

        expect(validationCount, equals(0));
      });
    });
  });

  // ===========================================================================
  // Field – múltiplos validadores async (short-circuit)
  // ===========================================================================
  group('Field – múltiplos async validators', () {
    test(
      'segundo validador async não é chamado quando o primeiro falha',
      () async {
        var secondCalled = false;
        final field = Field<String>('email')
          ..addValidatorAsync('Primeiro erro', (_) async => true)
          ..addValidatorAsync('Segundo erro', (_) async {
            secondCalled = true;
            return true;
          });
        addTearDown(field.dispose);

        await field.validateAsync();

        expect(field.error, equals('Primeiro erro'));
        expect(secondCalled, isFalse);
      },
    );

    test(
      'validadores async são executados em sequência até o primeiro erro',
      () async {
        final calls = <int>[];
        final field = Field<String>('x')
          ..addValidatorAsync('err1', (_) async {
            calls.add(1);
            return false;
          })
          ..addValidatorAsync('err2', (_) async {
            calls.add(2);
            return true;
          })
          ..addValidatorAsync('err3', (_) async {
            calls.add(3);
            return true;
          });
        addTearDown(field.dispose);

        await field.validateAsync();

        expect(calls, equals([1, 2]));
        expect(field.error, equals('err2'));
      },
    );
  });

  // ===========================================================================
  // Field – applyEach em borda
  // ===========================================================================
  group('Field – applyEach em borda', () {
    test('iterable vazio é sempre válido', () {
      final field = Field<List<String>>('tags')
        ..applyEach<String>(
          (f) => f.addValidator('Vazio', (v) => v == null || v.isEmpty),
        );
      addTearDown(field.dispose);
      field.value = <String>[];
      expect(field.validate(), isTrue);
    });

    test('valor null é tratado como ausente (sem erro de tipo)', () {
      final field = Field<List<String>>('tags')
        ..applyEach<String>(
          (f) => f.addValidator('Vazio', (v) => v == null || v.isEmpty),
        );
      addTearDown(field.dispose);
      field.value = null;
      expect(() => field.validate(), returnsNormally);
    });

    test('Set é iterado sem TypeError (regressão de bug)', () {
      final field = Field<Set<int>>(
        'ids',
      )..applyEach<int>((f) => f.addValidator('Negativo', (v) => (v ?? 0) < 0));
      addTearDown(field.dispose);

      field.value = {1, 2, 3};
      expect(field.validate(), isTrue);

      field.value = {1, -1, 3};
      expect(field.validate(), isFalse);
    });
  });

  // ===========================================================================
  // Field – apply() e applyWhen() aninhados
  // ===========================================================================
  group('Field – apply() e applyWhen() aninhados', () {
    test('apply() executa buildValidators e retorna self para chaining', () {
      final field = Field<String>('password').apply((f) {
        f.addValidator('Curto', (v) => (v?.length ?? 0) < 6);
      });
      addTearDown(field.dispose);

      field.value = 'abc';
      expect(field.validate(), isFalse);
      field.value = 'abcdef';
      expect(field.validate(), isTrue);
    });

    test('applyWhen aninhado: ambas as condições devem ser true', () {
      final form = formCtrl(() {
        final flag1 = Field<bool>('flag1', true);
        final flag2 = Field<bool>('flag2', true);
        final name = Field<String>('name').applyWhen(
          (v) => v<bool>('flag1').value == true,
          (f) => f.applyWhen(
            (v) => v<bool>('flag2').value == true,
            (f) => f.addValidator('Obrig', (v) => v == null || v.isEmpty),
          ),
        );
        return (flag1: flag1, flag2: flag2, name: name);
      });
      addTearDown(form.dispose);

      expect(form.fields.name.validate(), isFalse);

      form.fields.flag2.value = false;
      expect(form.fields.name.validate(), isTrue);
    });
  });

  // ===========================================================================
  // FormController – notificações
  // ===========================================================================
  group('FormController – notificações', () {
    test('form notifica listeners quando campo filho muda', () {
      final form = formCtrl(() => (name: Field<String>('name')));
      addTearDown(form.dispose);
      var formNotified = false;
      form.addListener(() => formNotified = true);

      form.fields.name.value = 'Wellington';

      expect(formNotified, isTrue);
    });

    test('form notifica listeners quando campo é invalidado externamente', () {
      final form = formCtrl(() => (x: Field<String>('x')));
      addTearDown(form.dispose);
      var count = 0;
      form.addListener(() => count++);

      form.invalidateField('x', 'Erro externo');

      expect(count, greaterThan(0));
    });
  });

  // ===========================================================================
  // FormController – isValidating
  // ===========================================================================
  group('FormController – isValidating', () {
    test('isValidating é true enquanto algum campo está carregando', () {
      fakeAsync((fake) {
        final completer = Completer<bool>();
        final form = formCtrl(
          () => (
            email: Field<String>('email')
              ..addValidatorAsync('', (_) => completer.future),
          ),
        );
        addTearDown(form.dispose);

        form.fields.email.validateAsync();
        expect(form.isValidating, isTrue);

        completer.complete(false);
        fake.flushMicrotasks();
        expect(form.isValidating, isFalse);
      });
    });
  });

  // ===========================================================================
  // FormController – operações com chave inválida
  // ===========================================================================
  group('FormController – operações com chave inválida', () {
    test('patchValue ignora chaves que não existem no form', () {
      final form = formCtrl(() => (name: Field<String>('name', 'original')));
      addTearDown(form.dispose);
      expect(
        () => form.patchValue({'nonexistent': 'value', 'name': 'updated'}),
        returnsNormally,
      );
      expect(form.fields.name.value, equals('updated'));
    });

    test('setValue ignora path inexistente sem lançar exceção', () {
      final form = formCtrl(() => (x: Field<String>('x')));
      addTearDown(form.dispose);
      expect(() => form.setValue('nonexistent', 'val'), returnsNormally);
    });

    test('resetField ignora path inexistente sem lançar exceção', () {
      final form = formCtrl(() => (x: Field<String>('x')));
      addTearDown(form.dispose);
      expect(() => form.resetField('nonexistent'), returnsNormally);
    });

    test('invalidateField ignora path inexistente sem lançar exceção', () {
      final form = formCtrl(() => (x: Field<String>('x')));
      addTearDown(form.dispose);
      expect(
        () => form.invalidateField('nonexistent', 'Erro'),
        returnsNormally,
      );
    });
  });

  // ===========================================================================
  // FormController – trigger com path parcial
  // ===========================================================================
  group('FormController – trigger com path parcial', () {
    test(
      'trigger("account") valida subcampos de account mas não personal',
      () async {
        final form = formCtrl(
          () => (
            account: formGroup(
              'account',
              () => (
                email: Field<String>('email')
                  ..addValidator('R', (v) => v == null || v.isEmpty),
                name: Field<String>('name')
                  ..addValidator('R', (v) => v == null || v.isEmpty),
              ),
            ),
            personal: formGroup(
              'personal',
              () => (
                name: Field<String>('name')
                  ..addValidator('R', (v) => v == null || v.isEmpty),
              ),
            ),
          ),
        );
        addTearDown(form.dispose);

        await form.trigger(path: 'account');

        expect(form.fields.account.email.isTouched, isTrue);
        expect(form.fields.account.name.isTouched, isTrue);
        expect(form.fields.personal.name.isTouched, isFalse);
      },
    );

    test(
      'trigger("") valida todos os campos (equivalente a trigger())',
      () async {
        final form = formCtrl(
          () => (
            a: Field<String>('a')
              ..addValidator('R', (v) => v == null || v.isEmpty),
            b: Field<String>('b')
              ..addValidator('R', (v) => v == null || v.isEmpty),
          ),
        );
        addTearDown(form.dispose);

        final result = await form.trigger(path: '');

        expect(result, isFalse);
        expect(form.fields.a.isTouched, isTrue);
        expect(form.fields.b.isTouched, isTrue);
      },
    );
  });

  // ===========================================================================
  // FormController – touchAll
  // ===========================================================================
  group('FormController – touchAll', () {
    test('touchAll marca todos os campos como tocados', () {
      final form = formCtrl(
        () => (
          a: Field<String>('a'),
          b: Field<String>('b'),
          c: Field<String>('c'),
        ),
      );
      addTearDown(form.dispose);

      form.touchAll();

      expect(form.fields.a.isTouched, isTrue);
      expect(form.fields.b.isTouched, isTrue);
      expect(form.fields.c.isTouched, isTrue);
    });
  });

  // ===========================================================================
  // FormController – invalidação de cache
  // ===========================================================================
  group('FormController – invalidação de cache', () {
    test('errors cache é invalidado quando campo recebe invalidate()', () {
      final form = formCtrl(() => (x: Field<String>('x')));
      addTearDown(form.dispose);
      final e1 = form.errors;
      form.fields.x.invalidate('Erro');
      final e2 = form.errors;
      expect(identical(e1, e2), isFalse);
      expect(e2['x'], equals('Erro'));
    });

    test('errors cache é invalidado após reset do campo', () {
      final form = formCtrl(() => (x: Field<String>('x')));
      addTearDown(form.dispose);
      form.fields.x.invalidate('Erro');
      final e1 = form.errors;
      form.fields.x.reset();
      final e2 = form.errors;
      expect(identical(e1, e2), isFalse);
      expect(e2.isEmpty, isTrue);
    });
  });

  // ===========================================================================
  // FormController – debugFields é imutável
  // ===========================================================================
  group('FormController – debugFields', () {
    test('debugFields retorna lista não-modificável', () {
      final form = formCtrl(() => (name: Field<String>('name')));
      addTearDown(form.dispose);
      expect(
        () => (form.debugFields as List).add(Field<String>('hack')),
        throwsUnsupportedError,
      );
    });
  });

  // ===========================================================================
  // FormController – submit com validationMode.onSubmit
  // ===========================================================================
  group('FormController – submit respeita validação independente do mode', () {
    test('submit valida mesmo campos com validationMode.onSubmit', () async {
      var submitted = false;
      final form = formCtrl(
        () => (
          name: Field<String>('name')
            ..validationMode(ValidationMode.onSubmit)
            ..addValidator('Obrigatório', (v) => v == null || v.isEmpty),
        ),
      );
      addTearDown(form.dispose);

      await form.submit((_) async => submitted = true);

      expect(submitted, isFalse);
      expect(form.fields.name.error, equals('Obrigatório'));
    });
  });

  // ===========================================================================
  // Field – isLoading setter
  // ===========================================================================
  group('Field – isLoading setter', () {
    test('isLoading setter notifica quando muda de false para true', () {
      final field = Field<String>('x');
      addTearDown(field.dispose);
      var notified = false;
      field.addListener(() => notified = true);
      field.isLoading = true;
      expect(notified, isTrue);
    });

    test('isLoading setter NÃO notifica quando valor não muda', () {
      final field = Field<String>('x');
      addTearDown(field.dispose);
      field.isLoading = true;
      var count = 0;
      field.addListener(() => count++);
      field.isLoading = true;
      expect(count, equals(0));
    });
  });

  // ===========================================================================
  // Field – validate limpa erro anterior quando validador passa
  // ===========================================================================
  group('Field – validate limpa erro residual', () {
    test('validate() limpa error de invalidate() anterior ao passar', () {
      final field = Field<String>('x');
      addTearDown(field.dispose);
      field.invalidate('erro externo');
      field.validate();
      expect(field.error, isNull);
    });
  });

  // ===========================================================================
  // Field – matches e equals
  // ===========================================================================
  group('Field – matches e equals', () {
    test('matches: válido quando ambos têm o mesmo valor', () {
      final form = formCtrl(() {
        final password = Field<String>('password', 'secret123');
        final confirm = Field<String>('confirm').matches('password');
        return (password: password, confirm: confirm);
      });
      addTearDown(form.dispose);

      form.fields.confirm.value = 'secret123';
      expect(form.fields.confirm.validate(), isTrue);
    });

    test('matches: inválido quando valores diferem', () {
      final form = formCtrl(() {
        final password = Field<String>('password', 'secret123');
        final confirm = Field<String>('confirm').matches('password');
        return (password: password, confirm: confirm);
      });
      addTearDown(form.dispose);

      form.fields.confirm.value = 'other';
      expect(form.fields.confirm.validate(), isFalse);
    });

    test(
      'matches: retorna válido quando form é null (campo fora de formCtrl)',
      () {
        // Quando form == null a condição não pode ser avaliada → validador retorna false (sem erro)
        final field = Field<String>('confirm').matches('password');
        addTearDown(field.dispose);
        field.value = 'qualquer';
        expect(field.validate(), isTrue);
      },
    );

    test('equals: passes quando valor é vazio (não valida comparação)', () {
      final form = formCtrl(() {
        final password = Field<String>('password', 'secret');
        final confirm = Field<String>(
          'confirm',
        ).equals((v) => v<String>('password'), message: 'Não coincidem');
        return (password: password, confirm: confirm);
      });
      addTearDown(form.dispose);

      form.fields.confirm.value = '';
      expect(form.fields.confirm.validate(), isTrue);
    });

    test(
      'equals: falha quando valores são diferentes e campo não está vazio',
      () {
        final form = formCtrl(() {
          final password = Field<String>('password', 'secret');
          final confirm = Field<String>(
            'confirm',
          ).equals((v) => v<String>('password'), message: 'Não coincidem');
          return (password: password, confirm: confirm);
        });
        addTearDown(form.dispose);

        form.fields.confirm.value = 'diferente';
        expect(form.fields.confirm.validate(), isFalse);
        expect(form.fields.confirm.error, equals('Não coincidem'));
      },
    );
  });

  // ===========================================================================
  // formGroup – path é sempre restaurado
  // ===========================================================================
  group('formGroup – path é sempre restaurado', () {
    test('path é restaurado mesmo quando builder retorna vazio', () {
      late Field<String> after;
      final form = formCtrl(() {
        formGroup('scope', () => 'não é um Field');
        after = Field<String>('after');
        return after;
      });
      addTearDown(form.dispose);
      expect(after.name, equals('after'));
    });
  });

  // ===========================================================================
  // Field – oneOf
  // ===========================================================================
  group('Field – oneOf', () {
    test('aceita valor da lista', () {
      final field = Field<String>('role')..oneOf(['admin', 'user', 'guest']);
      addTearDown(field.dispose);
      field.value = 'admin';
      expect(field.validate(), isTrue);
    });

    test('rejeita valor fora da lista', () {
      final field = Field<String>('role')..oneOf(['admin', 'user', 'guest']);
      addTearDown(field.dispose);
      field.value = 'superuser';
      expect(field.validate(), isFalse);
    });

    test('valor null ou vazio passa (oneOf não valida ausência)', () {
      final field = Field<String>('role')..oneOf(['admin', 'user']);
      addTearDown(field.dispose);
      field.value = null;
      expect(field.validate(), isTrue);
      field.value = '';
      expect(field.validate(), isTrue);
    });

    test('funciona com tipos genéricos (ex: int)', () {
      final field = Field<int>('number').oneOf([10, 20, 30]);
      addTearDown(field.dispose);
      field.value = 10;
      expect(field.validate(), isTrue);
      field.value = 15;
      expect(field.validate(), isFalse);
      field.value = null;
      expect(field.validate(), isTrue);
    });
  });

  // ===========================================================================
  // Field – text getter (string extension)
  // ===========================================================================
  group('Field – text getter', () {
    test('retorna string vazia quando value é null', () {
      final field = Field<String>('x');
      addTearDown(field.dispose);
      expect(field.text, equals(''));
    });

    test('retorna o valor quando não é null', () {
      final field = Field<String>('x', 'Wellington');
      addTearDown(field.dispose);
      expect(field.text, equals('Wellington'));
    });
  });

  // ===========================================================================
  // toJson(omitNulls) – bordas
  // ===========================================================================
  group('toJson(omitNulls) – bordas', () {
    test('form com todos os campos nulos retorna {} com omitNulls', () {
      final form = formCtrl(
        () => (a: Field<String>('a'), b: Field<int>('b'), c: Field<bool>('c')),
      );
      addTearDown(form.dispose);
      expect(form.toJson(omitNulls: true), isEmpty);
    });

    test('campo com valor lista não é confundido com mapa aninhado', () {
      final form = formCtrl(
        () => (tags: Field<List<String>>('tags', ['a', 'b'])),
      );
      addTearDown(form.dispose);
      final json = form.toJson(omitNulls: true);
      expect(json['tags'], equals(['a', 'b']));
    });

    test('campo com valor inteiro zero (falsy) não é omitido', () {
      final form = formCtrl(() => (count: Field<int>('count', 0)));
      addTearDown(form.dispose);
      final json = form.toJson(omitNulls: true);
      expect(json.containsKey('count'), isTrue);
      expect(json['count'], equals(0));
    });

    test('campo com valor false não é omitido', () {
      final form = formCtrl(() => (flag: Field<bool>('flag', false)));
      addTearDown(form.dispose);
      final json = form.toJson(omitNulls: true);
      expect(json.containsKey('flag'), isTrue);
      expect(json['flag'], equals(false));
    });

    test('mapa com irmãos mistos — nulo é podado, não-nulo permanece', () {
      final form = formCtrl(() {
        formGroup(
          'addr',
          () => (
            street: Field<String>('street', 'Rua A'),
            complement: Field<String>('complement'),
          ),
        );
        return (x: Field<String>('x'));
      });
      addTearDown(form.dispose);

      final json = form.toJson(omitNulls: true);
      expect(json['addr']['street'], equals('Rua A'));
      expect((json['addr'] as Map).containsKey('complement'), isFalse);
    });

    test('omitNulls não muta o cache do toJson() sem flag', () {
      final form = formCtrl(
        () => (name: Field<String>('name', 'A'), alias: Field<String>('alias')),
      );
      addTearDown(form.dispose);

      form.toJson(omitNulls: true); // popula _jsonCacheOmitNulls
      final full = form.toJson(); // deve usar _jsonCache separado
      expect(full.containsKey('alias'), isTrue);
      expect(full['alias'], isNull);
    });
  });

  // ===========================================================================
  // formGroup(applyWhen:) – bordas
  // ===========================================================================
  group('formGroup(applyWhen:) – bordas', () {
    test('grupos aninhados com applyWhen em ambos — AND composto', () async {
      final form = formCtrl(() {
        final outer = formGroup(
          'outer',
          () => formGroup(
            'inner',
            () => (name: Field<String>('name').required()),
            applyWhen: (valueOf) => valueOf<bool>('innerActive').value == true,
          ),
          applyWhen: (valueOf) => valueOf<bool>('outerActive').value == true,
        );
        return (
          outerActive: Field<bool>('outerActive', true),
          innerActive: Field<bool>('innerActive', false),
          outer: outer,
        );
      });
      addTearDown(form.dispose);

      // outer=true, inner=false → não valida
      await form.trigger();
      expect(form.fields.outer.name.error, isNull);

      // ambos true → valida
      form.fields.innerActive.value = true;
      await form.trigger();
      expect(form.fields.outer.name.error, isNotNull);

      // outer=false → não valida mesmo com inner=true
      form.fields.outerActive.value = false;
      await form.trigger();
      expect(form.fields.outer.name.error, isNull);
    });

    test('applyWhen em grupo sem campos não lança exceção', () {
      expect(
        () => formCtrl(() {
          formGroup('empty', () => null, applyWhen: (_) => true);
          return (x: Field<String>('x'));
        }),
        returnsNormally,
      );
    });
  });

  // ===========================================================================
  // switchWith – bordas
  // ===========================================================================
  group('switchWith – bordas', () {
    test('dependsOn com path inexistente não lança na construção', () {
      expect(
        () => formCtrl(
          () => (
            x: Field<String>('x').switchWith<String>(
              (v) => v<String>('x').value,
              {'a': (f) => f.required()},
              dependsOn: ['nao_existe'],
            ),
          ),
        ),
        returnsNormally,
      );
    });

    test(
      'switchWith chamado duas vezes no mesmo campo — casos acumulam',
      () async {
        final form = formCtrl(
          () => (
            mode: Field<String>('mode', 'X'),
            doc: Field<String>('doc')
                .switchWith<String>((v) => v<String>('mode').value, {
                  'X': (f) => f.addValidator('erro X', (v) => v == null),
                })
                .switchWith<String>((v) => v<String>('mode').value, {
                  'Y': (f) => f.addValidator('erro Y', (v) => v == null),
                }),
          ),
        );
        addTearDown(form.dispose);

        await form.trigger();
        expect(form.fields.doc.error, equals('erro X'));

        form.fields.mode.value = 'Y';
        await form.trigger();
        expect(form.fields.doc.error, equals('erro Y'));
      },
    );

    test('orElse com validador assíncrono funciona', () async {
      final form = formCtrl(
        () => (
          mode: Field<String>('mode', 'XX'),
          doc: Field<String>('doc').switchWith<String>(
            (valueOf) => valueOf<String>('mode').value,
            {'BR': (f) => f.required()},
            orElse: (f) =>
                f.addValidatorAsync('modo async inválido', (_) async => true),
          ),
        ),
      );
      addTearDown(form.dispose);

      await form.trigger();
      expect(form.fields.doc.error, equals('modo async inválido'));
    });

    test('chave do tipo int funciona como selector', () async {
      final form = formCtrl(
        () => (
          step: Field<int>('step', 2),
          value: Field<String>('value')
              .switchWith<int>((valueOf) => valueOf<int>('step').value, {
                1: (f) => f.addValidator('erro 1', (v) => v == null),
                2: (f) => f.addValidator('erro 2', (v) => v == null),
              }),
        ),
      );
      addTearDown(form.dispose);

      await form.trigger();
      expect(form.fields.value.error, equals('erro 2'));
    });
  });

  // ===========================================================================
  // switchWith – sealed class + oneOf
  // ===========================================================================
  // Padrão: Field<String> + oneOf restringe o domínio em tempo de execução;
  // switchWith<Jurisdicao> usa a sealed class como chave — const canonicaliza
  // as instâncias (const Brasil() == const Brasil()), e o switch exaustivo
  // no keySelector faz o compilador alertar se um subtipo for esquecido.
  group('switchWith – sealed class + oneOf', () {
    // keySelector: converte string → sealed class via switch exaustivo.
    // O _ final captura valores inválidos que escaparam do oneOf.
    Jurisdicao? parsePais(ValueOf valueOf) {
      return switch (valueOf<String>('pais').value) {
        'brasil' => const Brasil(),
        'eua' => const EUA(),
        'ue' => const UE(),
        _ => null,
      };
    }

    // Mapa reutilizado nos testes: chaves são const — mesma instância canônica
    // que parsePais retorna, então == funciona sem override de operator==.
    final cases = <Jurisdicao, void Function(Field<String>)>{
      const Brasil(): (f) =>
          f.addValidator('CPF inválido', (v) => v == null || v.length != 11),
      const EUA(): (f) =>
          f.addValidator('SSN inválido', (v) => v == null || v.length != 9),
      const UE(): (f) =>
          f.addValidator('VAT inválido', (v) => v == null || v.length < 5),
    };

    test('case brasil: CPF validado, SSN e VAT ignorados', () async {
      final form = formCtrl(
        () => (
          pais: Field<String>(
            'pais',
            'brasil',
          ).oneOf(['brasil', 'eua', 'ue'], message: 'Jurisdição inválida'),
          doc: Field<String>(
            'doc',
            '',
          ).switchWith<Jurisdicao>(parsePais, cases),
        ),
      );
      addTearDown(form.dispose);

      await form.trigger();
      expect(form.fields.pais.error, isNull);
      expect(form.fields.doc.error, equals('CPF inválido')); // vazio ≠ 11 chars
    });

    test('case eua: SSN validado, CPF e VAT ignorados', () async {
      final form = formCtrl(
        () => (
          pais: Field<String>(
            'pais',
            'eua',
          ).oneOf(['brasil', 'eua', 'ue'], message: 'Jurisdição inválida'),
          doc:
              Field<String>('doc', '123456789') // 9 chars
                  .switchWith<Jurisdicao>(parsePais, cases),
        ),
      );
      addTearDown(form.dispose);

      await form.trigger();
      expect(form.fields.pais.error, isNull);
      expect(form.fields.doc.error, isNull); // SSN de 9 chars é válido
    });

    test('case ue: VAT validado, CPF e SSN ignorados', () async {
      final form = formCtrl(
        () => (
          pais: Field<String>(
            'pais',
            'ue',
          ).oneOf(['brasil', 'eua', 'ue'], message: 'Jurisdição inválida'),
          doc:
              Field<String>('doc', 'DE12345') // 7 chars ≥ 5
                  .switchWith<Jurisdicao>(parsePais, cases),
        ),
      );
      addTearDown(form.dispose);

      await form.trigger();
      expect(form.fields.pais.error, isNull);
      expect(form.fields.doc.error, isNull); // VAT de 7 chars é válido
    });

    test('oneOf rejeita jurisdição fora do domínio', () async {
      final form = formCtrl(
        () => (
          pais:
              Field<String>('pais', 'xyz') // não está em [brasil, eua, ue]
                  .oneOf([
                    'brasil',
                    'eua',
                    'ue',
                  ], message: 'Jurisdição inválida'),
          doc: Field<String>('doc').switchWith<Jurisdicao>(parsePais, cases),
        ),
      );
      addTearDown(form.dispose);

      await form.trigger();
      expect(form.fields.pais.error, isNotNull); // 'xyz' rejeitado pelo oneOf
    });

    test('oneOf aceita todas as jurisdições válidas', () async {
      for (final valid in ['brasil', 'eua', 'ue']) {
        final form = formCtrl(
          () => (
            pais: Field<String>(
              'pais',
              valid,
            ).oneOf(['brasil', 'eua', 'ue'], message: 'Jurisdição inválida'),
            doc: Field<String>(
              'doc',
              '12345678901',
            ).switchWith<Jurisdicao>(parsePais, cases),
          ),
        );
        addTearDown(form.dispose);
        await form.trigger();
        expect(
          form.fields.pais.error,
          isNull,
          reason: 'pais=$valid deve ser válido',
        );
      }
    });

    test(
      'orElse não dispara quando todos os casos da sealed class estão cobertos',
      () async {
        final form = formCtrl(
          () => (
            pais: Field<String>(
              'pais',
              'brasil',
            ).oneOf(['brasil', 'eua', 'ue'], message: 'Jurisdição inválida'),
            doc:
                Field<String>('doc', '12345678901') // 11 chars = CPF válido
                    .switchWith<Jurisdicao>(
                      parsePais,
                      cases,
                      orElse: (f) => f.addValidator(
                        'jurisdição desconhecida',
                        (_) => true,
                      ),
                    ),
          ),
        );
        addTearDown(form.dispose);

        await form.trigger();
        // case Brasil ativo + CPF de 11 chars válido → sem erros; orElse não roda
        expect(form.fields.doc.error, isNull);
      },
    );
  });
}
