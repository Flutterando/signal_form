import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/bloc_form/pages/bloc_form_page.dart';
import 'package:example/bloc_form/cubit/bloc_form_cubit.dart';
import 'package:example/bloc_form/cubit/bloc_form_state.dart';

void main() {
  group('BlocFormCubit', () {
    late BlocFormCubit cubit;

    setUp(() {
      cubit = BlocFormCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is BlocFormInitial', () {
      expect(cubit.state, isA<BlocFormInitial>());
    });

    test(
      'emits [BlocFormSubmitting, BlocFormSuccess] on valid submission',
      () async {
        expectLater(
          cubit.stream,
          emitsInOrder([isA<BlocFormSubmitting>(), isA<BlocFormSuccess>()]),
        );

        await cubit.submitFeedback({
          'name': 'John Doe',
          'email': 'john@example.com',
          'message': 'This is a test message.',
        });
      },
    );

    test(
      'emits [BlocFormSubmitting, BlocFormFailure] for error@error.com',
      () async {
        expectLater(
          cubit.stream,
          emitsInOrder([isA<BlocFormSubmitting>(), isA<BlocFormFailure>()]),
        );

        await cubit.submitFeedback({
          'name': 'Error User',
          'email': 'error@error.com',
          'message': 'This should trigger a failure.',
        });
      },
    );

    test('BlocFormSuccess carries submitted data', () async {
      final data = {
        'name': 'Jane Smith',
        'email': 'jane@example.com',
        'message': 'Hello from test!',
      };

      await cubit.submitFeedback(data);

      final state = cubit.state as BlocFormSuccess;
      expect(state.data['email'], equals('jane@example.com'));
      expect(state.data['name'], equals('Jane Smith'));
    });

    test('BlocFormFailure carries error message', () async {
      await cubit.submitFeedback({
        'name': 'Error User',
        'email': 'error@error.com',
        'message': 'trigger error',
      });

      final state = cubit.state as BlocFormFailure;
      expect(state.errorMessage, isNotEmpty);
    });
  });

  group('BlocFormPage widget tests', () {
    Widget buildApp() => const MaterialApp(home: BlocFormPage());

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

      // Tap submit without filling fields
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
      // Pump just enough to let the submission start but not complete (1500ms delay)
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Drain the pending 1500ms timer so the widget tree can be safely disposed
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
      // Advance past the 1500ms network simulation delay
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();

      expect(find.text('Sucesso (Cubit State)'), findsOneWidget);
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
