import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SignalSlider', () {
    testWidgets('renders a Slider', (tester) async {
      final field = Field<double>('volume', 50);
      await tester.pumpWidget(_wrap(SignalSlider(
        field: field,
        min: 0,
        max: 100,
      )));

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('slider value reflects field initial value', (tester) async {
      final field = Field<double>('volume', 70);
      await tester.pumpWidget(_wrap(SignalSlider(
        field: field,
        min: 0,
        max: 100,
      )));

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 70);
    });

    testWidgets('slider defaults to min when field value is null',
        (tester) async {
      final field = Field<double>('volume');
      await tester.pumpWidget(_wrap(SignalSlider(
        field: field,
        min: 20,
        max: 100,
      )));

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 20);
    });

    testWidgets('enabled = false disables the Slider', (tester) async {
      final field = Field<double>('volume', 50);
      await tester.pumpWidget(_wrap(SignalSlider(
        field: field,
        min: 0,
        max: 100,
        enabled: false,
      )));

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.onChanged, isNull);
    });

    testWidgets('decoration label is rendered', (tester) async {
      final field = Field<double>('volume', 50);
      await tester.pumpWidget(_wrap(SignalSlider(
        field: field,
        min: 0,
        max: 100,
        decoration: const InputDecoration(labelText: 'Volume'),
      )));

      expect(find.text('Volume'), findsOneWidget);
    });

    testWidgets('error is hidden before touch', (tester) async {
      final field = Field<double>('score');
      await tester.pumpWidget(_wrap(SignalSlider(
        field: field,
        min: 0,
        max: 10,
        decoration: const InputDecoration(),
      )));

      expect(find.text('Too low'), findsNothing);
    });

    testWidgets('field is touched after drag ends', (tester) async {
      final field = Field<double>('volume', 50);
      await tester.pumpWidget(_wrap(SizedBox(
        width: 400,
        child: SignalSlider(
          field: field,
          min: 0,
          max: 100,
        ),
      )));

      // Simulate drag on the Slider
      final sliderFinder = find.byType(Slider);
      await tester.drag(sliderFinder, const Offset(20, 0));
      await tester.pump();

      expect(field.isTouched, true);
    });

    testWidgets('onChangeEnd callback fires after drag', (tester) async {
      final field = Field<double>('volume', 50);
      double? endValue;
      await tester.pumpWidget(_wrap(SizedBox(
        width: 400,
        child: SignalSlider(
          field: field,
          min: 0,
          max: 100,
          onChangeEnd: (v) => endValue = v,
        ),
      )));

      await tester.drag(find.byType(Slider), const Offset(20, 0));
      await tester.pump();

      expect(endValue, isNotNull);
    });
  });
}
