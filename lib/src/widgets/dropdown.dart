import 'package:flutter/material.dart';
import '../core.dart';

/// A reactive [DropdownButtonFormField] bound to a [Field<T>].
///
/// Writes the selected item's value to [field.value] and calls [Field.touch]
/// on selection. [Field.error] appears as [InputDecoration.errorText] once the
/// field is touched.
///
/// [T] is the type of the selected dropdown value.
/// [field] is the backing [Field<T>].
/// [items] is the list of [DropdownMenuItem] entries shown in the overlay.
/// [decoration] wraps the dropdown button with a Material [InputDecoration].
/// [hint] is shown when no value is selected (placeholder).
/// [disabledHint] is shown instead of [hint] when [enabled] is `false`.
/// [onChanged] is called after [field.value] is updated on each selection.
/// [onTap] fires when the user taps the dropdown button (before the overlay opens).
/// [enabled] — when `false`, the dropdown is read-only and visually dimmed.
/// [focusNode] overrides the internally managed [FocusNode].
///
/// Example:
/// ```dart
/// final country = Field<String>('country')
///   ..required(message: 'Selecione um país');
///
/// SignalDropdown<String>(
///   field: country,
///   decoration: const InputDecoration(labelText: 'País'),
///   hint: const Text('Selecione...'),
///   items: const [
///     DropdownMenuItem(value: 'BR', child: Text('Brasil')),
///     DropdownMenuItem(value: 'US', child: Text('Estados Unidos')),
///     DropdownMenuItem(value: 'PT', child: Text('Portugal')),
///   ],
/// )
/// ```
class SignalDropdown<T> extends StatefulWidget {
  final Field<T> field;
  final List<DropdownMenuItem<T>> items;
  final InputDecoration decoration;
  final Widget? hint;
  final Widget? disabledHint;
  final ValueChanged<T?>? onChanged;
  final VoidCallback? onTap;
  final bool enabled;
  final FocusNode? focusNode;

  const SignalDropdown({
    super.key,
    required this.field,
    required this.items,
    this.decoration = const InputDecoration(),
    this.hint,
    this.disabledHint,
    this.onChanged,
    this.onTap,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<SignalDropdown<T>> createState() => _SignalDropdownState<T>();
}

class _SignalDropdownState<T> extends State<SignalDropdown<T>> {
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
  void didUpdateWidget(SignalDropdown<T> oldWidget) {
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
        return DropdownButtonFormField<T>(
          focusNode: _effectiveFocusNode,
          initialValue: widget.field.value,
          items: widget.items,
          decoration: widget.decoration.copyWith(
            errorText: widget.field.isTouched ? widget.field.error : null,
            enabled: widget.enabled,
          ),
          hint: widget.hint,
          disabledHint: widget.disabledHint,
          onChanged: widget.enabled
              ? (val) {
                  widget.field.value = val;
                  widget.field.touch();
                  widget.onChanged?.call(val);
                }
              : null,
          onTap: widget.onTap,
        );
      },
    );
  }
}
