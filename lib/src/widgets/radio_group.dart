import 'package:flutter/material.dart';
import '../core.dart';
import 'form_field.dart';

/// A reactive group of radio buttons for single-value selection, bound to a
/// [Field<T>].
///
/// Each [SignalFieldOption] in [options] renders as a [Radio] + label pair
/// wrapped in a Material [RadioGroup]. Selecting an option writes its value
/// to [field.value] and calls [Field.touch]. The [Field.error] is surfaced
/// inside the [InputDecorator] once the field is touched.
///
/// [T] is the type of the selected value.
/// [field] is the backing [Field<T>].
/// [options] is the ordered list of [SignalFieldOption] items to display.
/// [decoration] wraps the group with a Material [InputDecoration]; the error
/// text is driven by [Field.error] once touched.
/// [orientation] — [Axis.vertical] stacks options top-to-bottom (default);
/// [Axis.horizontal] wraps them in a [Wrap] side-by-side.
/// [activeColor] overrides the selected radio button fill color.
/// [focusColor] overrides the focus ring color.
/// [hoverColor] overrides the hover ring color.
/// [splashRadius] overrides the ink splash radius on tap.
/// [visualDensity] adjusts the spacing around each radio button.
/// [enabled] — when `false`, all radio buttons are disabled.
/// [focusNode] overrides the internally managed [FocusNode].
///
/// Example:
/// ```dart
/// final gender = Field<String>('gender')
///   ..required(message: 'Selecione uma opção');
///
/// SignalRadioGroup<String>(
///   field: gender,
///   decoration: const InputDecoration(labelText: 'Gênero'),
///   options: const [
///     SignalFieldOption(value: 'M', label: 'Masculino'),
///     SignalFieldOption(value: 'F', label: 'Feminino'),
///     SignalFieldOption(value: 'O', label: 'Outro'),
///   ],
/// )
/// ```
class SignalRadioGroup<T> extends StatefulWidget {
  final Field<T> field;
  final List<SignalFieldOption<T>> options;
  final InputDecoration decoration;
  final Axis orientation;
  final Color? activeColor;
  final Color? focusColor;
  final Color? hoverColor;
  final double? splashRadius;
  final VisualDensity? visualDensity;
  final bool enabled;
  final FocusNode? focusNode;

  const SignalRadioGroup({
    super.key,
    required this.field,
    required this.options,
    this.decoration = const InputDecoration(),
    this.orientation = Axis.vertical,
    this.activeColor,
    this.focusColor,
    this.hoverColor,
    this.splashRadius,
    this.visualDensity,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<SignalRadioGroup<T>> createState() => _SignalRadioGroupState<T>();
}

class _SignalRadioGroupState<T> extends State<SignalRadioGroup<T>> {
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
  void didUpdateWidget(SignalRadioGroup<T> oldWidget) {
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
        final List<Widget> radioWidgets = widget.options.map((option) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<T>(
                focusNode: _effectiveFocusNode,
                value: option.value,
                enabled: widget.enabled,
                activeColor: widget.activeColor,
                focusColor: widget.focusColor,
                hoverColor: widget.hoverColor,
                splashRadius: widget.splashRadius,
                visualDensity: widget.visualDensity,
              ),
              GestureDetector(
                onTap: widget.enabled
                    ? () {
                        widget.field.value = option.value;
                        widget.field.touch();
                      }
                    : null,
                child: option.widget,
              ),
            ],
          );
        }).toList();

        return RadioGroup<T>(
          groupValue: widget.field.value,
          onChanged: widget.enabled
              ? (val) {
                  widget.field.value = val;
                  widget.field.touch();
                }
              : (val) {},
          child: InputDecorator(
            decoration: widget.decoration.copyWith(
              errorText: widget.field.isTouched ? widget.field.error : null,
              enabled: widget.enabled,
            ),
            child: widget.orientation == Axis.horizontal
                ? Wrap(spacing: 8.0, children: radioWidgets)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: radioWidgets,
                  ),
          ),
        );
      },
    );
  }
}
