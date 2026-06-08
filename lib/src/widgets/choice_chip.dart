import 'package:flutter/material.dart';
import '../core.dart';
import 'form_field.dart';

/// A reactive group of [ChoiceChip] widgets for single-value selection, bound
/// to a [Field<T>].
///
/// Each [SignalFieldOption] in [options] renders as a [ChoiceChip]. Selecting
/// a chip writes its value to [field.value] and calls [Field.touch].
/// Re-selecting an already-selected chip sets [field.value] to `null` (deselect).
/// [Field.error] surfaces inside the [InputDecorator] once the field is touched.
///
/// [T] is the type of the selected value.
/// [field] is the backing [Field<T>].
/// [options] is the list of [SignalFieldOption] items to display as chips.
/// [decoration] wraps the chip group with a Material [InputDecoration]; the
/// error text is driven by [Field.error] once touched.
/// [alignment] controls the main-axis alignment of chips within the [Wrap].
/// [runAlignment] controls the cross-axis alignment of chip rows.
/// [spacing] is the horizontal gap between chips (defaults to `8.0`).
/// [runSpacing] is the vertical gap between chip rows (defaults to `0.0`).
/// [enabled] — when `false`, chips cannot be tapped.
/// [focusNode] overrides the internally managed [FocusNode].
///
/// Example:
/// ```dart
/// final plan = Field<String>('plan')
///   ..required(message: 'Selecione um plano');
///
/// SignalChoiceChip<String>(
///   field: plan,
///   decoration: const InputDecoration(labelText: 'Plano'),
///   options: const [
///     SignalFieldOption(value: 'basic', label: 'Básico'),
///     SignalFieldOption(value: 'pro', label: 'Pro'),
///     SignalFieldOption(value: 'enterprise', label: 'Enterprise'),
///   ],
/// )
/// ```
class SignalChoiceChip<T> extends StatefulWidget {
  final Field<T> field;
  final List<SignalFieldOption<T>> options;
  final InputDecoration decoration;
  final WrapAlignment alignment;
  final WrapAlignment runAlignment;
  final double spacing;
  final double runSpacing;
  final bool enabled;
  final FocusNode? focusNode;

  const SignalChoiceChip({
    super.key,
    required this.field,
    required this.options,
    this.decoration = const InputDecoration(),
    this.alignment = WrapAlignment.start,
    this.runAlignment = WrapAlignment.start,
    this.spacing = 8.0,
    this.runSpacing = 0.0,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<SignalChoiceChip<T>> createState() => _SignalChoiceChipState<T>();
}

class _SignalChoiceChipState<T> extends State<SignalChoiceChip<T>> {
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
  void didUpdateWidget(SignalChoiceChip<T> oldWidget) {
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
          child: Wrap(
            alignment: widget.alignment,
            runAlignment: widget.runAlignment,
            spacing: widget.spacing,
            runSpacing: widget.runSpacing,
            children: widget.options.map((option) {
              return ChoiceChip(
                focusNode: _effectiveFocusNode,
                label: option.widget,
                selected: widget.field.value == option.value,
                onSelected: widget.enabled
                    ? (selected) {
                        if (selected) {
                          widget.field.value = option.value;
                        } else {
                          widget.field.value = null;
                        }
                        widget.field.touch();
                      }
                    : null,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
