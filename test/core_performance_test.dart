import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

// Thresholds são generosos para não ser flaky em CI mais lento.
// O objetivo é capturar regressões de complexidade (ex: O(n) → O(n²)),
// não micro-otimizações de nanosegundos.

void main() {
  // ===========================================================================
  // Field – criação em massa
  // ===========================================================================
  group('Perf – Field: criação em massa', () {
    test('criar e descartar 500 Fields leva < 200ms', () {
      final sw = Stopwatch()..start();
      final fields = List.generate(500, (i) => Field<String>('perf_field_$i'));
      sw.stop();

      for (final f in fields) {
        f.dispose();
      }

      expect(
        sw.elapsedMilliseconds,
        lessThan(200),
        reason: 'Construtor de Field não deve ter overhead quadrático',
      );
    });
  });

  // ===========================================================================
  // Field – value setter throughput
  // ===========================================================================
  group('Perf – Field: value setter', () {
    test('10.000 atribuições sem validadores leva < 200ms', () {
      final field = Field<String>('x')..validationMode(ValidationMode.onSubmit);
      addTearDown(field.dispose);

      for (var i = 0; i < 200; i++) {
        field.value = 'warmup_$i'; // JIT warmup
      }

      final sw = Stopwatch()..start();
      for (var i = 0; i < 10000; i++) {
        field.value = 'v$i';
      }
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(200));
    });

    test('5.000 atribuições com máscara de telefone leva < 300ms', () {
      final field = Field<String>('phone')
        ..mask('(##) #####-####')
        ..validationMode(ValidationMode.onSubmit);
      addTearDown(field.dispose);

      for (var i = 0; i < 50; i++) {
        field.value = '11999990000'; // warmup
      }

      final sw = Stopwatch()..start();
      for (var i = 0; i < 5000; i++) {
        field.value = '11999990000';
      }
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(300));
    });

    test('10.000 atribuições com valor idêntico (no-op) leva < 100ms', () {
      final field = Field<String>('x', 'same')
        ..validationMode(ValidationMode.onSubmit);
      addTearDown(field.dispose);

      final sw = Stopwatch()..start();
      for (var i = 0; i < 10000; i++) {
        field.value = 'same';
      }
      sw.stop();

      expect(
        sw.elapsedMilliseconds,
        lessThan(100),
        reason: 'Setter com valor igual deve ser O(1) e não notificar',
      );
    });
  });

  // ===========================================================================
  // Field – sync validation throughput
  // ===========================================================================
  group('Perf – Field: validação síncrona', () {
    test('50.000 chamadas a validate() com 1 validator leva < 500ms', () {
      final field = Field<String>('x', 'ok')
        ..addValidator('Fail', (v) => v == null || v.isEmpty);
      addTearDown(field.dispose);

      for (var i = 0; i < 1000; i++) {
        field.validate(); // warmup
      }

      final sw = Stopwatch()..start();
      for (var i = 0; i < 50000; i++) {
        field.validate();
      }
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    test('1.000 chamadas a validate() com 50 validators leva < 500ms', () {
      final field = Field<String>('x', 'ok');
      addTearDown(field.dispose);

      for (var i = 0; i < 50; i++) {
        field.addValidator('r$i', (_) => false); // todos passam
      }

      for (var i = 0; i < 20; i++) {
        field.validate(); // warmup
      }

      final sw = Stopwatch()..start();
      for (var i = 0; i < 1000; i++) {
        field.validate();
      }
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    test(
      'validate() para no 1º erro: 50 validators, falha no 1º leva < 200ms para 10.000 chamadas',
      () {
        final field = Field<String>('x');
        addTearDown(field.dispose);

        // Primeiro validator sempre falha → os outros 49 nunca são avaliados
        field.addValidator('obrigatorio', (_) => true);
        for (var i = 0; i < 49; i++) {
          field.addValidator('r$i', (_) => false);
        }

        final sw = Stopwatch()..start();
        for (var i = 0; i < 10000; i++) {
          field.validate();
        }
        sw.stop();

        expect(
          sw.elapsedMilliseconds,
          lessThan(200),
          reason:
              'Short-circuit deve manter complexidade O(1) no pior caso do 1º validator',
        );
      },
    );
  });

  // ===========================================================================
  // Field – listener fanout
  // ===========================================================================
  group('Perf – Field: listeners', () {
    test('notificar 500 listeners com 1 value change leva < 50ms', () {
      final field = Field<String>('x')..validationMode(ValidationMode.onSubmit);
      addTearDown(field.dispose);

      var count = 0;
      for (var i = 0; i < 500; i++) {
        field.addListener(() => count++);
      }

      final sw = Stopwatch()..start();
      field.value = 'trigger';
      sw.stop();

      expect(count, equals(500));
      expect(sw.elapsedMilliseconds, lessThan(50));
    });
  });

  // ===========================================================================
  // FormController – criação com muitos campos
  // ===========================================================================
  group('Perf – FormController: criação', () {
    test('form com 200 campos é criado em < 200ms', () {
      final sw = Stopwatch()..start();
      final form = formCtrl(
        () => List.generate(200, (i) => Field<String>('fc_$i', 'v$i')),
      );
      sw.stop();

      addTearDown(form.dispose);
      expect(sw.elapsedMilliseconds, lessThan(200));
    });
  });

  // ===========================================================================
  // FormController – toJson() cache
  // ===========================================================================
  group('Perf – FormController: toJson()', () {
    test('10.000 cache hits com 50 campos leva < 50ms', () {
      final form = formCtrl(
        () => List.generate(50, (i) => Field<String>('tj_$i', 'val$i')),
      );
      addTearDown(form.dispose);

      form.toJson(); // popula cache

      for (var i = 0; i < 200; i++) {
        form.toJson(); // warmup
      }

      final sw = Stopwatch()..start();
      for (var i = 0; i < 10000; i++) {
        form.toJson();
      }
      sw.stop();

      expect(
        sw.elapsedMilliseconds,
        lessThan(50),
        reason: 'Cache hit deve ser O(1)',
      );
    });

    test('1.000 cache misses + rebuild com 50 campos leva < 500ms', () {
      final form = formCtrl(
        () => List.generate(50, (i) {
          return Field<String>('cm_$i', 'val$i')
            ..validationMode(ValidationMode.onSubmit);
        }),
      );
      addTearDown(form.dispose);

      for (var i = 0; i < 10; i++) {
        form.fields[0].value = 'warmup_$i';
        form.toJson();
      }

      final sw = Stopwatch()..start();
      for (var i = 0; i < 1000; i++) {
        form.fields[i % 50].value = 'updated_$i'; // invalida cache
        form.toJson(); // rebuild
      }
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    test('toJson() retorna objeto identico em cache hits consecutivos', () {
      final form = formCtrl(() => (x: Field<String>('x', 'v')));
      addTearDown(form.dispose);

      final a = form.toJson();
      final b = form.toJson();
      expect(
        identical(a, b),
        isTrue,
        reason: 'Cache deve retornar a mesma instância, não uma cópia',
      );
    });
  });

  // ===========================================================================
  // FormController – errors cache
  // ===========================================================================
  group('Perf – FormController: errors', () {
    test('10.000 leituras de errors (cache hit) com 50 campos leva < 50ms', () {
      final form = formCtrl(
        () => List.generate(50, (i) {
          final f = Field<String>('er_$i');
          if (i % 5 == 0) f.invalidate('erro_$i');
          return f;
        }),
      );
      addTearDown(form.dispose);

      final _ = form.errors; // popula cache

      for (var i = 0; i < 200; i++) {
        form.errors; // warmup
      }

      final sw = Stopwatch()..start();
      for (var i = 0; i < 10000; i++) {
        form.errors;
      }
      sw.stop();

      expect(
        sw.elapsedMilliseconds,
        lessThan(50),
        reason: 'Cache hit deve ser O(1)',
      );
    });
  });

  // ===========================================================================
  // FormController – getField() O(1) via HashMap
  // ===========================================================================
  group('Perf – FormController: getField()', () {
    test('50.000 lookups em form com 200 campos leva < 200ms', () {
      final form = formCtrl(
        () => List.generate(200, (i) => Field<String>('lk_$i')),
      );
      addTearDown(form.dispose);

      for (var i = 0; i < 1000; i++) {
        form.getField('lk_${i % 200}'); // warmup
      }

      final sw = Stopwatch()..start();
      for (var i = 0; i < 50000; i++) {
        form.getField('lk_${i % 200}');
      }
      sw.stop();

      expect(
        sw.elapsedMilliseconds,
        lessThan(200),
        reason:
            'getField() usa HashMap → deve ser O(1) independente do tamanho do form',
      );
    });

    test('tempo de lookup é constante: form com 10 vs 500 campos é comparável', () {
      final smallForm = formCtrl(
        () => List.generate(10, (i) => Field<String>('sm_$i')),
      );
      addTearDown(smallForm.dispose);

      final largeForm = formCtrl(
        () => List.generate(500, (i) => Field<String>('lg_$i')),
      );
      addTearDown(largeForm.dispose);

      const iterations = 20000;

      final swSmall = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        smallForm.getField('sm_${i % 10}');
      }
      swSmall.stop();

      final swLarge = Stopwatch()..start();
      for (var i = 0; i < iterations; i++) {
        largeForm.getField('lg_${i % 500}');
      }
      swLarge.stop();

      // O large form (50x maior) não deve levar mais do que 3x o tempo do small
      expect(
        swLarge.elapsedMicroseconds,
        lessThan(swSmall.elapsedMicroseconds * 3),
        reason:
            'Lookup O(1): escalar de 10 para 500 campos não deve degradar linearmente',
      );
    });
  });

  // ===========================================================================
  // FormController – patchValue() em massa
  // ===========================================================================
  group('Perf – FormController: patchValue()', () {
    test('500 chamadas de patchValue com 50 campos leva < 500ms', () {
      final form = formCtrl(
        () => List.generate(50, (i) {
          return Field<String>('pv_$i')
            ..validationMode(ValidationMode.onSubmit);
        }),
      );
      addTearDown(form.dispose);

      final patch = {for (var i = 0; i < 50; i++) 'pv_$i': 'v$i'};

      for (var i = 0; i < 10; i++) {
        form.patchValue(patch); // warmup
      }

      final sw = Stopwatch()..start();
      for (var i = 0; i < 500; i++) {
        form.patchValue(patch);
      }
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(500));
    });
  });

  // ===========================================================================
  // FormController – reset() em massa
  // ===========================================================================
  group('Perf – FormController: reset()', () {
    test('1.000 resets em form com 100 campos leva < 500ms', () {
      final form = formCtrl(
        () => List.generate(100, (i) => Field<String>('rs_$i', 'initial_$i')),
      );
      addTearDown(form.dispose);

      for (var i = 0; i < 5; i++) {
        form.reset(); // warmup
      }

      final sw = Stopwatch()..start();
      for (var i = 0; i < 1000; i++) {
        form.reset();
      }
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(500));
    });
  });

  // ===========================================================================
  // FormController – trigger() com sync validators
  // ===========================================================================
  group('Perf – FormController: trigger()', () {
    test('trigger() em 100 campos com 1 sync validator leva < 500ms', () async {
      final form = formCtrl(
        () => List.generate(100, (i) {
          return Field<String>('tr_$i', 'ok')
            ..addValidator('Fail', (v) => v == null || v.isEmpty);
        }),
      );
      addTearDown(form.dispose);

      final sw = Stopwatch()..start();
      final result = await form.trigger();
      sw.stop();

      expect(result, isTrue);
      expect(sw.elapsedMilliseconds, lessThan(500));
    });
  });

  // ===========================================================================
  // Debounce – absorção de rajada de eventos
  // ===========================================================================
  group('Perf – Debounce: absorção de rajada', () {
    test('1.000 value changes com debounce dispara exatamente 1 validação', () {
      fakeAsync((fake) {
        var validationCount = 0;
        final field = Field<String>('search')
          ..debounce(const Duration(milliseconds: 100))
          ..addValidatorAsync('', (_) async {
            validationCount++;
            return false;
          });
        addTearDown(field.dispose);

        for (var i = 0; i < 1000; i++) {
          field.value = 'query_$i';
        }

        fake.elapse(const Duration(milliseconds: 200));
        fake.flushMicrotasks();

        expect(
          validationCount,
          equals(1),
          reason:
              'Debounce deve absorver todas as mudanças e disparar apenas 1 validação',
        );
      });
    });

    test(
      'N rajadas separadas por debounce disparam exatamente N validações',
      () {
        fakeAsync((fake) {
          var validationCount = 0;
          final field = Field<String>('search')
            ..debounce(const Duration(milliseconds: 100))
            ..addValidatorAsync('', (_) async {
              validationCount++;
              return false;
            });
          addTearDown(field.dispose);

          // 3 rajadas separadas por > debounce
          for (var i = 0; i < 100; i++) {
            field.value = 'burst1_$i';
          }
          fake.elapse(const Duration(milliseconds: 150));
          fake.flushMicrotasks();

          for (var i = 0; i < 100; i++) {
            field.value = 'burst2_$i';
          }
          fake.elapse(const Duration(milliseconds: 150));
          fake.flushMicrotasks();

          for (var i = 0; i < 100; i++) {
            field.value = 'burst3_$i';
          }
          fake.elapse(const Duration(milliseconds: 150));
          fake.flushMicrotasks();

          expect(validationCount, equals(3));
        });
      },
    );
  });

  // ===========================================================================
  // Race condition – escala com muitas versões concorrentes
  // ===========================================================================
  group('Perf – Race condition: escala', () {
    test(
      '50 validateAsync() consecutivos: apenas o último dispara onValidationEnd',
      () {
        fakeAsync((fake) {
          var endCallCount = 0;
          final field = Field<String>('x')
            ..addValidatorAsync('', (_) async {
              await Future.delayed(const Duration(milliseconds: 10));
              return false;
            });
          addTearDown(field.dispose);

          field.onValidationEnd = (_, _) => endCallCount++;

          for (var i = 0; i < 50; i++) {
            field.validateAsync();
            fake.elapse(const Duration(milliseconds: 1));
          }

          fake.elapse(const Duration(milliseconds: 100));
          fake.flushMicrotasks();

          expect(
            endCallCount,
            equals(1),
            reason:
                'Proteção de race condition deve descartar todas as versões obsoletas',
          );
        });
      },
    );

    test(
      '50 validateAsync() consecutivos: isLoading volta a false no final',
      () {
        fakeAsync((fake) {
          final field = Field<String>('x')
            ..addValidatorAsync('', (_) async {
              await Future.delayed(const Duration(milliseconds: 10));
              return false;
            });
          addTearDown(field.dispose);

          for (var i = 0; i < 50; i++) {
            field.validateAsync();
            fake.elapse(const Duration(milliseconds: 1));
          }

          fake.elapse(const Duration(milliseconds: 100));
          fake.flushMicrotasks();

          expect(field.isLoading, isFalse);
          expect(field.isLoading, isFalse);
        });
      },
    );
  });

  // ===========================================================================
  // Async validation – onAsyncValidationStart/End em escala
  // ===========================================================================
  group('Perf – onAsyncValidationStart/End: escala', () {
    test(
      '100 validateAsync() com async validators dispara 100 pares start/end',
      () async {
        var startCount = 0;
        var endCount = 0;
        final field = Field<String>('x', 'ok')
          ..addValidatorAsync('', (_) async => false);
        addTearDown(field.dispose);

        field.onAsyncValidationStart = () => startCount++;
        field.onAsyncValidationEnd = (_, _) => endCount++;

        // Chamadas sequenciais (cada uma aguarda a anterior)
        for (var i = 0; i < 100; i++) {
          await field.validateAsync();
        }

        expect(startCount, equals(100));
        expect(endCount, equals(100));
      },
    );
  });

  // ===========================================================================
  // toJson(omitNulls) – desempenho
  // ===========================================================================
  group('Perf – toJson(omitNulls)', () {
    test('cache hit em form com 200 campos retorna em < 1ms', () {
      final form = formCtrl(() {
        for (var i = 0; i < 200; i++) {
          Field<String>('field_$i', i.isEven ? 'value_$i' : null);
        }
        return Field<String>('sentinel');
      });
      addTearDown(form.dispose);

      form.toJson(omitNulls: true); // constrói o cache

      final sw = Stopwatch()..start();
      for (var i = 0; i < 1000; i++) {
        form.toJson(omitNulls: true); // apenas hit de cache
      }
      sw.stop();

      expect(
        sw.elapsedMilliseconds,
        lessThan(10),
        reason: '1.000 cache hits devem ser quase instantâneos',
      );
    });

    test('construção inicial com 200 campos nulos e poda leva < 100ms', () {
      final sw = Stopwatch()..start();

      for (var run = 0; run < 20; run++) {
        final form = formCtrl(() {
          for (var i = 0; i < 200; i++) {
            formGroup('g$i', () => (f: Field<String>('val')));
          }
          return Field<String>('root');
        });
        form.toJson(omitNulls: true);
        form.dispose();
      }

      sw.stop();
      expect(
        sw.elapsedMilliseconds,
        lessThan(100),
        reason: '20 formulários com 200 grupos nulos cada devem ser construídos e podados em < 100ms',
      );
    });
  });

  // ===========================================================================
  // switchWith – desempenho
  // ===========================================================================
  group('Perf – switchWith', () {
    test('trigger em form com 50 campos switchWith leva < 500ms', () async {
      final form = formCtrl(() {
        final selector = Field<String>('selector', 'A');
        for (var i = 0; i < 50; i++) {
          Field<String>('field_$i').switchWith<String>(
            (valueOf) => valueOf<String>('selector').value,
            {
              'A': (f) => f.addValidator('err', (v) => v == null),
              'B': (f) => f.addValidator('err', (v) => v == null),
              'C': (f) => f.addValidator('err', (v) => v == null),
            },
          );
        }
        return selector;
      });
      addTearDown(form.dispose);

      final sw = Stopwatch()..start();
      for (var i = 0; i < 10; i++) {
        await form.trigger();
      }
      sw.stop();

      expect(
        sw.elapsedMilliseconds,
        lessThan(500),
        reason: '10 trigger()s em form com 50 switchWith não devem ser lentos',
      );
    });
  });
}
