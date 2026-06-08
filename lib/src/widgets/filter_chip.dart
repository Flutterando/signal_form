import 'package:flutter/material.dart';
import '../core.dart';
import 'form_field.dart';

/// A reactive group of [FilterChip] widgets for multiple-selection, bound to a
/// [Field<List<T>>].
///
/// Each [SignalFieldOption] in [options] renders as a toggleable [FilterChip].
/// Selecting a chip adds its value to the list stored in [Field.value];
/// deselecting removes it. [Field.touch] is called on every tap so that
/// [Field.error] surfaces in the [InputDecorator] immediately.
///
/// [T] is the element type of the selected list.
/// [field] is the backing [Field<List<T>>].
/// [options] is the list of [SignalFieldOption] items to display as chips.
/// [decoration] wraps the chip group with a Material [InputDecoration]; the
/// error text is driven by [Field.error] once touched.
/// [alignment] controls the main-axis alignment of chips within the [Wrap].
/// [runAlignment] controls the cross-axis alignment of chip rows.
/// [spacing] is the horizontal gap between chips (defaults to `8.0`).
/// [runSpacing] is the vertical gap between chip rows (defaults to `0.0`).
/// [enabled] — when `false`, chips cannot be toggled.
/// [focusNode] overrides the internally managed [FocusNode].
///
/// Example:
/// ```dart
/// final interests = Field<List<String>>('interests')
///   ..minItems(1, message: 'Selecione ao menos um interesse');
///
/// SignalFilterChip<String>(
///   field: interests,
///   decoration: const InputDecoration(labelText: 'Interesses'),
///   options: const [
///     SignalFieldOption(value: 'sports', label: 'Esportes'),
///     SignalFieldOption(value: 'music', label: 'Música'),
///     SignalFieldOption(value: 'tech', label: 'Tecnologia'),
///   ],
/// )
/// ```
class SignalFilterChip<T> extends StatefulWidget {
  final Field<List<T>> field;
  final List<SignalFieldOption<T>> options;
  final InputDecoration decoration;
  final WrapAlignment alignment;
  final WrapAlignment runAlignment;
  final double spacing;
  final double runSpacing;
  final bool enabled;
  final FocusNode? focusNode;

  const SignalFilterChip({
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
  State<SignalFilterChip<T>> createState() => _SignalFilterChipState<T>();
}

class _SignalFilterChipState<T> extends State<SignalFilterChip<T>> {
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
  void didUpdateWidget(SignalFilterChip<T> oldWidget) {
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
              final isSelected = currentValue.contains(option.value);
              return FilterChip(
                label: option.widget,
                selected: isSelected,
                focusNode: _effectiveFocusNode,
                onSelected: widget.enabled
                    ? (selected) {
                        final List<T> newValue = List.from(currentValue);
                        if (selected) {
                          newValue.add(option.value);
                        } else {
                          newValue.remove(option.value);
                        }
                        widget.field.value = newValue;
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
