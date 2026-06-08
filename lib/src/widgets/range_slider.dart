import 'package:flutter/material.dart';
import '../core.dart';

/// A reactive [RangeSlider] bound to a [Field<RangeValues>].
///
/// Writes a [RangeValues] to [field.value] on each position change and calls
/// [Field.touch] when the drag ends, so that [Field.error] surfaces in the
/// [InputDecorator] only after the user has finished interacting.
///
/// When [field.value] is `null`, both thumbs default to the range extremes:
/// start = [min], end = [max].
///
/// [field] is the backing [Field<RangeValues>].
/// [min] is the minimum value of the slider range.
/// [max] is the maximum value of the slider range.
/// [divisions] is the number of discrete steps between [min] and [max].
/// When `null`, the slider is continuous.
/// [decoration] wraps the slider with a Material [InputDecoration].
/// [activeColor] overrides the filled track color between the two thumbs.
/// [inactiveColor] overrides the unfilled track color outside the thumbs.
/// [enabled] — when `false`, the thumbs cannot be moved.
/// [focusNode] overrides the internally managed [FocusNode].
///
/// Example:
/// ```dart
/// final priceRange = Field<RangeValues>('price', const RangeValues(100, 500));
///
/// SignalRangeSlider(
///   field: priceRange,
///   min: 0,
///   max: 1000,
///   divisions: 20,
///   decoration: const InputDecoration(labelText: 'Faixa de preço'),
/// )
/// ```
class SignalRangeSlider extends StatefulWidget {
  final Field<RangeValues> field;
  final double min;
  final double max;
  final int? divisions;
  final InputDecoration decoration;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool enabled;
  final FocusNode? focusNode;

  const SignalRangeSlider({
    super.key,
    required this.field,
    required this.min,
    required this.max,
    this.divisions,
    this.decoration = const InputDecoration(),
    this.activeColor,
    this.inactiveColor,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<SignalRangeSlider> createState() => _SignalRangeSliderState();
}

class _SignalRangeSliderState extends State<SignalRangeSlider> {
  late final FocusNode _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
    widget.field.focusNode = _effectiveFocusNode;
  }

  @override
  void didUpdateWidget(SignalRangeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) _internalFocusNode.dispose();
      if (widget.focusNode == null) {
        _internalFocusNode = FocusNode();
      }
      widget.field.focusNode = _effectiveFocusNode;
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _internalFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.field,
      builder: (context, _) {
        return InputDecorator(
          decoration: widget.decoration.copyWith(
            errorText: widget.field.isTouched ? widget.field.error : null,
            enabled: widget.enabled,
          ),
          child: RangeSlider(
            values: widget.field.value ?? RangeValues(widget.min, widget.max),
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            activeColor: widget.activeColor,
            inactiveColor: widget.inactiveColor,
            onChanged: widget.enabled
                ? (val) {
                    widget.field.value = val;
                  }
                : null,
            onChangeEnd: (val) {
              widget.field.touch();
            },
          ),
        );
      },
    );
  }
}
