import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SignalDropdown', () {
    final items = [
      const DropdownMenuItem<String>(value: 'br', child: Text('Brasil')),
      const DropdownMenuItem<String>(value: 'us', child: Text('Estados Unidos')),
      const DropdownMenuItem<String>(value: 'pt', child: Text('Portugal')),
    ];

    testWidgets('renders a DropdownButtonFormField', (tester) async {
      final field = Field<String>('country');
      await tester.pumpWidget(_wrap(SignalDropdown<String>(
        field: field,
        items: items,
      )));

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('hint is shown when no value selected', (tester) async {
      final field = Field<String>('country');
      await tester.pumpWidget(_wrap(SignalDropdown<String>(
        field: field,
        items: items,
        hint: const Text('Selecione...'),
      )));

      expect(find.text('Selecione...'), findsOneWidget);
    });

    testWidgets('decoration label is rendered', (tester) async {
      final field = Field<String>('country');
      await tester.pumpWidget(_wrap(SignalDropdown<String>(
        field: field,
        items: items,
        decoration: const InputDecoration(labelText: 'País'),
      )));

      expect(find.text('País'), findsOneWidget);
    });

    testWidgets('error is hidden before touch', (tester) async {
      final field =
          Field<String>('country').required(message: 'Required country');
      await tester.pumpWidget(_wrap(SignalDropdown<String>(
        field: field,
        items: items,
        decoration: const InputDecoration(),
      )));

      expect(find.text('Required country'), findsNothing);
    });

    testWidgets('error appears after field is touched with no value',
        (tester) async {
      final field =
          Field<String>('country').required(message: 'Required country');
      await tester.pumpWidget(_wrap(SignalDropdown<String>(
        field: field,
        items: items,
        decoration: const InputDecoration(),
      )));

      field.validate();


      field.touch();
      await tester.pumpAndSettle();

      expect(find.text('Required country'), findsOneWidget);
    });

    testWidgets('enabled = false prevents selection (onChanged is null)',
        (tester) async {
      final field = Field<String>('country');
      await tester.pumpWidget(_wrap(SignalDropdown<String>(
        field: field,
        items: items,
        enabled: false,
      )));

      final ddff = tester.widget<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>));
      expect(ddff.onChanged, isNull);
    });

    testWidgets('onChanged callback fires after selection', (tester) async {
      final field = Field<String>('country');
      String? received;
      await tester.pumpWidget(_wrap(SignalDropdown<String>(
        field: field,
        items: items,
        onChanged: (v) => received = v,
      )));

      // Open the dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      // Pick an item
      await tester.tap(find.text('Portugal').last);
      await tester.pumpAndSettle();

      expect(received, 'pt');
    });

    testWidgets('field value is updated on selection', (tester) async {
      final field = Field<String>('country');
      await tester.pumpWidget(_wrap(SignalDropdown<String>(
        field: field,
        items: items,
      )));

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brasil').last);
      await tester.pumpAndSettle();

      expect(field.value, 'br');
    });

    testWidgets('field is touched on selection', (tester) async {
      final field = Field<String>('country');
      await tester.pumpWidget(_wrap(SignalDropdown<String>(
        field: field,
        items: items,
      )));

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Estados Unidos').last);
      await tester.pumpAndSettle();

      expect(field.isTouched, true);
    });
  });
}
