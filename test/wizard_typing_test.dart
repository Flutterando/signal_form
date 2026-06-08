import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

Future<void> typeChar(WidgetTester tester, Finder finder, String char) async {
  final textField = tester.widget<TextField>(finder);
  final controller = textField.controller!;
  final text = controller.text;
  final selection = controller.selection;

  String newText;
  int newOffset;
  if (selection.isValid) {
    newText = text.replaceRange(selection.start, selection.end, char);
    newOffset = selection.start + char.length;
  } else {
    newText = text + char;
    newOffset = newText.length;
  }

  controller.value = TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: newOffset),
  );
  // Re-run widgets to trigger the TextField's onChanged event
  textField.onChanged?.call(newText);
  await tester.pump();
}

void main() {
  testWidgets('Typing in masked field keeps cursor at the end', (
    WidgetTester tester,
  ) async {
    final form = formCtrl(
      () => (
        phone: Field<String>(
          'phone',
        ).required(message: 'Required').mask('(##) #####-####'),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SignalTextField(
            field: form.fields.phone,
            keyboardType: TextInputType.phone,
          ),
        ),
      ),
    );

    final finder = find.byType(TextField);
    expect(finder, findsOneWidget);

    final textField = tester.widget<TextField>(finder);
    final controller = textField.controller!;

    // Focus the text field
    await tester.tap(finder);
    await tester.pump();

    // Type '9'
    await typeChar(tester, finder, '9');
    expect(controller.text, equals('(9'));
    expect(controller.selection.baseOffset, equals(2));

    // Type '8'
    await typeChar(tester, finder, '8');
    expect(controller.text, equals('(98'));
    expect(controller.selection.baseOffset, equals(3));

    // Type '7'
    await typeChar(tester, finder, '7');
    expect(controller.text, equals('(98) 7'));
    expect(controller.selection.baseOffset, equals(6));
  });

  testWidgets('Typing past the mask limit rejects extra characters', (
    WidgetTester tester,
  ) async {
    final form = formCtrl(
      () => (
        phone: Field<String>(
          'phone',
        ).required(message: 'Required').mask('(##) #####-####'),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SignalTextField(
            field: form.fields.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [LengthLimitingTextInputFormatter(15)],
          ),
        ),
      ),
    );

    final finder = find.byType(TextField);
    final textField = tester.widget<TextField>(finder);
    final controller = textField.controller!;

    await tester.tap(finder);
    await tester.pump();

    // Type 20 digits
    for (int i = 0; i < 20; i++) {
      await typeChar(tester, finder, '9');
    }

    // The text should be exactly 15 characters long
    expect(controller.text.length, equals(15));
    expect(controller.text, equals('(99) 99999-9999'));
  });

  testWidgets(
    'SignalCheckbox shows error message instead of subtitle when touched and invalid',
    (WidgetTester tester) async {
      final form = formCtrl(
        () => (
          acceptTerms: Field<bool>(
            'acceptTerms',
            false,
          ).mustBeTrue(message: 'You must accept terms'),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SignalCheckbox(
              field: form.fields.acceptTerms,
              title: const Text('Title'),
              subtitle: const Text('Custom Subtitle'),
            ),
          ),
        ),
      );

      // Initial state: should show the custom subtitle
      expect(find.text('Custom Subtitle'), findsOneWidget);
      expect(find.text('You must accept terms'), findsNothing);

      // Touch the field (trigger validation so it is touched and has error)
      await form.trigger();
      await tester.pump();

      // Now it should show the error message and NOT the custom subtitle
      expect(find.text('Custom Subtitle'), findsNothing);
      expect(find.text('You must accept terms'), findsOneWidget);
    },
  );

  testWidgets(
    'SignalSwitch shows error message instead of subtitle when touched and invalid',
    (WidgetTester tester) async {
      final form = formCtrl(
        () => (
          newsletter: Field<bool>(
            'newsletter',
            false,
          ).mustBeTrue(message: 'Required to opt-in'),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SignalSwitch(
              field: form.fields.newsletter,
              title: const Text('Title'),
              subtitle: const Text('Custom Subtitle'),
            ),
          ),
        ),
      );

      // Initial state: should show custom subtitle
      expect(find.text('Custom Subtitle'), findsOneWidget);
      expect(find.text('Required to opt-in'), findsNothing);

      // Touch and validate
      await form.trigger();
      await tester.pump();

      // Now it should show the error message instead
      expect(find.text('Custom Subtitle'), findsNothing);
      expect(find.text('Required to opt-in'), findsOneWidget);
    },
  );
}
