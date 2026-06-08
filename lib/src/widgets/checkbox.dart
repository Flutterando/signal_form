import 'package:flutter/material.dart';
import '../core.dart';

/// A reactive [CheckboxListTile] bound to a [Field<bool>].
///
/// Writes `true` or `false` to [field.value] when toggled and calls
/// [Field.touch] immediately so that validation errors appear right away
/// without waiting for a form submit. The error string from [Field.error]
/// replaces [subtitle] once the field is touched.
///
/// [field] is the backing [Field<bool>].
/// [title] is the primary label shown next to the checkbox.
/// [subtitle] is the secondary label; replaced by the error text when the
/// field is touched and has an error.
/// [secondary] is an optional widget displayed on the opposite side of the tile.
/// [tristate] — when `true`, the checkbox cycles through `null`, `false`, `true`.
/// [activeColor] overrides the checkbox fill color when checked.
/// [checkColor] overrides the color of the check mark.
/// [selected] highlights the tile background when `true`.
/// [controlAffinity] controls which side the checkbox appears on.
/// [enabled] — when `false`, taps are ignored and the tile is visually dimmed.
/// [focusNode] overrides the internally managed [FocusNode].
///
/// Example:
/// ```dart
/// final terms = Field<bool>('terms')
///   ..mustBeTrue(message: 'Você deve aceitar os termos');
///
/// SignalCheckbox(
///   field: terms,
///   title: const Text('Aceito os termos de uso'),
/// )
/// ```
class SignalCheckbox extends StatefulWidget {
  final Field<bool> field;
  final Widget title;
  final Widget? subtitle;
  final Widget? secondary;
  final bool tristate;
  final Color? activeColor;
  final Color? checkColor;
  final bool selected;
  final ListTileControlAffinity controlAffinity;
  final bool enabled;
  final FocusNode? focusNode;

  const SignalCheckbox({
    super.key,
    required this.field,
    required this.title,
    this.subtitle,
    this.secondary,
    this.tristate = false,
    this.activeColor,
    this.checkColor,
    this.selected = false,
    this.controlAffinity = ListTileControlAffinity.leading,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<SignalCheckbox> createState() => _SignalCheckboxState();
}

class _SignalCheckboxState extends State<SignalCheckbox> {
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
  void didUpdateWidget(SignalCheckbox oldWidget) {
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
        return CheckboxListTile(
          focusNode: _effectiveFocusNode,
          value: widget.field.value ?? false,
          onChanged: widget.enabled
              ? (val) {
                  widget.field.value = val;
                  widget.field.touch();
                }
              : null,
          title: widget.title,
          subtitle: widget.field.isTouched && widget.field.error != null
              ? Text(widget.field.error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12))
              : widget.subtitle,
          secondary: widget.secondary,
          tristate: widget.tristate,
          activeColor: widget.activeColor,
          checkColor: widget.checkColor,
          selected: widget.selected,
          controlAffinity: widget.controlAffinity,
          enabled: widget.enabled,
        );
      },
    );
  }
}
