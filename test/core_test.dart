import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

void main() {
  // ===========================================================================
  // Field – estado inicial
  // ===========================================================================
  group('Field – estado inicial', () {
    test('valor começa nulo quando nenhum initialValue é fornecido', () {
      final field = Field<String>('name');
      addTearDown(field.dispose);
      expect(field.value, isNull);
      expect(field.initialValue, isNull);
      expect(field.isDirty, isFalse);
      expect(field.isTouched, isFalse);
      expect(field.isLoading, isFalse);
      expect(field.error, isNull);
    });

    test('initialValue é atribuído corretamente', () {
      final field = Field<String>('name', 'Wellington');
      addTearDown(field.dispose);
      expect(field.value, equals('Wellington'));
      expect(field.initialValue, equals('Wellington'));
      expect(field.isDirty, isFalse);
    });

    test('name é composto pelo caminho completo via formGroup', () {
      late Field<String> inner;
      final form = formCtrl(() {
        inner = formGroup('address', () => Field<String>('city'));
        return inner;
      });
      addTearDown(form.dispose);
      expect(inner.name, equals('address.city'));
    });
  });

  // ===========================================================================
  // Field – setter value
  // ===========================================================================
  group('Field – value setter', () {
    test('isDirty fica true quando valor muda do inicial', () {
      final field = Field<String>('email', 'a@b.com');
      addTearDown(field.dispose);
      field.value = 'x@y.com';
      expect(field.isDirty, isTrue);
    });

    test('isDirty volta a false quando valor retorna ao inicial', () {
      final field = Field<String>('email', 'a@b.com');
      addTearDown(field.dispose);
      field.value = 'x@y.com';
      field.value = 'a@b.com';
      expect(field.isDirty, isFalse);
    });

    test('notifyListeners é chamado quando valor muda', () {
      final field = Field<String>('email');
      addTearDown(field.dispose);
      var notified = false;
      field.addListener(() => notified = true);
      field.value = 'test';
      expect(notified, isTrue);
    });

    test('notifyListeners NÃO é chamado quando valor não muda', () {
      final field = Field<String>('email', 'same');
      addTearDown(field.dispose);
      var count = 0;
      field.addListener(() => count++);
      field.value = 'same';
      expect(count, equals(0));
    });

    test('onValueChanged callback é acionado com valores corretos', () {
      final field = Field<String>('email', 'old');
      addTearDown(field.dispose);
      String? capturedOld, capturedNew;
      field.onValueChanged = (o, n) {
        capturedOld = o;
        capturedNew = n;
      };
      field.value = 'new';
      expect(capturedOld, equals('old'));
      expect(capturedNew, equals('new'));
    });
  });

  // ===========================================================================
  // Field – touch
  // ===========================================================================
  group('Field – touch', () {
    test('touch() marca isTouched como true', () {
      final field = Field<String>('name');
      addTearDown(field.dispose);
      field.touch();
      expect(field.isTouched, isTrue);
    });

    test('touch() não notifica duas vezes', () {
      final field = Field<String>('name');
      addTearDown(field.dispose);
      var count = 0;
      field.addListener(() => count++);
      field.touch();
      field.touch();
      expect(count, equals(1));
    });
  });

  // ===========================================================================
  // Field – reset() (propriedade por propriedade)
  // ===========================================================================
  group('Field – reset()', () {
    late Field<String> field;

    setUp(() {
      field = Field<String>('name', 'init');
      field.value = 'changed';
      field.touch();
      field.invalidate('erro');
    });

    tearDown(() => field.dispose());

    test('restaura value para initialValue', () {
      field.reset();
      expect(field.value, equals('init'));
    });

    test('limpa error', () {
      field.reset();
      expect(field.error, isNull);
    });

    test('limpa isDirty', () {
      field.reset();
      expect(field.isDirty, isFalse);
    });

    test('limpa isTouched', () {
      field.reset();
      expect(field.isTouched, isFalse);
    });

    test('limpa isLoading', () {
      field.isLoading = true;
      field.reset();
      expect(field.isLoading, isFalse);
    });
  });

  // ===========================================================================
  // Field – validate (sync)
  // ===========================================================================
  group('Field – validação síncrona', () {
    test('retorna true quando não há validadores', () {
      final field = Field<String>('name');
      addTearDown(field.dispose);
      expect(field.validate(), isTrue);
    });

    test('retorna false e seta error quando validador falha', () {
      final field = Field<String>('name')
        ..addValidator('Obrigatório', (v) => v == null || v.isEmpty);
      addTearDown(field.dispose);
      expect(field.validate(), isFalse);
      expect(field.error, equals('Obrigatório'));
    });

    test('retorna true e limpa error quando validador passa', () {
      final field = Field<String>('name')
        ..addValidator('Obrigatório', (v) => v == null || v.isEmpty);
      addTearDown(field.dispose);
      field.value = 'Wellington';
      expect(field.validate(), isTrue);
      expect(field.error, isNull);
    });

    test('para no primeiro validador que falha', () {
      final field = Field<String>('age')
        ..addValidator('Erro 1', (_) => true)
        ..addValidator('Erro 2', (_) => true);
      addTearDown(field.dispose);
      field.validate();
      expect(field.error, equals('Erro 1'));
    });

    test('dynamicMessage é usado no lugar de message estática', () {
      final field = Field<int>('qty')
        ..addValidator(
          '',
          (v) => (v ?? 0) < 1,
          dynamicMessage: (v) => 'Mínimo é 1, recebido: $v',
        );
      addTearDown(field.dispose);
      field.value = 0;
      field.validate();
      expect(field.error, equals('Mínimo é 1, recebido: 0'));
    });
  });

  // ===========================================================================
  // Field – validateAsync
  // ===========================================================================
  group('Field – validação assíncrona', () {
    test('retorna false quando validação sync falha', () async {
      final field = Field<String>('email')
        ..addValidator('Sync error', (v) => true);
      addTearDown(field.dispose);
      final result = await field.validateAsync();
      expect(result, isFalse);
      expect(field.isLoading, isFalse);
    });

    test('executa validador async e seta error', () async {
      final field = Field<String>('email')
        ..addValidatorAsync('Email já cadastrado', (_) async => true);
      addTearDown(field.dispose);
      final result = await field.validateAsync();
      expect(result, isFalse);
      expect(field.error, equals('Email já cadastrado'));
      expect(field.isLoading, isFalse);
    });

    test('isLoading fica true durante async e false ao terminar', () {
      fakeAsync((fake) {
        final completer = Completer<bool>();
        final field = Field<String>('email')
          ..addValidatorAsync('', (_) => completer.future);
        addTearDown(field.dispose);

        field.validateAsync();
        expect(field.isLoading, isTrue);

        completer.complete(false);
        fake.flushMicrotasks();
        expect(field.isLoading, isFalse);
      });
    });

    test('race condition: versão antiga é descartada', () {
      fakeAsync((fake) {
        var callCount = 0;
        final field = Field<String>('email')
          ..addValidatorAsync('err', (_) async {
            callCount++;
            await Future.delayed(const Duration(milliseconds: 50));
            return true;
          });
        addTearDown(field.dispose);

        field.validateAsync(); // versão 1
        fake.elapse(const Duration(milliseconds: 10));
        field.validateAsync(); // versão 2

        fake.elapse(const Duration(milliseconds: 100));
        fake.flushMicrotasks();

        expect(field.error, equals('err'));
        expect(callCount, equals(2));
      });
    });

    test('onValidationStart e onValidationEnd são chamados', () async {
      var started = false;
      bool? endedValid;
      String? endedError;

      final field = Field<String>('x')..addValidator('fail', (_) => true);
      addTearDown(field.dispose);

      field.onValidationStart = () => started = true;
      field.onValidationEnd = (isValid, error) {
        endedValid = isValid;
        endedError = error;
      };

      await field.validateAsync();

      expect(started, isTrue);
      expect(endedValid, isFalse);
      expect(endedError, equals('fail'));
    });

    test('onValidationEnd(true, null) quando não há validadores', () async {
      final field = Field<String>('x');
      addTearDown(field.dispose);
      bool? isValid;
      String? error = 'sentinela';
      field.onValidationEnd = (v, e) {
        isValid = v;
        error = e;
      };

      await field.validateAsync();

      expect(isValid, isTrue);
      expect(error, isNull);
    });
  });

  // ===========================================================================
  // Field – debounce
  // ===========================================================================
  group('Field – debounce', () {
    test('debounce adia a validação pelo tempo configurado', () {
      fakeAsync((fake) {
        var validationCount = 0;
        final field = Field<String>('search')
          ..debounce(const Duration(milliseconds: 80))
          ..addValidatorAsync('', (_) async {
            validationCount++;
            return false;
          });
        addTearDown(field.dispose);

        field.value = 'a';
        field.value = 'ab';
        field.value = 'abc';

        fake.elapse(const Duration(milliseconds: 150));
        fake.flushMicrotasks();

        expect(validationCount, equals(1));
      });
    });
  });

  // ===========================================================================
  // Field – mask
  // ===========================================================================
  group('Field – mask', () {
    test('aplica máscara corretamente', () {
      final field = Field<String>('cpf')..mask('###.###.###-##');
      addTearDown(field.dispose);
      field.value = '12345678901';
      expect(field.value, equals('123.456.789-01'));
    });

    test('jsonValue remove máscara quando removeMaskOnJson=true', () {
      final field = Field<String>('cpf')
        ..mask('###.###.###-##', removeMaskOnJson: true);
      addTearDown(field.dispose);
      field.value = '12345678901';
      expect(field.jsonValue, equals('12345678901'));
    });

    test('jsonValue mantém máscara quando removeMaskOnJson=false', () {
      final field = Field<String>('cpf')
        ..mask('###.###.###-##', removeMaskOnJson: false);
      addTearDown(field.dispose);
      field.value = '12345678901';
      expect(field.jsonValue, equals('123.456.789-01'));
    });

    test('máscara é truncada quando input é curto', () {
      final field = Field<String>('cpf')..mask('###.###.###-##');
      addTearDown(field.dispose);
      field.value = '123';
      expect(field.value, equals('123'));
    });
  });

  // ===========================================================================
  // Field – transformToJson / jsonValue
  // ===========================================================================
  group('Field – jsonValue e transformToJson', () {
    test('DateTime é serializado como ISO 8601 por padrão', () {
      final date = DateTime(2024, 1, 15);
      final field = Field<DateTime>('date');
      addTearDown(field.dispose);
      field.value = date;
      expect(field.jsonValue, equals(date.toIso8601String()));
    });

    test('transformToJson substitui serialização padrão', () {
      final field = Field<int>('age')..transformToJson((v) => v?.toString());
      addTearDown(field.dispose);
      field.value = 30;
      expect(field.jsonValue, equals('30'));
    });

    test('valor nulo retorna null no jsonValue', () {
      final field = Field<String>('name');
      addTearDown(field.dispose);
      expect(field.jsonValue, isNull);
    });
  });

  // ===========================================================================
  // Field – invalidate
  // ===========================================================================
  group('Field – invalidate', () {
    test('seta error diretamente sem passar por validadores', () {
      final field = Field<String>('email');
      addTearDown(field.dispose);
      field.invalidate('Email já existe');
      expect(field.error, equals('Email já existe'));
    });

    test('notifica listeners após invalidate', () {
      final field = Field<String>('email');
      addTearDown(field.dispose);
      var notified = false;
      field.addListener(() => notified = true);
      field.invalidate('err');
      expect(notified, isTrue);
    });
  });

  // ===========================================================================
  // Field – applyWhen (conditional validators)
  // ===========================================================================
  group('Field – applyWhen', () {
    test('validador é ignorado quando condição é falsa', () {
      final form = formCtrl(() {
        final toggle = Field<bool>('toggle', false);
        final name = Field<String>('name').applyWhen(
          (valueOf) => valueOf<bool>('toggle').value == true,
          (f) => f.addValidator('Obrigatório', (v) => v == null || v.isEmpty),
        );
        return (toggle: toggle, name: name);
      });
      addTearDown(form.dispose);

      form.fields.toggle.value = false;
      expect(form.fields.name.validate(), isTrue);
    });

    test('validador é aplicado quando condição é verdadeira', () {
      final form = formCtrl(() {
        final toggle = Field<bool>('toggle', true);
        final name = Field<String>('name').applyWhen(
          (valueOf) => valueOf<bool>('toggle').value == true,
          (f) => f.addValidator('Obrigatório', (v) => v == null || v.isEmpty),
        );
        return (toggle: toggle, name: name);
      });
      addTearDown(form.dispose);

      expect(form.fields.name.validate(), isFalse);
      expect(form.fields.name.error, equals('Obrigatório'));
    });
  });

  // ===========================================================================
  // Field – applyEach
  // ===========================================================================
  group('Field – applyEach', () {
    test(
      'valida cada item de uma lista e retorna false no primeiro inválido',
      () {
        final field = Field<List<String>>('tags')
          ..applyEach<String>(
            (f) => f.addValidator('Vazio', (v) => v == null || v.isEmpty),
          );
        addTearDown(field.dispose);
        field.value = ['ok', '', 'valid'];
        expect(field.validate(), isFalse);
      },
    );

    test('retorna true quando todos os itens são válidos', () {
      final field = Field<List<String>>('tags')
        ..applyEach<String>(
          (f) => f.addValidator('Vazio', (v) => v == null || v.isEmpty),
        );
      addTearDown(field.dispose);
      field.value = ['ok', 'valid'];
      expect(field.validate(), isTrue);
    });

    test('formatError é usado para compor mensagem de erro', () {
      final field = Field<List<String>>('tags')
        ..applyEach<String>(
          (f) => f.addValidator('Vazio', (v) => v == null || v.isEmpty),
          formatError: (i, msg) => 'Item $i: $msg',
        );
      addTearDown(field.dispose);
      field.value = ['ok', ''];
      field.validate();
      expect(field.error, equals('Item 1: Vazio'));
    });
  });

  // ===========================================================================
  // Field – exposedRules
  // ===========================================================================
  group('Field – exposedRules', () {
    test('exposedRules reflete estado atual dos validadores', () {
      final field = Field<String>('password')
        ..addValidator(
          'Mínimo 8 caracteres',
          (v) => (v?.length ?? 0) < 8,
          exposedMessage: true,
        );
      addTearDown(field.dispose);

      field.value = 'abc';
      expect(field.exposedRules.length, equals(1));
      expect(field.exposedRules.first.isValid, isFalse);

      field.value = 'abcdefgh';
      expect(field.exposedRules.first.isValid, isTrue);
    });

    test('validadores sem exposedMessage não aparecem em exposedRules', () {
      final field = Field<String>('x')
        ..addValidator('hidden', (_) => false)
        ..addValidator('shown', (_) => false, exposedMessage: true);
      addTearDown(field.dispose);
      expect(field.exposedRules.length, equals(1));
      expect(field.exposedRules.first.message, equals('shown'));
    });
  });

  // ===========================================================================
  // Field – validationMode
  // ===========================================================================
  group('Field – validationMode', () {
    test('onSubmit: value change não dispara validação automaticamente', () {
      fakeAsync((fake) {
        var validated = false;
        final field = Field<String>('email')
          ..validationMode(ValidationMode.onSubmit)
          ..addValidatorAsync('err', (_) async {
            validated = true;
            return false;
          });
        addTearDown(field.dispose);

        field.value = 'trigger';
        fake.elapse(const Duration(milliseconds: 20));
        fake.flushMicrotasks();
        expect(validated, isFalse);
      });
    });

    test('onBlur: touch() dispara validação, value change não', () {
      fakeAsync((fake) {
        var validationCount = 0;
        final field = Field<String>('email')
          ..validationMode(ValidationMode.onBlur)
          ..addValidatorAsync('err', (_) async {
            validationCount++;
            return false;
          });
        addTearDown(field.dispose);

        field.value = 'trigger';
        fake.elapse(const Duration(milliseconds: 20));
        expect(validationCount, equals(0));

        field.touch();
        fake.flushMicrotasks();
        expect(validationCount, equals(1));
      });
    });
  });

  // ===========================================================================
  // FormController – estado geral
  // ===========================================================================
  group('FormController – estado geral', () {
    test('valid é true quando não há errors', () {
      final form = formCtrl(() => (name: Field<String>('name', 'Wellington')));
      addTearDown(form.dispose);
      expect(form.valid, isTrue);
    });

    test('valid é false quando há campo com error', () {
      final form = formCtrl(() => (name: Field<String>('name')));
      addTearDown(form.dispose);
      form.fields.name.invalidate('Erro');
      expect(form.valid, isFalse);
    });

    test('isDirty é true quando qualquer campo é sujo', () {
      final form = formCtrl(() => (name: Field<String>('name', 'initial')));
      addTearDown(form.dispose);
      form.fields.name.value = 'changed';
      expect(form.isDirty, isTrue);
    });

    test('isTouched é true quando qualquer campo foi tocado', () {
      final form = formCtrl(() => (name: Field<String>('name')));
      addTearDown(form.dispose);
      form.fields.name.touch();
      expect(form.isTouched, isTrue);
    });

    test('errors retorna mapa apenas com campos com error', () {
      final form = formCtrl(
        () => (a: Field<String>('a'), b: Field<String>('b')),
      );
      addTearDown(form.dispose);
      form.fields.a.invalidate('Erro em A');
      expect(form.errors.length, equals(1));
      expect(form.errors['a'], equals('Erro em A'));
    });
  });

  // ===========================================================================
  // FormController – getField / tryGetField
  // ===========================================================================
  group('FormController – getField', () {
    test('getField retorna o campo correto', () {
      final form = formCtrl(() => (email: Field<String>('email')));
      addTearDown(form.dispose);
      final field = form.getField<String>('email');
      expect(field, same(form.fields.email));
    });

    test('getField lança ArgumentError quando campo não existe', () {
      final form = formCtrl(() => (name: Field<String>('name')));
      addTearDown(form.dispose);
      expect(() => form.getField('nonexistent'), throwsArgumentError);
    });

    test('tryGetField retorna null quando campo não existe', () {
      final form = formCtrl(() => (name: Field<String>('name')));
      addTearDown(form.dispose);
      expect(form.tryGetField('nonexistent'), isNull);
    });
  });

  // ===========================================================================
  // FormController – patchValue / setValue / resetField
  // ===========================================================================
  group('FormController – patchValue / setValue / resetField', () {
    test('patchValue atualiza múltiplos campos', () {
      final form = formCtrl(
        () => (first: Field<String>('first'), last: Field<String>('last')),
      );
      addTearDown(form.dispose);
      form.patchValue({'first': 'Wellington', 'last': 'Santos'});
      expect(form.fields.first.value, equals('Wellington'));
      expect(form.fields.last.value, equals('Santos'));
    });

    test('setValue atualiza campo específico', () {
      final form = formCtrl(() => (age: Field<int>('age')));
      addTearDown(form.dispose);
      form.setValue('age', 28);
      expect(form.fields.age.value, equals(28));
    });

    test('resetField reseta apenas o campo indicado', () {
      final form = formCtrl(
        () =>
            (a: Field<String>('a', 'init_a'), b: Field<String>('b', 'init_b')),
      );
      addTearDown(form.dispose);
      form.fields.a.value = 'changed';
      form.fields.b.value = 'changed';

      form.resetField('a');

      expect(form.fields.a.value, equals('init_a'));
      expect(form.fields.b.value, equals('changed'));
    });
  });

  // ===========================================================================
  // FormController – reset
  // ===========================================================================
  group('FormController – reset', () {
    test('reset restaura todos os campos e dispara onReset', () {
      var resetCalled = false;
      final form = formCtrl(() => (name: Field<String>('name', 'init')));
      addTearDown(form.dispose);
      form.onReset = () => resetCalled = true;

      form.fields.name.value = 'changed';
      form.reset();

      expect(form.fields.name.value, equals('init'));
      expect(form.fields.name.isDirty, isFalse);
      expect(resetCalled, isTrue);
    });

    test('reset() notifica listeners do FormController', () {
      final form = formCtrl(() => (x: Field<String>('x', 'v')));
      addTearDown(form.dispose);
      var count = 0;
      form.addListener(() => count++);
      form.reset();
      expect(count, greaterThan(0));
    });
  });

  // ===========================================================================
  // FormController – toJson
  // ===========================================================================
  group('FormController – toJson', () {
    test('toJson produz mapa plano para campos simples', () {
      final form = formCtrl(
        () => (
          email: Field<String>('email', 'a@b.com'),
          age: Field<int>('age', 30),
        ),
      );
      addTearDown(form.dispose);
      final json = form.toJson();
      expect(json['email'], equals('a@b.com'));
      expect(json['age'], equals(30));
    });

    test('toJson produz mapa aninhado para formGroup', () {
      final form = formCtrl(
        () => (
          address: formGroup(
            'address',
            () => (city: Field<String>('city', 'SP')),
          ),
        ),
      );
      addTearDown(form.dispose);
      final json = form.toJson();
      expect((json['address'] as Map)['city'], equals('SP'));
    });

    test('toJson usa cache: objeto idêntico retornado na segunda chamada', () {
      final form = formCtrl(() => (x: Field<String>('x', 'v')));
      addTearDown(form.dispose);
      final j1 = form.toJson();
      final j2 = form.toJson();
      expect(identical(j1, j2), isTrue);
    });

    test('toJson invalida cache após mudança de valor', () {
      final form = formCtrl(() => (x: Field<String>('x', 'old')));
      addTearDown(form.dispose);
      final j1 = form.toJson();
      form.fields.x.value = 'new';
      final j2 = form.toJson();
      expect(identical(j1, j2), isFalse);
      expect(j2['x'], equals('new'));
    });
  });

  // ===========================================================================
  // FormController – submit
  // ===========================================================================
  group('FormController – submit', () {
    test('submit chama onSubmit quando form é válido', () async {
      var submitted = false;
      final form = formCtrl(() => (name: Field<String>('name', 'Wellington')));
      addTearDown(form.dispose);
      await form.submit((_) async => submitted = true);
      expect(submitted, isTrue);
    });

    test('submit NÃO chama onSubmit quando form é inválido', () async {
      var submitted = false;
      final form = formCtrl(
        () => (
          name: Field<String>('name')
            ..addValidator('Obrigatório', (v) => v == null || v.isEmpty),
        ),
      );
      addTearDown(form.dispose);
      await form.submit((_) async => submitted = true);
      expect(submitted, isFalse);
    });

    test('isSubmitting é true durante submit e false após', () async {
      final form = formCtrl(() => (name: Field<String>('name', 'ok')));
      addTearDown(form.dispose);

      final completer = Completer<void>();
      bool? duringSubmit;

      final fut = form.submit((_) async {
        duringSubmit = form.isSubmitting;
        await completer.future;
      });

      completer.complete();
      await fut;

      expect(duringSubmit, isTrue);
      expect(form.isSubmitting, isFalse);
    });

    test('submit aciona onSubmitStart e onSubmitEnd com sucesso', () async {
      var started = false;
      bool? endedSuccess;

      final form = formCtrl(() => (name: Field<String>('name', 'ok')));
      addTearDown(form.dispose);
      form.onSubmitStart = () => started = true;
      form.onSubmitEnd = (s) => endedSuccess = s;

      await form.submit((_) async {});

      expect(started, isTrue);
      expect(endedSuccess, isTrue);
    });

    test('submit aciona onSubmitEnd com false e relança exceção', () async {
      bool? endedSuccess;

      final form = formCtrl(() => (name: Field<String>('name', 'ok')));
      addTearDown(form.dispose);
      form.onSubmitEnd = (s) => endedSuccess = s;

      await expectLater(
        () => form.submit((_) async => throw Exception('fail')),
        throwsException,
      );

      expect(endedSuccess, isFalse);
      expect(form.isSubmitting, isFalse);
    });

    test('submit concorrente: ambas as chamadas executam onSubmit', () async {
      var submitCount = 0;
      final form = formCtrl(() => (x: Field<String>('x', 'ok')));
      addTearDown(form.dispose);

      await Future.wait([
        form.submit((_) async => submitCount++),
        form.submit((_) async => submitCount++),
      ]);

      expect(submitCount, equals(2));
    });
  });

  // ===========================================================================
  // FormController – trigger
  // ===========================================================================
  group('FormController – trigger', () {
    test(
      'trigger() com path que não encontra nenhum campo retorna true',
      () async {
        final form = formCtrl(() => (x: Field<String>('x')));
        addTearDown(form.dispose);
        final result = await form.trigger(path: 'inexistente');
        expect(result, isTrue);
      },
    );
  });

  // ===========================================================================
  // FormController – dispose
  // ===========================================================================
  group('FormController – dispose', () {
    test('dispose não lança exceções', () {
      final form = formCtrl(() => (name: Field<String>('name', 'Wellington')));
      expect(() => form.dispose(), returnsNormally);
    });

    test('após dispose, field não notifica listeners', () {
      final form = formCtrl(() => (name: Field<String>('name')));
      var notified = false;
      form.fields.name.addListener(() => notified = true);
      form.dispose();
      expect(notified, isFalse);
    });
  });

  // ===========================================================================
  // formGroup – path stacking
  // ===========================================================================
  group('formGroup – aninhamento de paths', () {
    test('paths são compostos corretamente em dois níveis', () {
      late Field<String> city;
      final form = formCtrl(() {
        return formGroup('user', () {
          return formGroup('address', () {
            city = Field<String>('city');
            return city;
          });
        });
      });
      addTearDown(form.dispose);
      expect(city.name, equals('user.address.city'));
    });
  });

  // ===========================================================================
  // FormController – toJson(omitNulls)
  // ===========================================================================
  group('FormController – toJson(omitNulls)', () {
    test('inclui null por padrão', () {
      final form = formCtrl(
        () => (
          name: Field<String>('name', 'Alice'),
          alias: Field<String>('alias'),
        ),
      );
      addTearDown(form.dispose);

      final json = form.toJson();
      expect(json['name'], equals('Alice'));
      expect(json.containsKey('alias'), isTrue);
      expect(json['alias'], isNull);
    });

    test('exclui folha nula com omitNulls: true', () {
      final form = formCtrl(
        () => (
          name: Field<String>('name', 'Alice'),
          alias: Field<String>('alias'),
        ),
      );
      addTearDown(form.dispose);

      final json = form.toJson(omitNulls: true);
      expect(json['name'], equals('Alice'));
      expect(json.containsKey('alias'), isFalse);
    });

    test('poda mapa aninhado todo nulo', () {
      final form = formCtrl(() {
        final address = formGroup(
          'address',
          () => (street: Field<String>('street'), city: Field<String>('city')),
        );
        return (address: address);
      });
      addTearDown(form.dispose);

      final json = form.toJson(omitNulls: true);
      expect(json.containsKey('address'), isFalse);
    });

    test('mantém mapa aninhado parcialmente preenchido', () {
      final form = formCtrl(() {
        final address = formGroup(
          'address',
          () => (
            street: Field<String>('street', 'Rua A'),
            city: Field<String>('city'),
          ),
        );
        return (address: address);
      });
      addTearDown(form.dispose);

      final json = form.toJson(omitNulls: true);
      expect(json['address'], isA<Map>());
      expect(json['address']['street'], equals('Rua A'));
      expect((json['address'] as Map).containsKey('city'), isFalse);
    });

    test('poda mapa avô quando filho e neto são todos nulos', () {
      final form = formCtrl(() {
        final billing = formGroup('billing', () {
          final addr = formGroup(
            'address',
            () => (street: Field<String>('street')),
          );
          return (address: addr);
        });
        return (billing: billing);
      });
      addTearDown(form.dispose);

      final json = form.toJson(omitNulls: true);
      expect(json.containsKey('billing'), isFalse);
    });

    test('cache independente — omitNulls e não-omitNulls não interferem', () {
      final form = formCtrl(
        () => (
          name: Field<String>('name', 'Alice'),
          alias: Field<String>('alias'),
        ),
      );
      addTearDown(form.dispose);

      final full = form.toJson();
      final omitted = form.toJson(omitNulls: true);

      expect(full.containsKey('alias'), isTrue);
      expect(omitted.containsKey('alias'), isFalse);
      expect(identical(form.toJson(), full), isTrue);
      expect(identical(form.toJson(omitNulls: true), omitted), isTrue);
    });

    test('invalida ambos os caches ao mudar valor', () {
      final form = formCtrl(
        () => (
          name: Field<String>('name', 'Alice'),
          alias: Field<String>('alias'),
        ),
      );
      addTearDown(form.dispose);

      final before = form.toJson();
      final beforeOmit = form.toJson(omitNulls: true);

      form.fields.alias.value = 'Bob';

      expect(identical(form.toJson(), before), isFalse);
      expect(identical(form.toJson(omitNulls: true), beforeOmit), isFalse);
      expect(form.toJson()['alias'], equals('Bob'));
      expect(form.toJson(omitNulls: true)['alias'], equals('Bob'));
    });
  });

  // ===========================================================================
  // formGroup – applyWhen
  // ===========================================================================
  group('formGroup – applyWhen', () {
    test(
      'condição false pula validadores de todos os campos do grupo',
      () async {
        final form = formCtrl(() {
          final billing = formGroup(
            'billing',
            () => (
              street: Field<String>('street').required(),
              zip: Field<String>('zip').required(),
            ),
            applyWhen: (valueOf) => valueOf<bool>('hasBilling').value == true,
          );
          return (
            hasBilling: Field<bool>('hasBilling', false),
            billing: billing,
          );
        });
        addTearDown(form.dispose);

        await form.trigger();
        expect(form.fields.billing.street.error, isNull);
        expect(form.fields.billing.zip.error, isNull);
        expect(form.valid, isTrue);
      },
    );

    test(
      'condição true executa validadores de todos os campos do grupo',
      () async {
        final form = formCtrl(() {
          final billing = formGroup(
            'billing',
            () => (
              street: Field<String>('street').required(),
              zip: Field<String>('zip').required(),
            ),
            applyWhen: (valueOf) => valueOf<bool>('hasBilling').value == true,
          );
          return (
            hasBilling: Field<bool>('hasBilling', true),
            billing: billing,
          );
        });
        addTearDown(form.dispose);

        await form.trigger();
        expect(form.fields.billing.street.error, isNotNull);
        expect(form.fields.billing.zip.error, isNotNull);
        expect(form.valid, isFalse);
      },
    );

    test('composição com applyWhen de campo — AND lógico', () async {
      final form = formCtrl(() {
        final billing = formGroup(
          'billing',
          () => (
            street: Field<String>('street').applyWhen(
              (valueOf) => valueOf<String>('mode').value == 'strict',
              (f) => f.required(),
            ),
          ),
          applyWhen: (valueOf) => valueOf<bool>('hasBilling').value == true,
        );
        return (
          hasBilling: Field<bool>('hasBilling', true),
          mode: Field<String>('mode', 'relaxed'),
          billing: billing,
        );
      });
      addTearDown(form.dispose);

      await form.trigger();
      expect(form.fields.billing.street.error, isNull);

      form.fields.mode.value = 'strict';
      await form.trigger();
      expect(form.fields.billing.street.error, isNotNull);

      form.fields.hasBilling.value = false;
      await form.trigger();
      expect(form.fields.billing.street.error, isNull);
    });

    test('applyWhen de grupo funciona com validador assíncrono', () async {
      final form = formCtrl(() {
        final billing = formGroup(
          'billing',
          () => (
            zip: Field<String>(
              'zip',
            ).addValidatorAsync('CEP inválido', (_) async => true),
          ),
          applyWhen: (valueOf) => valueOf<bool>('hasBilling').value == true,
        );
        return (hasBilling: Field<bool>('hasBilling', false), billing: billing);
      });
      addTearDown(form.dispose);

      await form.trigger();
      expect(form.fields.billing.zip.error, isNull);

      form.fields.hasBilling.value = true;
      await form.trigger();
      expect(form.fields.billing.zip.error, isNotNull);
    });
  });

  // ===========================================================================
  // Field – switchWith
  // ===========================================================================
  group('Field – switchWith', () {
    test('case correto roda, outros são pulados', () async {
      final form = formCtrl(
        () => (
          mode: Field<String>('mode', 'BR'),
          doc: Field<String>('doc').switchWith<String>(
            (valueOf) => valueOf<String>('mode').value,
            {
              'BR': (f) =>
                  f.addValidator('BR inválido', (v) => v == null || v.isEmpty),
              'US': (f) => f.addValidator(
                'US inválido',
                (v) => v == null || v.length < 9,
              ),
            },
          ),
        ),
      );
      addTearDown(form.dispose);

      await form.trigger();
      expect(form.fields.doc.error, equals('BR inválido'));

      form.fields.doc.value = 'qualquer';
      await form.trigger();
      expect(form.fields.doc.error, isNull);
    });

    test('N cases — três casos possíveis', () async {
      final form = formCtrl(
        () => (
          type: Field<String>('type', 'A'),
          value: Field<String>('value')
              .switchWith<String>((valueOf) => valueOf<String>('type').value, {
                'A': (f) => f.addValidator('erro A', (v) => v == null),
                'B': (f) => f.addValidator('erro B', (v) => v == null),
                'C': (f) => f.addValidator('erro C', (v) => v == null),
              }),
        ),
      );
      addTearDown(form.dispose);

      for (final entry in {
        'A': 'erro A',
        'B': 'erro B',
        'C': 'erro C',
      }.entries) {
        form.fields.type.value = entry.key;
        form.fields.value.value = null;
        await form.trigger();
        expect(form.fields.value.error, equals(entry.value));
      }
    });

    test('keySelector retorna null → campo válido', () async {
      final form = formCtrl(
        () => (
          mode: Field<String>('mode'),
          doc: Field<String>('doc').switchWith<String>(
            (valueOf) => valueOf<String>('mode').value,
            {'BR': (f) => f.required()},
          ),
        ),
      );
      addTearDown(form.dispose);

      await form.trigger();
      expect(form.fields.doc.error, isNull);
    });

    test(
      'keySelector retorna chave sem case e orElse é null → campo válido',
      () async {
        final form = formCtrl(
          () => (
            mode: Field<String>('mode', 'XX'),
            doc: Field<String>('doc').switchWith<String>(
              (valueOf) => valueOf<String>('mode').value,
              {'BR': (f) => f.required()},
            ),
          ),
        );
        addTearDown(form.dispose);

        await form.trigger();
        expect(form.fields.doc.error, isNull);
      },
    );

    test('dependsOn: limpa erro quando campo observado muda', () {
      fakeAsync((async) {
        final form = formCtrl(
          () => (
            pais: Field<String>('pais', 'BR'),
            doc: Field<String>('doc')
                .validationMode(ValidationMode.onSubmit)
                .switchWith<String>(
                  (valueOf) => valueOf<String>('pais').value,
                  {'BR': (f) => f.required(), 'US': (f) => f.required()},
                  dependsOn: ['pais'],
                ),
          ),
        );
        addTearDown(form.dispose);

        form.trigger();
        async.flushMicrotasks();
        expect(form.fields.doc.error, isNotNull);

        form.fields.pais.value = 'US';
        async.flushMicrotasks();
        expect(form.fields.doc.error, isNull);
      });
    });

    test('dependsOn com múltiplos campos — qualquer mudança limpa erro', () {
      fakeAsync((async) {
        final form = formCtrl(
          () => (
            a: Field<String>('a', 'x'),
            b: Field<String>('b', 'y'),
            doc: Field<String>('doc')
                .validationMode(ValidationMode.onSubmit)
                .switchWith<String>(
                  (valueOf) => valueOf<String>('a').value,
                  {'x': (f) => f.required()},
                  dependsOn: ['a', 'b'],
                ),
          ),
        );
        addTearDown(form.dispose);

        form.trigger();
        async.flushMicrotasks();
        expect(form.fields.doc.error, isNotNull);

        form.fields.b.value = 'z';
        async.flushMicrotasks();
        expect(form.fields.doc.error, isNull);
      });
    });

    test('re-valida em onChange após campo dependsOn mudar', () {
      fakeAsync((async) {
        final form = formCtrl(
          () => (
            pais: Field<String>('pais', 'BR'),
            doc: Field<String>('doc', 'preenchido').switchWith<String>(
              (valueOf) => valueOf<String>('pais').value,
              {
                'BR': (f) => f.addValidator(
                  'cpf inválido',
                  (v) => v != null && v.length < 11,
                ),
              },
              dependsOn: ['pais'],
            ),
          ),
        );
        addTearDown(form.dispose);

        form.trigger();
        async.flushMicrotasks();
        expect(form.fields.doc.error, equals('cpf inválido'));

        form.fields.pais.value = 'US';
        async.flushMicrotasks();
        expect(form.fields.doc.error, isNull);

        form.fields.pais.value = 'BR';
        async.flushMicrotasks();
        form.fields.doc.value = '123';
        async.flushMicrotasks();
        expect(form.fields.doc.error, equals('cpf inválido'));
      });
    });

    test('sem dependsOn — erro persiste até próxima validação', () async {
      final form = formCtrl(
        () => (
          mode: Field<String>('mode', 'BR'),
          doc: Field<String>('doc').switchWith<String>(
            (valueOf) => valueOf<String>('mode').value,
            {'BR': (f) => f.required()},
          ),
        ),
      );
      addTearDown(form.dispose);

      await form.trigger();
      expect(form.fields.doc.error, isNotNull);

      form.fields.mode.value = 'US';
      expect(form.fields.doc.error, isNotNull);

      await form.trigger();
      expect(form.fields.doc.error, isNull);
    });

    test('orElse roda quando nenhum case corresponde', () async {
      final form = formCtrl(
        () => (
          mode: Field<String>('mode', 'XX'),
          doc: Field<String>('doc').switchWith<String>(
            (valueOf) => valueOf<String>('mode').value,
            {'BR': (f) => f.addValidator('erro BR', (v) => v == null)},
            orElse: (f) => f.addValidator('modo inválido', (_) => true),
          ),
        ),
      );
      addTearDown(form.dispose);

      await form.trigger();
      expect(form.fields.doc.error, equals('modo inválido'));
    });

    test('orElse não roda quando case corresponde', () async {
      final form = formCtrl(
        () => (
          mode: Field<String>('mode', 'BR'),
          doc: Field<String>('doc').switchWith<String>(
            (valueOf) => valueOf<String>('mode').value,
            {'BR': (f) => f.addValidator('erro BR', (v) => v == null)},
            orElse: (f) => f.addValidator('modo inválido', (_) => true),
          ),
        ),
      );
      addTearDown(form.dispose);

      await form.trigger();
      expect(form.fields.doc.error, equals('erro BR'));
    });

    test('orElse roda quando keySelector retorna null', () async {
      final form = formCtrl(
        () => (
          mode: Field<String>('mode'),
          doc: Field<String>('doc').switchWith<String>(
            (valueOf) => valueOf<String>('mode').value,
            {'BR': (f) => f.addValidator('erro BR', (v) => v == null)},
            orElse: (f) => f.required(),
          ),
        ),
      );
      addTearDown(form.dispose);

      await form.trigger();
      expect(form.fields.doc.error, isNotNull);
    });
  });

  // ===========================================================================
  // Field – detached
  // ===========================================================================
  group('Field – detached', () {
    test('Field.detached não é registrado no FormTracker', () {
      final form = formCtrl(() {
        final tracked = Field<String>('tracked');
        Field.detached<String>('orphan'); // não deve aparecer no form
        return tracked;
      });
      addTearDown(form.dispose);
      expect(form.debugFields.length, equals(1));
      expect(form.debugFields.first.name, equals('tracked'));
    });

    test('Field.detached usa o nome exatamente como passado (sem prefix)', () {
      final f = Field.detached<String>('my.field');
      addTearDown(f.dispose);
      expect(f.name, equals('my.field'));
    });

    test('Field.detached com initialValue funciona normalmente', () {
      final f = Field.detached<int>('age', 30);
      addTearDown(f.dispose);
      expect(f.value, equals(30));
      expect(f.isDirty, isFalse);
    });

    test('Field.detached aceita validadores e valida corretamente', () {
      final f = Field.detached<String>('email')
        ..addValidator('Obrigatório', (v) => v == null || v.isEmpty);
      addTearDown(f.dispose);
      f.value = '';
      expect(f.validate(), isFalse);
      f.value = 'a@b.com';
      expect(f.validate(), isTrue);
    });

    test('pauseTracking é restaurado mesmo se o construtor pudesse lançar', () {
      // Verifica que FormTracker não fica preso em pauseTracking=true
      Field.detached<String>('safe');
      // Se pauseTracking vazasse, este formCtrl não capturaria nenhum campo
      final form = formCtrl(() => Field<String>('x'));
      addTearDown(form.dispose);
      expect(form.debugFields.length, equals(1));
    });
  });

  // ===========================================================================
  // Field – clearError
  // ===========================================================================
  group('Field – clearError', () {
    test('clearError limpa o erro sem revalidar', () {
      final f = Field<String>('x')
        ..addValidator('Erro', (v) => true); // sempre falha
      addTearDown(f.dispose);
      f.validate(); // seta o erro
      expect(f.error, equals('Erro'));
      f.clearError();
      expect(f.error, isNull);
    });

    test('clearError não-op quando error já é null', () {
      final f = Field<String>('x');
      addTearDown(f.dispose);
      var notified = false;
      f.addListener(() => notified = true);
      f.clearError();
      expect(notified, isFalse);
    });

    test('clearError notifica listeners quando havia erro', () {
      final f = Field<String>('x');
      addTearDown(f.dispose);
      f.invalidate('erro externo');
      var notified = false;
      f.addListener(() => notified = true);
      f.clearError();
      expect(notified, isTrue);
      expect(f.error, isNull);
    });

    test('invalidate seguido de clearError não revalida', () {
      final f = Field<String>('x')..addValidator('Sempre erro', (v) => true);
      addTearDown(f.dispose);
      f.invalidate('Erro servidor');
      f.clearError();
      // error é null após clearError; validators NÃO foram re-executados
      expect(f.error, isNull);
    });
  });

  // ===========================================================================
  // Field – disable / enable
  // ===========================================================================
  group('Field – disable / enable', () {
    test('disable seta isDisabled=true e limpa o error', () {
      final f = Field<String>('x');
      addTearDown(f.dispose);
      f.invalidate('erro');
      f.disable();
      expect(f.isDisabled, isTrue);
      expect(f.error, isNull);
    });

    test('enable restaura isDisabled=false', () {
      final f = Field<String>('x');
      addTearDown(f.dispose);
      f.disable();
      f.enable();
      expect(f.isDisabled, isFalse);
    });

    test('campo desabilitado ignora todos os validators (sync)', () {
      final form = formCtrl(
        () => (
          name: Field<String>(
            'name',
          ).addValidator('Obrigatório', (v) => v == null || v.isEmpty),
        ),
      );
      addTearDown(form.dispose);
      form.fields.name.disable();
      expect(form.fields.name.validate(), isTrue);
      expect(form.fields.name.error, isNull);
    });

    test('campo desabilitado não contribui para form.errors', () async {
      final form = formCtrl(
        () => (
          name: Field<String>(
            'name',
          ).addValidator('Obrigatório', (v) => v == null || v.isEmpty),
        ),
      );
      addTearDown(form.dispose);
      form.fields.name.disable();
      await form.trigger();
      expect(form.errors, isEmpty);
    });

    test('campo desabilitado ainda aparece em toJson por padrão', () {
      final form = formCtrl(() => (x: Field<String>('x', 'valor')));
      addTearDown(form.dispose);
      form.fields.x.disable();
      expect(form.toJson()['x'], equals('valor'));
    });

    test('toJson(omitDisabled: true) exclui campos desabilitados', () {
      final form = formCtrl(
        () => (
          active: Field<String>('active', 'keep'),
          disabled: Field<String>('disabled', 'drop')..disable(),
        ),
      );
      addTearDown(form.dispose);
      final json = form.toJson(omitDisabled: true);
      expect(json.containsKey('active'), isTrue);
      expect(json.containsKey('disabled'), isFalse);
    });

    test(
      'toJson(omitDisabled: true) remove grupos aninhados que ficam vazios',
      () {
        final form = formCtrl(
          () => (
            addr: formGroup('addr', () => (city: Field<String>('city', 'SP'))),
          ),
        );
        addTearDown(form.dispose);
        form.fields.addr.city.disable();
        final json = form.toJson(omitDisabled: true);
        expect(json.containsKey('addr'), isFalse);
      },
    );

    test('disable() é no-op se já estiver desabilitado', () {
      final f = Field<String>('x');
      addTearDown(f.dispose);
      f.disable();
      var count = 0;
      f.addListener(() => count++);
      f.disable();
      expect(count, equals(0));
    });

    test('enable() é no-op se já estiver habilitado', () {
      final f = Field<String>('x');
      addTearDown(f.dispose);
      var count = 0;
      f.addListener(() => count++);
      f.enable();
      expect(count, equals(0));
    });

    test('re-habilitar restaura validação normal', () {
      final form = formCtrl(
        () => (
          name: Field<String>(
            'name',
          ).addValidator('Obrigatório', (v) => v == null || v.isEmpty),
        ),
      );
      addTearDown(form.dispose);
      form.fields.name.disable();
      form.fields.name.enable();
      form.fields.name.validate();
      expect(form.fields.name.error, equals('Obrigatório'));
    });
  });

  // ===========================================================================
  // FormController – fromJson
  // ===========================================================================
  group('FormController – fromJson', () {
    test('fromJson preenche campo a partir de mapa plano', () {
      final form = formCtrl(() => (name: Field<String>('name')));
      addTearDown(form.dispose);
      form.fromJson({'name': 'Alice'});
      expect(form.fields.name.value, equals('Alice'));
    });

    test('fromJson expande mapa aninhado em dot-notation', () {
      final form = formCtrl(
        () => (addr: formGroup('addr', () => (city: Field<String>('city')))),
      );
      addTearDown(form.dispose);
      form.fromJson({
        'addr': {'city': 'São Paulo'},
      });
      expect(form.fields.addr.city.value, equals('São Paulo'));
    });

    test('fromJson ignora chaves desconhecidas', () {
      final form = formCtrl(() => (x: Field<String>('x')));
      addTearDown(form.dispose);
      expect(
        () => form.fromJson({'x': 'ok', 'unknown': 'ignored'}),
        returnsNormally,
      );
      expect(form.fields.x.value, equals('ok'));
    });

    test('fromJson sem setAsInitial não altera initialValue', () {
      final form = formCtrl(() => (name: Field<String>('name')));
      addTearDown(form.dispose);
      form.fromJson({'name': 'Bob'});
      expect(form.fields.name.isDirty, isTrue);
      expect(form.fields.name.initialValue, isNull);
    });

    test('fromJson com setAsInitial:true atualiza initialValue', () {
      final form = formCtrl(() => (name: Field<String>('name')));
      addTearDown(form.dispose);
      form.fromJson({'name': 'Bob'}, setAsInitial: true);
      expect(form.fields.name.value, equals('Bob'));
      expect(form.fields.name.initialValue, equals('Bob'));
      expect(form.fields.name.isDirty, isFalse);
    });

    test(
      'fromJson setAsInitial:true faz reset() voltar ao valor carregado',
      () {
        final form = formCtrl(() => (name: Field<String>('name')));
        addTearDown(form.dispose);
        form.fromJson({'name': 'Alice'}, setAsInitial: true);
        form.fields.name.value = 'Bob';
        form.fields.name.reset();
        expect(form.fields.name.value, equals('Alice'));
      },
    );

    test('fromJson é batched — emite 1 notificação para N campos', () {
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
      form.fromJson({'a': '1', 'b': '2', 'c': '3'});
      expect(count, equals(1));
    });
  });

  // ===========================================================================
  // FormController – dirtyValues
  // ===========================================================================
  group('FormController – dirtyValues', () {
    test('retorna mapa vazio quando nenhum campo é dirty', () {
      final form = formCtrl(
        () =>
            (name: Field<String>('name', 'Alice'), age: Field<int>('age', 30)),
      );
      addTearDown(form.dispose);
      expect(form.dirtyValues(), isEmpty);
    });

    test('retorna apenas campos modificados', () {
      final form = formCtrl(
        () =>
            (name: Field<String>('name', 'Alice'), age: Field<int>('age', 30)),
      );
      addTearDown(form.dispose);
      form.fields.name.value = 'Bob';
      final patch = form.dirtyValues();
      expect(patch.containsKey('name'), isTrue);
      expect(patch.containsKey('age'), isFalse);
      expect(patch['name'], equals('Bob'));
    });

    test('retorna estrutura aninhada para formGroup', () {
      final form = formCtrl(
        () => (
          addr: formGroup('addr', () => (city: Field<String>('city', 'SP'))),
        ),
      );
      addTearDown(form.dispose);
      form.fields.addr.city.value = 'RJ';
      final patch = form.dirtyValues();
      expect((patch['addr'] as Map)['city'], equals('RJ'));
    });

    test('aplica transformToJson nos valores sujos', () {
      final form = formCtrl(() => (cpf: Field<String>('cpf').maskCPF()));
      addTearDown(form.dispose);
      form.fields.cpf.value = '12345678909';
      final patch = form.dirtyValues();
      // jsonValue de maskCPF remove a máscara
      expect(patch['cpf'], equals('12345678909'));
    });
  });

  // ===========================================================================
  // FormController – clearErrors
  // ===========================================================================
  group('FormController – clearErrors', () {
    test('clearErrors() sem path limpa todos os erros', () async {
      final form = formCtrl(
        () => (
          a: Field<String>('a').addValidator('e', (v) => true),
          b: Field<String>('b').addValidator('e', (v) => true),
        ),
      );
      addTearDown(form.dispose);
      await form.trigger();
      expect(form.errors.length, equals(2));
      form.clearErrors();
      expect(form.errors, isEmpty);
    });

    test('clearErrors(path:) limpa apenas campos do grupo', () async {
      final form = formCtrl(
        () => (
          addr: formGroup(
            'addr',
            () => (city: Field<String>('city').addValidator('e', (v) => true)),
          ),
          name: Field<String>('name').addValidator('e', (v) => true),
        ),
      );
      addTearDown(form.dispose);
      await form.trigger();
      expect(form.errors.length, equals(2));
      form.clearErrors(path: 'addr');
      expect(form.errors.containsKey('addr.city'), isFalse);
      expect(form.errors.containsKey('name'), isTrue);
    });

    test('clearErrors é batched — emite 1 notificação', () async {
      final form = formCtrl(
        () => (
          a: Field<String>('a').addValidator('e', (v) => true),
          b: Field<String>('b').addValidator('e', (v) => true),
        ),
      );
      addTearDown(form.dispose);
      await form.trigger();
      var count = 0;
      form.addListener(() => count++);
      form.clearErrors();
      expect(count, equals(1));
    });
  });
}
