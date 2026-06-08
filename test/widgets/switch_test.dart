import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SignalSwitch', () {
    testWidgets('renders a SwitchListTile', (tester) async {
      final field = Field<bool>('notifications', false);
      await tester.pumpWidget(_wrap(SignalSwitch(
        field: field,
        title: const Text('Notifications'),
      )));

      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('initial value false renders switch off', (tester) async {
      final field = Field<bool>('notifications', false);
      await tester.pumpWidget(_wrap(SignalSwitch(
        field: field,
        title: const Text('Notifications'),
      )));

      final tile =
          tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(tile.value, false);
    });

    testWidgets('initial value true renders switch on', (tester) async {
      final field = Field<bool>('notifications', true);
      await tester.pumpWidget(_wrap(SignalSwitch(
        field: field,
        title: const Text('Notifications'),
      )));

      final tile =
          tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(tile.value, true);
    });

    testWidgets('tapping toggles field value from false to true',
        (tester) async {
      final field = Field<bool>('notifications', false);
      await tester.pumpWidget(_wrap(SignalSwitch(
        field: field,
        title: const Text('Notifications'),
      )));

      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      expect(field.value, true);
    });

    testWidgets('tapping twice returns to false', (tester) async {
      final field = Field<bool>('notifications', false);
      await tester.pumpWidget(_wrap(SignalSwitch(
        field: field,
        title: const Text('Notifications'),
      )));

      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      expect(field.value, false);
    });

    testWidgets('field is touched after toggle', (tester) async {
      final field = Field<bool>('notifications', false);
      await tester.pumpWidget(_wrap(SignalSwitch(
        field: field,
        title: const Text('Notifications'),
      )));

      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      expect(field.isTouched, true);
    });

    testWidgets('title is rendered', (tester) async {
      final field = Field<bool>('notifications', false);
      await tester.pumpWidget(_wrap(SignalSwitch(
        field: field,
        title: const Text('My Switch'),
      )));

      expect(find.text('My Switch'), findsOneWidget);
    });

    testWidgets('subtitle is rendered when no error', (tester) async {
      final field = Field<bool>('notifications', false);
      await tester.pumpWidget(_wrap(SignalSwitch(
        field: field,
        title: const Text('Notifications'),
        subtitle: const Text('Subtitle text'),
      )));

      expect(find.text('Subtitle text'), findsOneWidget);
    });

    testWidgets('enabled = false disables the tile', (tester) async {
      final field = Field<bool>('notifications', false);
      await tester.pumpWidget(_wrap(SignalSwitch(
        field: field,
        title: const Text('Notifications'),
        enabled: false,
      )));

      final tile =
          tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(tile.onChanged, isNull);
    });

    testWidgets('error replaces subtitle when touched with a validation error',
        (tester) async {
      // A Field<bool> that must be true
      final field =
          Field<bool>('agree', false).mustBeTrue(message: 'Must be on');
      await tester.pumpWidget(_wrap(SignalSwitch(
        field: field,
        title: const Text('Accept'),
        subtitle: const Text('Original subtitle'),
      )));

      // Touch by toggling on then off
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      expect(find.text('Must be on'), findsOneWidget);
      expect(find.text('Original subtitle'), findsNothing);
    });
  });
}
