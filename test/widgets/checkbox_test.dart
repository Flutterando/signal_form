import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SignalCheckbox', () {
    testWidgets('renders a CheckboxListTile', (tester) async {
      final field = Field<bool>('agree', false);
      await tester.pumpWidget(_wrap(SignalCheckbox(
        field: field,
        title: const Text('Accept'),
      )));

      expect(find.byType(CheckboxListTile), findsOneWidget);
    });

    testWidgets('initial value false renders unchecked', (tester) async {
      final field = Field<bool>('agree', false);
      await tester.pumpWidget(_wrap(SignalCheckbox(
        field: field,
        title: const Text('Accept'),
      )));

      final tile = tester.widget<CheckboxListTile>(
          find.byType(CheckboxListTile));
      expect(tile.value, false);
    });

    testWidgets('tapping toggles field value to true', (tester) async {
      final field = Field<bool>('agree', false);
      await tester.pumpWidget(_wrap(SignalCheckbox(
        field: field,
        title: const Text('Accept'),
      )));

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(field.value, true);
    });

    testWidgets('tapping twice toggles back to false', (tester) async {
      final field = Field<bool>('agree', false);
      await tester.pumpWidget(_wrap(SignalCheckbox(
        field: field,
        title: const Text('Accept'),
      )));

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(field.value, false);
    });

    testWidgets('touching shows validation error', (tester) async {
      final field = Field<bool>('agree', false)
          .mustBeTrue(message: 'Must accept');

      await tester.pumpWidget(_wrap(SignalCheckbox(
        field: field,
        title: const Text('Accept'),
      )));

      // Tap triggers touch immediately in SignalCheckbox
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      // Toggle back to false
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();

      expect(find.text('Must accept'), findsOneWidget);
    });

    testWidgets('error is hidden before touch', (tester) async {
      final field = Field<bool>('agree', false)
          .mustBeTrue(message: 'Must accept');

      await tester.pumpWidget(_wrap(SignalCheckbox(
        field: field,
        title: const Text('Accept'),
      )));

      expect(find.text('Must accept'), findsNothing);
    });

    testWidgets('enabled = false disables the tile', (tester) async {
      final field = Field<bool>('agree', false);
      await tester.pumpWidget(_wrap(SignalCheckbox(
        field: field,
        title: const Text('Accept'),
        enabled: false,
      )));

      final tile = tester.widget<CheckboxListTile>(
          find.byType(CheckboxListTile));
      expect(tile.enabled, false);
    });

    testWidgets('disabled tile does not update field when tapped',
        (tester) async {
      final field = Field<bool>('agree', false);
      await tester.pumpWidget(_wrap(SignalCheckbox(
        field: field,
        title: const Text('Accept'),
        enabled: false,
      )));

      await tester.tap(find.byType(CheckboxListTile), warnIfMissed: false);
      await tester.pump();
      expect(field.value, false);
    });

    testWidgets('title widget is rendered', (tester) async {
      final field = Field<bool>('agree', false);
      await tester.pumpWidget(_wrap(SignalCheckbox(
        field: field,
        title: const Text('My checkbox label'),
      )));

      expect(find.text('My checkbox label'), findsOneWidget);
    });

    testWidgets('subtitle shows when no error', (tester) async {
      final field = Field<bool>('agree', false);
      await tester.pumpWidget(_wrap(SignalCheckbox(
        field: field,
        title: const Text('Accept'),
        subtitle: const Text('Subtitle text'),
      )));

      expect(find.text('Subtitle text'), findsOneWidget);
    });
  });
}
