import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/simple_form/login_form.dart';
import 'package:example/simple_form/simple_form_page.dart';

Widget buildLoginForm() => const MaterialApp(home: Scaffold(body: LoginForm()));

Widget buildSimpleFormPage() => const MaterialApp(home: SimpleFormPage());

void main() {
  // Tela maior para evitar que o botão "Entrar" fique fora dos bounds
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('LoginForm — renderização', () {
    testWidgets('exibe campos Email, Senha, checkbox e botão Entrar', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(buildLoginForm());
      await tester.pumpAndSettle();
      addTearDown(() => tester.binding.setSurfaceSize(null));

      expect(find.widgetWithText(TextField, 'E-mail'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Senha'), findsOneWidget);
      expect(find.text('Lembrar-me'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
    });
  });

  group('LoginForm — validação de campos obrigatórios', () {
    testWidgets('mostra erros ao submeter form vazio', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildLoginForm());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('O e-mail é obrigatório'), findsOneWidget);
      expect(find.text('A senha é obrigatória'), findsOneWidget);
    });

    testWidgets('mostra erro de formato ao digitar e-mail inválido', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildLoginForm());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'E-mail'),
        'nao-e-email',
      );
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('E-mail inválido'), findsOneWidget);
    });

    testWidgets(
      'customPassword exige mínimo 6 chars — exibe erro com senha curta',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildLoginForm());
        await tester.pumpAndSettle();

        await tester.enterText(find.widgetWithText(TextField, 'Senha'), 'abc');
        await tester.tap(find.text('Entrar'));
        await tester.pumpAndSettle();

        expect(
          find.text('A senha deve ter pelo menos 6 caracteres'),
          findsOneWidget,
        );
      },
    );
  });

  group('LoginForm — toggle de visibilidade da senha', () {
    testWidgets('alterna ícone ao tocar no botão de visibilidade', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildLoginForm());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });

  group(
    'LoginForm — validação assíncrona de email único (customUniqueEmail)',
    () {
      testWidgets('"admin@admin.com" falha na validação assíncrona', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildLoginForm());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'E-mail'),
          'admin@admin.com',
        );

        // debounce 800ms + async delay 1200ms
        await tester.pump(const Duration(milliseconds: 800));
        await tester.pump(const Duration(milliseconds: 1200));
        await tester.pumpAndSettle();

        // Toca em outro campo para marcar email como 'touched' e exibir o erro
        await tester.tap(find.widgetWithText(TextField, 'Senha'));
        await tester.pumpAndSettle();

        expect(find.text('Email inválido'), findsOneWidget);
      });

      testWidgets('email livre passa na validação assíncrona', (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildLoginForm());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'E-mail'),
          'user@example.com',
        );

        await tester.pump(const Duration(milliseconds: 800));
        await tester.pump(const Duration(milliseconds: 1200));
        await tester.pumpAndSettle();

        expect(find.text('Email inválido'), findsNothing);
      });
    },
  );

  group('LoginForm — fluxo completo', () {
    testWidgets('submissão com credenciais válidas exibe SnackBar de sucesso', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildLoginForm());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'E-mail'),
        'user@example.com',
      );
      // Avança validação assíncrona
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Senha'),
        'Senha@1',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Entrar'));
      // submit() re-executa o async email validator (1200ms)
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Login realizado com sucesso!'),
        findsOneWidget,
      );
    });
  });

  group('LoginForm — integração com SimpleFormPage', () {
    testWidgets('a aba "Entrar" exibe o LoginForm por padrão', (tester) async {
      await tester.pumpWidget(buildSimpleFormPage());
      await tester.pumpAndSettle();

      expect(find.byType(LoginForm), findsOneWidget);
    });

    testWidgets('navegar para aba "Cadastrar" exibe o RegisterForm', (
      tester,
    ) async {
      await tester.pumpWidget(buildSimpleFormPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cadastrar').first);
      await tester.pumpAndSettle();

      expect(find.text('Criar Nova Conta'), findsOneWidget);
    });
  });
}
