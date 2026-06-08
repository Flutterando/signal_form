import 'package:flutter/material.dart';
import '../core.dart';
import 'form_field.dart';

/// A reactive group of checkboxes for multiple-selection, bound to a
/// [Field<List<T>>].
///
/// Each [SignalFieldOption] in [options] renders as a [Checkbox] + label pair.
/// Selecting or deselecting an option adds or removes its value from the list
/// stored in [Field.value]. [Field.touch] is called on every interaction so
/// that [Field.error] surfaces immediately inside the [InputDecorator].
///
/// [T] is the element type of the selected list.
/// [field] is the backing [Field<List<T>>].
/// [options] is the list of selectable [SignalFieldOption] items.
/// [decoration] wraps the entire group with a Material [InputDecoration];
/// [InputDecoration.errorText] is driven by [Field.error] once touched.
/// [orientation] — [Axis.vertical] stacks options top-to-bottom (default);
/// [Axis.horizontal] wraps them in a [Wrap] side-by-side.
/// [activeColor] overrides the checkbox fill color when checked.
/// [checkColor] overrides the color of the check mark icon.
/// [visualDensity] adjusts the spacing around each checkbox.
/// [enabled] — when `false`, all checkboxes are disabled.
/// [focusNode] overrides the internally managed [FocusNode].
///
/// Example:
/// ```dart
/// final skills = Field<List<String>>('skills')
///   ..minItems(1, message: 'Selecione ao menos uma habilidade');
///
/// SignalCheckboxGroup<String>(
///   field: skills,
///   decoration: const InputDecoration(labelText: 'Habilidades'),
///   options: const [
///     SignalFieldOption(value: 'dart', label: 'Dart'),
///     SignalFieldOption(value: 'flutter', label: 'Flutter'),
///     SignalFieldOption(value: 'firebase', label: 'Firebase'),
///   ],
/// )
/// ```
class SignalCheckboxGroup<T> extends StatefulWidget {
  final Field<List<T>> field;
  final List<SignalFieldOption<T>> options;
  final InputDecoration decoration;
  final Axis orientation;
  final Color? activeColor;
  final Color? checkColor;
  final VisualDensity? visualDensity;
  final bool enabled;
  final FocusNode? focusNode;

  const SignalCheckboxGroup({
    super.key,
    required this.field,
    required this.options,
    this.decoration = const InputDecoration(),
    this.orientation = Axis.vertical,
    this.activeColor,
    this.checkColor,
    this.visualDensity,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<SignalCheckboxGroup<T>> createState() => _SignalCheckboxGroupState<T>();
}

class _SignalCheckboxGroupState<T> extends State<SignalCheckboxGroup<T>> {
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
  void didUpdateWidget(SignalCheckboxGroup<T> oldWidget) {
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
        final List<T> currentValue = widget.field.value ?? [];

        final List<Widget> checkboxWidgets = widget.options.map((option) {
          final isSelected = currentValue.contains(option.value);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                focusNode: _effectiveFocusNode,
                value: isSelected,
                onChanged: widget.enabled
                    ? (val) {
                        final List<T> newValue = List.from(currentValue);
                        if (val == true) {
                          newValue.add(option.value);
                        } else {
                          newValue.remove(option.value);
                        }
                        widget.field.value = newValue;
                        widget.field.touch();
                      }
                    : null,
                activeColor: widget.activeColor,
                checkColor: widget.checkColor,
                visualDensity: widget.visualDensity,
              ),
              GestureDetector(
                onTap: widget.enabled
                    ? () {
                        final List<T> newValue = List.from(currentValue);
                        if (!isSelected) {
                          newValue.add(option.value);
                        } else {
                          newValue.remove(option.value);
                        }
                        widget.field.value = newValue;
                        widget.field.touch();
                      }
                    : null,
                child: option.widget,
              ),
            ],
          );
        }).toList();

        return InputDecorator(
          decoration: widget.decoration.copyWith(
            errorText: widget.field.isTouched ? widget.field.error : null,
            enabled: widget.enabled,
          ),
          child: widget.orientation == Axis.horizontal
              ? Wrap(spacing: 8.0, children: checkboxWidgets)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: checkboxWidgets,
                ),
        );
      },
    );
  }
}
