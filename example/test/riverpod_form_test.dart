import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example/riverpod_form/pages/riverpod_form_page.dart';
import 'package:example/riverpod_form/notifier/riverpod_form_notifier.dart';

void main() {
  group('RiverpodFormNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'initial state resolves to AsyncData(null) after build completes',
      () async {
        // AsyncNotifierProvider starts as AsyncLoading while build() runs.
        // We read the future to wait for build() to finish.
        await container.read(riverpodFormProvider.future);
        final state = container.read(riverpodFormProvider);
        expect(state, const AsyncData<Map<String, dynamic>?>(null));
      },
    );

    test(
      'transitions to AsyncLoading then AsyncData on valid submission',
      () async {
        // Wait for the notifier to be fully initialized first
        await container.read(riverpodFormProvider.future);

        final states = <AsyncValue<Map<String, dynamic>?>>[];
        container.listen(riverpodFormProvider, (_, next) => states.add(next));

        await container.read(riverpodFormProvider.notifier).submitFeedback({
          'name': 'John',
          'email': 'john@example.com',
          'message': 'Hello!',
        });

        // states[0] = AsyncLoading (emitted when submitFeedback starts)
        // states[1] = AsyncData   (emitted on success)
        expect(states[0], isA<AsyncLoading>());
        expect(states[1], isA<AsyncData>());
        expect((states[1] as AsyncData).value, isNotNull);
      },
    );

    test(
      'transitions to AsyncLoading then AsyncError for error@error.com',
      () async {
        await container.read(riverpodFormProvider.future);

        final states = <AsyncValue<Map<String, dynamic>?>>[];
        container.listen(riverpodFormProvider, (_, next) => states.add(next));

        await container.read(riverpodFormProvider.notifier).submitFeedback({
          'name': 'Error User',
          'email': 'error@error.com',
          'message': 'Trigger error',
        });

        expect(states[0], isA<AsyncLoading>());
        expect(states[1], isA<AsyncError>());
      },
    );

    test('AsyncData carries the submitted data', () async {
      await container.read(riverpodFormProvider.future);
      final data = {
        'name': 'Jane',
        'email': 'jane@example.com',
        'message': 'Hi!',
      };
      await container.read(riverpodFormProvider.notifier).submitFeedback(data);

      final state = container.read(riverpodFormProvider);
      expect(state.value?['email'], equals('jane@example.com'));
    });

    test('AsyncError carries the error message', () async {
      await container.read(riverpodFormProvider.future);
      await container.read(riverpodFormProvider.notifier).submitFeedback({
        'name': 'Error User',
        'email': 'error@error.com',
        'message': 'trigger',
      });

      final state = container.read(riverpodFormProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('Erro de Servidor'));
    });

    test('reset() returns state to AsyncData(null)', () async {
      await container.read(riverpodFormProvider.future);
      await container.read(riverpodFormProvider.notifier).submitFeedback({
        'name': 'John',
        'email': 'john@example.com',
        'message': 'Hello!',
      });

      container.read(riverpodFormProvider.notifier).reset();

      expect(
        container.read(riverpodFormProvider),
        const AsyncData<Map<String, dynamic>?>(null),
      );
    });
  });

  group('RiverpodFormPage widget tests', () {
    Widget buildApp() =>
        const ProviderScope(child: MaterialApp(home: RiverpodFormPage()));

    testWidgets('renders form fields and submit button', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Nome Completo'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'E-mail'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Mensagem'), findsOneWidget);
      expect(find.text('Enviar Feedback'), findsWidgets);
    });

    testWidgets('shows validation errors when submitting empty form', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar Feedback').last);
      await tester.pumpAndSettle();

      expect(find.text('Nome é obrigatório'), findsOneWidget);
      expect(find.text('E-mail é obrigatório'), findsOneWidget);
      expect(find.text('Mensagem é obrigatória'), findsOneWidget);
    });

    testWidgets('shows loading indicator during submission', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Nome Completo'),
        'John Doe',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'E-mail'),
        'john@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Mensagem'),
        'A valid message here.',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar Feedback').last);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Drain the pending timer
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();
    });

    testWidgets('shows success dialog on valid submission', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Nome Completo'),
        'John Doe',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'E-mail'),
        'john@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Mensagem'),
        'A valid message here.',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar Feedback').last);
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      expect(find.text('Sucesso (Riverpod State)'), findsOneWidget);
      expect(find.text('Dados enviados:'), findsOneWidget);
    });

    testWidgets('shows error snack bar for error@error.com', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Nome Completo'),
        'Error User',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'E-mail'),
        'error@error.com',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Mensagem'),
        'This triggers an error.',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar Feedback').last);
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Erro de Servidor'), findsOneWidget);
    });
  });
}
