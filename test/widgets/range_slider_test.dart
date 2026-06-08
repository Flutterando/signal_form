import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SignalRangeSlider', () {
    testWidgets('renders a RangeSlider', (tester) async {
      final field = Field<RangeValues>('price', const RangeValues(100, 500));
      await tester.pumpWidget(_wrap(SignalRangeSlider(
        field: field,
        min: 0,
        max: 1000,
      )));

      expect(find.byType(RangeSlider), findsOneWidget);
    });

    testWidgets('slider values reflect field initial value', (tester) async {
      final field = Field<RangeValues>('price', const RangeValues(200, 800));
      await tester.pumpWidget(_wrap(SignalRangeSlider(
        field: field,
        min: 0,
        max: 1000,
      )));

      final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
      expect(slider.values.start, 200);
      expect(slider.values.end, 800);
    });

    testWidgets('defaults to min/max extremes when field value is null',
        (tester) async {
      final field = Field<RangeValues>('price');
      await tester.pumpWidget(_wrap(SignalRangeSlider(
        field: field,
        min: 10,
        max: 500,
      )));

      final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
      expect(slider.values.start, 10);
      expect(slider.values.end, 500);
    });

    testWidgets('enabled = false disables the slider', (tester) async {
      final field = Field<RangeValues>('price', const RangeValues(0, 100));
      await tester.pumpWidget(_wrap(SignalRangeSlider(
        field: field,
        min: 0,
        max: 100,
        enabled: false,
      )));

      final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
      expect(slider.onChanged, isNull);
    });

    testWidgets('decoration label is rendered', (tester) async {
      final field = Field<RangeValues>('price', const RangeValues(0, 100));
      await tester.pumpWidget(_wrap(SignalRangeSlider(
        field: field,
        min: 0,
        max: 100,
        decoration: const InputDecoration(labelText: 'Faixa de preço'),
      )));

      expect(find.text('Faixa de preço'), findsOneWidget);
    });

    testWidgets('error is hidden before touch', (tester) async {
      final field = Field<RangeValues>('price');
      await tester.pumpWidget(_wrap(SignalRangeSlider(
        field: field,
        min: 0,
        max: 100,
        decoration: const InputDecoration(),
      )));

      // No error text rendered since not touched
      final decorator = tester.widget<InputDecorator>(
          find.byType(InputDecorator));
      expect(decorator.decoration.errorText, isNull);
    });

    testWidgets('field is touched after drag ends', (tester) async {
      final field = Field<RangeValues>('price', const RangeValues(0, 100));
      await tester.pumpWidget(_wrap(SizedBox(
        width: 400,
        child: SignalRangeSlider(
          field: field,
          min: 0,
          max: 100,
        ),
      )));

      await tester.drag(find.byType(RangeSlider), const Offset(20, 0));
      await tester.pump();

      expect(field.isTouched, true);
    });
  });
}
