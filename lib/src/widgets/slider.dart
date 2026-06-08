import 'package:flutter/material.dart';
import '../core.dart';

/// A reactive [Slider] bound to a [Field<double>].
///
/// Writes the dragged value to [field.value] on each position change and calls
/// [Field.touch] when the drag ends (`onChangeEnd`), so that [Field.error]
/// surfaces in the [InputDecorator] only after the user has finished
/// interacting.
///
/// When [field.value] is `null` the thumb starts at [min].
///
/// [field] is the backing [Field<double>].
/// [min] is the minimum value of the slider range.
/// [max] is the maximum value of the slider range.
/// [divisions] is the number of discrete steps between [min] and [max].
/// When `null`, the slider is continuous.
/// [decoration] wraps the slider with a Material [InputDecoration].
/// [activeColor] overrides the filled track and thumb color.
/// [inactiveColor] overrides the unfilled track color.
/// [onChangeStart] fires with the value when the user begins dragging.
/// [onChangeEnd] fires with the final value when the user releases the thumb;
/// [Field.touch] is always called here regardless of this callback.
/// [enabled] — when `false`, the thumb cannot be moved.
/// [focusNode] overrides the internally managed [FocusNode].
///
/// Example:
/// ```dart
/// final volume = Field<double>('volume', 50);
///
/// SignalSlider(
///   field: volume,
///   min: 0,
///   max: 100,
///   divisions: 10,
///   decoration: const InputDecoration(labelText: 'Volume'),
/// )
/// ```
class SignalSlider extends StatefulWidget {
  final Field<double> field;
  final double min;
  final double max;
  final int? divisions;
  final InputDecoration decoration;
  final Color? activeColor;
  final Color? inactiveColor;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final bool enabled;
  final FocusNode? focusNode;

  const SignalSlider({
    super.key,
    required this.field,
    required this.min,
    required this.max,
    this.divisions,
    this.decoration = const InputDecoration(),
    this.activeColor,
    this.inactiveColor,
    this.onChangeStart,
    this.onChangeEnd,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<SignalSlider> createState() => _SignalSliderState();
}

class _SignalSliderState extends State<SignalSlider> {
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
  void didUpdateWidget(SignalSlider oldWidget) {
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
          child: Slider(
            focusNode: _effectiveFocusNode,
            value: widget.field.value ?? widget.min,
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
            onChangeStart: widget.onChangeStart,
            onChangeEnd: (val) {
              widget.field.touch();
              widget.onChangeEnd?.call(val);
            },
          ),
        );
      },
    );
  }
}
