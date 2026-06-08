import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';
import 'package:example/simple_form/register_form.dart';
import 'package:example/simple_form/simple_form_page.dart';

Widget buildRegisterForm() =>
    const MaterialApp(home: Scaffold(body: RegisterForm()));

/// Seta o tamanho da tela de testes para caber o form completo
Future<void> setLargeScreen(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

/// Digita email e drena os timers assíncronos para evitar pending timer
Future<void> enterEmailAndDrain(WidgetTester tester, String email) async {
  await tester.enterText(find.widgetWithText(TextField, 'E-mail'), email);
  await tester.pump(const Duration(milliseconds: 800)); // debounce
  await tester.pump(const Duration(milliseconds: 1200)); // async delay
  await tester.pumpAndSettle();
}

/// Seta diretamente o valor no Signal Field de senha (contorna o enterText
/// que não dispara onChanged em campos obscurecidos via ListenableBuilder).
void setPasswordField(WidgetTester tester, int fieldIndex, String value) {
  tester.widget<TextField>(find.byType(TextField).at(fieldIndex));
  final sf = tester.widget<SignalTextField>(
    find.byType(SignalTextField).at(fieldIndex - 2),
  );
  sf.field.value = value;
}

void main() {
  group('RegisterForm — renderização', () {
    testWidgets('exibe todos os campos do formulário', (tester) async {
      await setLargeScreen(tester);
      await tester.pumpWidget(buildRegisterForm());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Nome Completo'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'E-mail'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Senha'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Confirmar Senha'), findsOneWidget);
      expect(find.text('Aceito os termos e condições'), findsOneWidget);
      expect(find.text('Cadastrar'), findsOneWidget);
    });
  });

  group('RegisterForm — validação de campos obrigatórios', () {
    testWidgets('mostra todos os erros ao submeter form vazio', (tester) async {
      await setLargeScreen(tester);
      await tester.pumpWidget(buildRegisterForm());
      await tester.pumpAndSettle();

      // Sem email — o async validator do email ainda é chamado no submit (null value)
      await tester.tap(find.text('Cadastrar'));
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();

      expect(find.text('O nome é obrigatório'), findsOneWidget);
      expect(find.text('O e-mail é obrigatório'), findsOneWidget);
      // Dois campos de senha com .required() via customPassword()
      expect(find.text('A senha é obrigatória'), findsNWidgets(2));
      expect(
        find.text('Você precisa aceitar os termos e condições'),
        findsOneWidget,
      );
    });

    testWidgets('mostra erro de nome muito curto (< 3 chars)', (tester) async {
      await setLargeScreen(tester);
      await tester.pumpWidget(buildRegisterForm());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Nome Completo'),
        'Jo',
      );
      await tester.tap(find.text('Cadastrar'));
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();

      expect(find.text('Nome muito curto'), findsOneWidget);
    });

    testWidgets('mostra erro de formato de e-mail inválido', (tester) async {
      await setLargeScreen(tester);
      await tester.pumpWidget(buildRegisterForm());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'E-mail'),
        'invalido',
      );
      // Drena timer do debounce para evitar pending timer
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.tap(find.text('Cadastrar'));
      // submit() chama validateAsync() para o email (1200ms)
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();

      expect(find.text('E-mail inválido'), findsOneWidget);
    });
  });

  group('RegisterForm — validação de senha (customPassword)', () {
    testWidgets('exibe checklist de regras ao digitar na senha', (
      tester,
    ) async {
      await setLargeScreen(tester);
      await tester.pumpWidget(buildRegisterForm());
      await tester.pumpAndSettle();

      // Seta diretamente no Signal Field (índice 2 = campo Senha)
      final passwordField = tester
          .widget<SignalTextField>(find.byType(SignalTextField).at(2))
          .field;
      passwordField.value = 'a';
      await tester.pumpAndSettle();

      expect(find.text('A senha deve conter:'), findsOneWidget);
    });

    testWidgets('todas as regras ficam verdes com senha forte', (tester) async {
      await setLargeScreen(tester);
      await tester.pumpWidget(buildRegisterForm());
      await tester.pumpAndSettle();

      final passwordField = tester
          .widget<SignalTextField>(find.byType(SignalTextField).at(2))
          .field;
      passwordField.value = 'Senha@123';
      await tester.pumpAndSettle();

      // 5 regras: minLength, lowercase, uppercase, number, specialChar
      expect(find.byIcon(Icons.check_circle), findsNWidgets(5));
      expect(find.byIcon(Icons.cancel), findsNothing);
    });

    testWidgets('ícones de cancel aparecem com senha fraca', (tester) async {
      await setLargeScreen(tester);
      await tester.pumpWidget(buildRegisterForm());
      await tester.pumpAndSettle();

      final passwordField = tester
          .widget<SignalTextField>(find.byType(SignalTextField).at(2))
          .field;
      passwordField.value = 'abc';
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cancel), findsWidgets);
    });
  });

  group('RegisterForm — validação de confirmação de senha', () {
    testWidgets('mostra erro quando senhas não coincidem', (tester) async {
      await setLargeScreen(tester);
      await tester.pumpWidget(buildRegisterForm());
      await tester.pumpAndSettle();

      // Índice 2 = Senha, índice 3 = Confirmar Senha (dentro dos SignalTextFields)
      final signalFields = find.byType(SignalTextField);
      tester.widget<SignalTextField>(signalFields.at(2)).field.value =
          'Senha@123';
      tester.widget<SignalTextField>(signalFields.at(3)).field.value =
          'Diferente@1';
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cadastrar'));
      // submit() chama validateAsync() no email (1200ms)
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();

      expect(find.text('As senhas não coincidem'), findsOneWidget);
    });

    testWidgets('não mostra erro quando senhas coincidem', (tester) async {
      await setLargeScreen(tester);
      await tester.pumpWidget(buildRegisterForm());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Nome Completo'),
        'João Silva',
      );
      await enterEmailAndDrain(tester, 'joao@example.com');

      final signalFields = find.byType(SignalTextField);
      tester.widget<SignalTextField>(signalFields.at(2)).field.value =
          'Senha@123';
      tester.widget<SignalTextField>(signalFields.at(3)).field.value =
          'Senha@123';
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aceito os termos e condições'));
      await tester.tap(find.text('Cadastrar'));
      // submit() re-executa o async email validator (1200ms)
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();

      expect(find.text('As senhas não coincidem'), findsNothing);
    });
  });

  group('RegisterForm — termos e condições', () {
    testWidgets('mostra erro ao submeter sem aceitar termos', (tester) async {
      await setLargeScreen(tester);
      await tester.pumpWidget(buildRegisterForm());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Nome Completo'),
        'João Silva',
      );
      await enterEmailAndDrain(tester, 'joao@example.com');

      final signalFields = find.byType(SignalTextField);
      tester.widget<SignalTextField>(signalFields.at(2)).field.value =
          'Senha@123';
      tester.widget<SignalTextField>(signalFields.at(3)).field.value =
          'Senha@123';
      await tester.pumpAndSettle();

      // NÃO aceita os termos
      await tester.tap(find.text('Cadastrar'));
      // submit() re-executa o async email validator (1200ms)
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();

      expect(
        find.text('Você precisa aceitar os termos e condições'),
        findsOneWidget,
      );
    });

    testWidgets('aceitar os termos remove o erro', (tester) async {
      await setLargeScreen(tester);
      await tester.pumpWidget(buildRegisterForm());
      await tester.pumpAndSettle();

      // Submete sem aceitar — gera erro
      // submit() sem email não tem async (email null não passa no .email() sync)
      await tester.tap(find.text('Cadastrar'));
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();

      expect(
        find.text('Você precisa aceitar os termos e condições'),
        findsOneWidget,
      );

      await tester.tap(find.text('Aceito os termos e condições'));
      await tester.pumpAndSettle();

      expect(
        find.text('Você precisa aceitar os termos e condições'),
        findsNothing,
      );
    });
  });

  group('RegisterForm — validação assíncrona de email único', () {
    testWidgets('"admin@admin.com" falha na validação assíncrona', (
      tester,
    ) async {
      await setLargeScreen(tester);
      await tester.pumpWidget(buildRegisterForm());
      await tester.pumpAndSettle();

      await enterEmailAndDrain(tester, 'admin@admin.com');

      // Toca no campo para marcar como touched e mostrar o erro
      await tester.tap(find.widgetWithText(TextField, 'Nome Completo'));
      await tester.pumpAndSettle();

      expect(find.text('Email inválido'), findsOneWidget);
    });

    testWidgets('email livre passa na validação assíncrona', (tester) async {
      await setLargeScreen(tester);
      await tester.pumpWidget(buildRegisterForm());
      await tester.pumpAndSettle();

      await enterEmailAndDrain(tester, 'joao@example.com');

      expect(find.text('Email inválido'), findsNothing);
    });
  });

  group('RegisterForm — toggle de visibilidade das senhas', () {
    testWidgets('toggle funciona no campo Senha', (tester) async {
      await setLargeScreen(tester);
      await tester.pumpWidget(buildRegisterForm());
      await tester.pumpAndSettle();

      // Dois campos com toggle: Senha e Confirmar Senha
      expect(find.byIcon(Icons.visibility_off_outlined), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.visibility_off_outlined).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });

  group('RegisterForm — fluxo completo de cadastro', () {
    testWidgets('submissão com dados válidos exibe SnackBar de sucesso', (
      tester,
    ) async {
      await setLargeScreen(tester);
      await tester.pumpWidget(buildRegisterForm());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Nome Completo'),
        'João Silva',
      );
      await enterEmailAndDrain(tester, 'joao@example.com');

      final signalFields = find.byType(SignalTextField);
      tester.widget<SignalTextField>(signalFields.at(2)).field.value =
          'Senha@123';
      tester.widget<SignalTextField>(signalFields.at(3)).field.value =
          'Senha@123';
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aceito os termos e condições'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cadastrar'));
      // submit() re-executa o async email validator internamente (1200ms)
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Conta criada com sucesso!'), findsOneWidget);
    });
  });

  group('RegisterForm — integração com SimpleFormPage', () {
    testWidgets('navegar para aba Cadastrar exibe o RegisterForm', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SimpleFormPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cadastrar').first);
      await tester.pumpAndSettle();

      expect(find.byType(RegisterForm), findsOneWidget);
      expect(find.text('Criar Nova Conta'), findsOneWidget);
    });
  });
}
