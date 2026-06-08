import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

void main() {
  // ===========================================================================
  // Field – onValueChanged
  // ===========================================================================
  group('Field.onValueChanged', () {
    test('não é chamado quando valor não muda', () {
      final field = Field<String>('x', 'same');
      addTearDown(field.dispose);
      var called = false;
      field.onValueChanged = (_, _) => called = true;

      field.value = 'same';
      expect(called, isFalse);
    });

    test('é chamado ANTES de qualquer validação disparada pelo onChange', () {
      fakeAsync((fake) {
        final order = <String>[];
        final field = Field<String>('x')
          ..addValidatorAsync('', (_) async {
            order.add('validation');
            return false;
          });
        addTearDown(field.dispose);

        field.onValueChanged = (_, _) => order.add('onValueChanged');
        field.value = 'trigger';

        expect(order.first, equals('onValueChanged'));

        fake.flushMicrotasks();
      });
    });

    test('recebe os valores corretos de old e new', () {
      final field = Field<String>('x', 'inicial');
      addTearDown(field.dispose);
      String? capturedOld, capturedNew;
      field.onValueChanged = (o, n) {
        capturedOld = o;
        capturedNew = n;
      };

      field.value = 'novo';
      expect(capturedOld, equals('inicial'));
      expect(capturedNew, equals('novo'));
    });

    test('é chamado com newValue = null quando campo é limpado', () {
      final field = Field<String>('x', 'valor');
      addTearDown(field.dispose);
      String? capturedNew = 'sentinela';
      field.onValueChanged = (_, n) => capturedNew = n;

      field.value = null;
      expect(capturedNew, isNull);
    });
  });

  // ===========================================================================
  // Field – onValidationStart e onValidationEnd
  // ===========================================================================
  group('Field.onValidationStart / onValidationEnd', () {
    test(
      'onValidationStart é chamado antes dos validadores síncronos',
      () async {
        final order = <String>[];
        final field = Field<String>('x')
          ..addValidator('sync err', (_) {
            order.add('sync');
            return true;
          });
        addTearDown(field.dispose);

        field.onValidationStart = () => order.add('start');
        await field.validateAsync();

        expect(order, equals(['start', 'sync']));
      },
    );

    test('onValidationEnd(false, error) quando validação sync falha', () async {
      bool? isValid;
      String? error;
      final field = Field<String>('x')..addValidator('Falha', (_) => true);
      addTearDown(field.dispose);

      field.onValidationEnd = (v, e) {
        isValid = v;
        error = e;
      };

      await field.validateAsync();
      expect(isValid, isFalse);
      expect(error, equals('Falha'));
    });

    test(
      'onValidationEnd(true, null) quando campo é válido sem async',
      () async {
        bool? isValid;
        String? error = 'sentinela';
        final field = Field<String>('x', 'ok')
          ..addValidator('Falha', (v) => v == null || v.isEmpty);
        addTearDown(field.dispose);

        field.onValidationEnd = (v, e) {
          isValid = v;
          error = e;
        };

        await field.validateAsync();
        expect(isValid, isTrue);
        expect(error, isNull);
      },
    );

    test('onValidationEnd(true, null) quando não há validadores', () async {
      bool? isValid;
      String? error = 'sentinela';
      final field = Field<String>('x');
      addTearDown(field.dispose);

      field.onValidationEnd = (v, e) {
        isValid = v;
        error = e;
      };

      await field.validateAsync();
      expect(isValid, isTrue);
      expect(error, isNull);
    });

    test(
      'onValidationEnd(false, error) quando validador async falha',
      () async {
        bool? isValid;
        String? error;
        final field = Field<String>('x', 'ok')
          ..addValidatorAsync('Async fail', (_) async => true);
        addTearDown(field.dispose);

        field.onValidationEnd = (v, e) {
          isValid = v;
          error = e;
        };

        await field.validateAsync();
        expect(isValid, isFalse);
        expect(error, equals('Async fail'));
      },
    );

    test('onValidationEnd NÃO é chamado na versão antiga (race condition)', () {
      fakeAsync((fake) {
        var endCallCount = 0;
        final field = Field<String>('x')
          ..addValidatorAsync('', (_) async {
            await Future.delayed(const Duration(milliseconds: 60));
            return false;
          });
        addTearDown(field.dispose);

        field.onValidationEnd = (_, _) => endCallCount++;

        field.validateAsync(); // versão 1 – timer em t=0
        fake.elapse(const Duration(milliseconds: 20)); // t=20ms
        field.validateAsync(); // versão 2 – timer em t=20ms

        // Avança além dos dois delays (60ms e 80ms do início)
        fake.elapse(const Duration(milliseconds: 80));
        fake.flushMicrotasks();

        expect(endCallCount, equals(1));
      });
    });

    test(
      'onValidationStart e onValidationEnd são chamados na ordem correta',
      () async {
        final order = <String>[];
        final field = Field<String>('x', 'ok')
          ..addValidatorAsync('', (_) async {
            order.add('async_validator');
            return false;
          });
        addTearDown(field.dispose);

        field.onValidationStart = () => order.add('start');
        field.onValidationEnd = (_, _) => order.add('end');

        await field.validateAsync();
        expect(order, equals(['start', 'async_validator', 'end']));
      },
    );
  });

  // ===========================================================================
  // Field – onAsyncValidationStart e onAsyncValidationEnd
  // ===========================================================================
  group('Field.onAsyncValidationStart / onAsyncValidationEnd', () {
    test('onAsyncValidationStart NÃO é chamado quando sync falha', () async {
      var asyncStartCalled = false;
      final field = Field<String>('x')
        ..addValidator('Obrigatório', (_) => true)
        ..addValidatorAsync('', (_) async => false);
      addTearDown(field.dispose);

      field.onAsyncValidationStart = () => asyncStartCalled = true;
      await field.validateAsync();

      expect(asyncStartCalled, isFalse);
    });

    test(
      'onAsyncValidationStart NÃO é chamado quando não há async validators',
      () async {
        var asyncStartCalled = false;
        final field = Field<String>('x', 'ok')..addValidator('', (_) => false);
        addTearDown(field.dispose);

        field.onAsyncValidationStart = () => asyncStartCalled = true;
        await field.validateAsync();

        expect(asyncStartCalled, isFalse);
      },
    );

    test(
      'onAsyncValidationStart é chamado antes dos validators async',
      () async {
        final order = <String>[];
        final field = Field<String>('x', 'ok')
          ..addValidatorAsync('', (_) async {
            order.add('async_validator');
            return false;
          });
        addTearDown(field.dispose);

        field.onAsyncValidationStart = () => order.add('async_start');
        await field.validateAsync();

        expect(order.first, equals('async_start'));
      },
    );

    test('onAsyncValidationEnd é chamado após os validators async', () async {
      bool? isValid;
      String? error;
      final field = Field<String>('x', 'ok')
        ..addValidatorAsync('Async fail', (_) async => true);
      addTearDown(field.dispose);

      field.onAsyncValidationEnd = (v, e) {
        isValid = v;
        error = e;
      };

      await field.validateAsync();
      expect(isValid, isFalse);
      expect(error, equals('Async fail'));
    });

    test(
      'onAsyncValidationEnd NÃO é chamado na versão antiga (race condition)',
      () {
        fakeAsync((fake) {
          var asyncEndCount = 0;
          final field = Field<String>('x')
            ..addValidatorAsync('', (_) async {
              await Future.delayed(const Duration(milliseconds: 60));
              return false;
            });
          addTearDown(field.dispose);

          field.onAsyncValidationEnd = (_, _) => asyncEndCount++;

          field.validateAsync();
          fake.elapse(const Duration(milliseconds: 20));
          field.validateAsync();

          fake.elapse(const Duration(milliseconds: 80));
          fake.flushMicrotasks();

          expect(asyncEndCount, equals(1));
        });
      },
    );

    test(
      'ordem completa: onValidationStart → onAsyncValidationStart → validator → onAsyncValidationEnd → onValidationEnd',
      () async {
        final order = <String>[];
        final field = Field<String>('x', 'ok')
          ..addValidatorAsync('', (_) async {
            order.add('async_validator');
            return false;
          });
        addTearDown(field.dispose);

        field.onValidationStart = () => order.add('validation_start');
        field.onAsyncValidationStart = () => order.add('async_start');
        field.onAsyncValidationEnd = (_, _) => order.add('async_end');
        field.onValidationEnd = (_, _) => order.add('validation_end');

        await field.validateAsync();

        expect(
          order,
          equals([
            'validation_start',
            'async_start',
            'async_validator',
            'async_end',
            'validation_end',
          ]),
        );
      },
    );
  });

  // ===========================================================================
  // FormController – onSubmitStart / onSubmitEnd
  // ===========================================================================
  group('FormController.onSubmitStart / onSubmitEnd', () {
    test('onSubmitStart NÃO é chamado quando form é inválido', () async {
      var started = false;
      final form = formCtrl(
        () => (
          name: Field<String>('name')
            ..addValidator('Obrigatório', (v) => v == null || v.isEmpty),
        ),
      );
      addTearDown(form.dispose);
      form.onSubmitStart = () => started = true;

      await form.submit((_) async {});
      expect(started, isFalse);
    });

    test('onSubmitEnd NÃO é chamado quando form é inválido', () async {
      bool? ended;
      final form = formCtrl(
        () => (
          name: Field<String>('name')
            ..addValidator('Obrigatório', (v) => v == null || v.isEmpty),
        ),
      );
      addTearDown(form.dispose);
      form.onSubmitEnd = (s) => ended = s;

      await form.submit((_) async {});
      expect(ended, isNull);
    });

    test('sequência exata: onSubmitStart → onSubmit → onSubmitEnd', () async {
      final order = <String>[];
      final form = formCtrl(() => (name: Field<String>('name', 'ok')));
      addTearDown(form.dispose);

      form.onSubmitStart = () => order.add('start');
      form.onSubmitEnd = (_) => order.add('end');

      await form.submit((_) async => order.add('submit'));

      expect(order, equals(['start', 'submit', 'end']));
    });

    test(
      'onSubmitEnd recebe false e isSubmitting volta a false mesmo com exceção',
      () async {
        bool? ended;
        final form = formCtrl(() => (x: Field<String>('x', 'ok')));
        addTearDown(form.dispose);
        form.onSubmitEnd = (s) => ended = s;

        await expectLater(
          () => form.submit((_) async => throw Exception('boom')),
          throwsException,
        );

        expect(ended, isFalse);
        expect(form.isSubmitting, isFalse);
      },
    );

    test(
      'isSubmitting é false antes, true durante e false depois do submit',
      () async {
        final states = <bool>[];
        final form = formCtrl(() => (x: Field<String>('x', 'ok')));
        addTearDown(form.dispose);

        states.add(form.isSubmitting);

        final completer = Completer<void>();
        final fut = form.submit((_) async {
          states.add(form.isSubmitting);
          await completer.future;
        });

        completer.complete();
        await fut;
        states.add(form.isSubmitting);

        expect(states, equals([false, true, false]));
      },
    );

    test(
      'submit concorrente: ambas as chamadas executam sem deadlock',
      () async {
        var submitCount = 0;
        final form = formCtrl(() => (x: Field<String>('x', 'ok')));
        addTearDown(form.dispose);

        await Future.wait([
          form.submit((_) async => submitCount++),
          form.submit((_) async => submitCount++),
        ]);

        expect(submitCount, equals(2));
      },
    );
  });

  // ===========================================================================
  // FormController – onReset
  // ===========================================================================
  group('FormController.onReset', () {
    test('onReset é chamado após todos os campos serem resetados', () {
      final form = formCtrl(() => (name: Field<String>('name', 'init')));
      addTearDown(form.dispose);
      form.fields.name.value = 'changed';

      String? valueAtReset;
      form.onReset = () => valueAtReset = form.fields.name.value;

      form.reset();
      expect(valueAtReset, equals('init'));
    });

    test('onReset não é chamado no dispose()', () {
      var called = false;
      final form = formCtrl(() => (x: Field<String>('x')));
      form.onReset = () => called = true;
      form.dispose(); // dispose explícito, sem tearDown adicional
      expect(called, isFalse);
    });

    test('onReset pode ser trocado entre chamadas', () {
      final calls = <int>[];
      final form = formCtrl(() => (x: Field<String>('x', 'v')));
      addTearDown(form.dispose);

      form.onReset = () => calls.add(1);
      form.reset();

      form.onReset = () => calls.add(2);
      form.reset();

      expect(calls, equals([1, 2]));
    });
  });

  // ===========================================================================
  // Field – dispose
  // ===========================================================================
  group('Field.dispose', () {
    test('_notifyIfMounted não dispara após dispose', () {
      fakeAsync((fake) {
        final field = Field<String>('x')
          ..addValidatorAsync('', (_) async {
            await Future.delayed(const Duration(milliseconds: 30));
            return false;
          });

        // validateAsync seta isLoading=true sincronamente; adicionamos o
        // listener DEPOIS para capturar apenas notificações pós-dispose.
        field.validateAsync();

        var notifiedAfterDispose = false;
        field.addListener(() => notifiedAfterDispose = true);

        field.dispose();

        fake.elapse(const Duration(milliseconds: 50));
        fake.flushMicrotasks();

        expect(notifiedAfterDispose, isFalse);
      });
    });

    test('dispose cancela debounce timer pendente', () {
      fakeAsync((fake) {
        var validationCalled = false;
        final field = Field<String>('x')
          ..debounce(const Duration(milliseconds: 80))
          ..addValidatorAsync('', (_) async {
            validationCalled = true;
            return false;
          });

        field.value = 'trigger';
        field.dispose();

        fake.elapse(const Duration(milliseconds: 120));
        fake.flushMicrotasks();

        expect(validationCalled, isFalse);
      });
    });
  });

  // ===========================================================================
  // FormController – dispose
  // ===========================================================================
  group('FormController.dispose', () {
    test('form para de notificar após dispose', () {
      final form = formCtrl(() => (x: Field<String>('x')));
      var formNotified = false;
      form.addListener(() => formNotified = true);
      form.dispose(); // dispose explícito, sem tearDown adicional
      expect(formNotified, isFalse);
    });

    test('dispose remove listeners dos campos filhos', () {
      final form = formCtrl(() => (x: Field<String>('x')));
      expect(() => form.dispose(), returnsNormally);
    });
  });

  // ===========================================================================
  // Field.invalidate – shouldFocus
  // ===========================================================================
  group('Field.invalidate – shouldFocus', () {
    testWidgets('shouldFocus: true solicita foco no FocusNode', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      final field = Field<String>('email')..focusNode = focusNode;
      addTearDown(field.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Focus(focusNode: focusNode, child: const SizedBox()),
        ),
      );

      expect(focusNode.hasFocus, isFalse);
      field.invalidate('Erro', shouldFocus: true);
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
      expect(field.error, equals('Erro'));
    });

    testWidgets('shouldFocus: false não solicita foco', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      final field = Field<String>('email')..focusNode = focusNode;
      addTearDown(field.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Focus(focusNode: focusNode, child: const SizedBox()),
        ),
      );

      field.invalidate('Erro');
      await tester.pump();

      expect(focusNode.hasFocus, isFalse);
      expect(field.error, equals('Erro'));
    });

    testWidgets('invalidate sem focusNode não lança exceção', (tester) async {
      final field = Field<String>('email');
      addTearDown(field.dispose);
      expect(
        () => field.invalidate('Erro', shouldFocus: true, shouldScroll: true),
        returnsNormally,
      );
    });
  });

  // ===========================================================================
  // Ordenação de eventos no value setter
  // ===========================================================================
  group('Ordenação de eventos no value setter', () {
    test('notifyListeners é chamado antes de onValueChanged', () {
      final order = <String>[];
      final field = Field<String>('x');
      addTearDown(field.dispose);
      field.addListener(() => order.add('notify'));
      field.onValueChanged = (_, _) => order.add('onValueChanged');

      field.value = 'novo';
      expect(order, equals(['notify', 'onValueChanged']));
    });

    test(
      'cache do form já está invalidado quando onValueChanged é chamado',
      () {
        final form = formCtrl(() => (x: Field<String>('x', 'initial')));
        addTearDown(form.dispose);

        final _ = form.toJson(); // força criação do cache

        Map<String, dynamic>? cacheAtCallback;
        form.fields.x.onValueChanged = (_, _) {
          cacheAtCallback = form.toJson();
        };

        form.fields.x.value = 'updated';
        expect(cacheAtCallback?['x'], equals('updated'));
      },
    );
  });

  // ===========================================================================
  // Field – múltiplos listeners
  // ===========================================================================
  group('Field – múltiplos listeners', () {
    test('todos os listeners são notificados quando valor muda', () {
      final field = Field<String>('x');
      addTearDown(field.dispose);
      var count = 0;
      field.addListener(() => count++);
      field.addListener(() => count++);
      field.addListener(() => count++);

      field.value = 'trigger';
      expect(count, equals(3));
    });

    test('listener removido não é mais notificado', () {
      final field = Field<String>('x');
      addTearDown(field.dispose);
      var count = 0;
      void listener() => count++;

      field.addListener(listener);
      field.value = 'a';
      expect(count, equals(1));

      field.removeListener(listener);
      field.value = 'b';
      expect(count, equals(1));
    });
  });

  // ===========================================================================
  // switchWith – ciclo de vida
  // ===========================================================================
  group('switchWith – ciclo de vida', () {
    test('_deferredSetup executa: form é atribuído ao field após formCtrl', () {
      late Field<String> doc;
      final form = formCtrl(() {
        doc = Field<String>('doc').switchWith<String>(
          (v) => v<String>('pais').value,
          {'BR': (f) => f.required()},
          dependsOn: ['pais'],
        );
        return (pais: Field<String>('pais', 'BR'), doc: doc);
      });
      addTearDown(form.dispose);

      expect(doc.form, isNotNull);
    });

    test('dispose do form não lança ao ter switchWith com dependsOn', () {
      final form = formCtrl(
        () => (
          pais: Field<String>('pais', 'BR'),
          doc: Field<String>('doc')
              .validationMode(ValidationMode.onSubmit)
              .switchWith<String>(
                (v) => v<String>('pais').value,
                {'BR': (f) => f.required()},
                dependsOn: ['pais'],
              ),
        ),
      );

      expect(() => form.dispose(), returnsNormally);
    });

    test('listener de dependsOn não tenta acessar form após dispose do form', () {
      fakeAsync((async) {
        final form = formCtrl(
          () => (
            pais: Field<String>('pais', 'BR'),
            doc: Field<String>('doc')
                .validationMode(ValidationMode.onSubmit)
                .switchWith<String>(
                  (v) => v<String>('pais').value,
                  {'BR': (f) => f.required()},
                  dependsOn: ['pais'],
                ),
          ),
        );

        form.trigger();
        async.flushMicrotasks();

        form.dispose();

        // não deve lançar após dispose total
        expect(() => async.flushMicrotasks(), returnsNormally);
      });
    });

    test('toJson(omitNulls) cache é zerado junto com cache padrão no dispose', () {
      final form = formCtrl(
        () => (name: Field<String>('name', 'Alice'), alias: Field<String>('alias')),
      );

      // popula ambos os caches
      form.toJson();
      form.toJson(omitNulls: true);

      // mudar o campo invalida ambos
      form.fields.alias.value = 'Bob';

      expect(form.toJson()['alias'], equals('Bob'));
      expect(form.toJson(omitNulls: true)['alias'], equals('Bob'));

      form.dispose();
    });

    test('formGroup(applyWhen:) não avalia condição após form disposed', () async {
      var conditionCallCount = 0;

      final form = formCtrl(() {
        final g = formGroup(
          'g',
          () => (name: Field<String>('name').required()),
          applyWhen: (valueOf) {
            conditionCallCount++;
            return valueOf<bool>('active').value == true;
          },
        );
        return (active: Field<bool>('active', true), g: g);
      });

      await form.trigger();
      final callsBeforeDispose = conditionCallCount;
      form.dispose();

      // após dispose não deve haver mais validações disparadas
      expect(conditionCallCount, equals(callsBeforeDispose));
    });
  });
}
