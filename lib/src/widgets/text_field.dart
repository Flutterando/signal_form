import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core.dart';

/// A reactive Material Design text field bound to a [Field<String>].
///
/// [SignalTextField] keeps a [TextEditingController] in sync with [Field.value]
/// in both directions:
///
/// - **Field → controller**: listens to [Field.notifyListeners] and updates
///   the controller text whenever the field's value changes externally (e.g.
///   via [Field.mask] or [FormController.patchValue]).
/// - **Controller → field**: on each keystroke, writes the raw text back to
///   `field.value`, triggering validation and dirty tracking.
///
/// Touch and blur are handled automatically: when the focus node loses focus,
/// [Field.touch] is called, which causes [Field.error] to appear under the
/// field via [InputDecoration.errorText].
///
/// [field] is the backing [Field<String>].
/// [decoration] is the [InputDecoration] applied to the underlying [TextField].
/// [keyboardType] sets the soft-keyboard layout (e.g. [TextInputType.emailAddress]).
/// [obscureText] — when `true`, characters are replaced with bullets (password fields).
/// [textInputAction] controls the action button on the soft keyboard.
/// [onChanged] is called after each keystroke, after [field.value] is updated.
/// [onEditingComplete] fires when the user presses the keyboard action button.
/// [onSubmitted] fires with the final text when editing is complete.
/// [inputFormatters] apply in-order transformations before the value reaches the field.
/// [enabled] — when `false`, the text field is read-only and visually dimmed.
/// [maxLines] is the maximum number of lines (defaults to 1; `null` = unlimited).
/// [minLines] is the minimum number of lines shown when the field is empty.
/// [autofocus] — when `true`, the field requests focus as soon as it mounts.
/// [focusNode] overrides the internally managed [FocusNode]; useful when
/// coordinating focus across multiple fields programmatically.
///
/// Example:
/// ```dart
/// final email = Field<String>('email')
///   ..required(message: 'Obrigatório')
///   ..email(message: 'Email inválido');
///
/// SignalTextField(
///   field: email,
///   keyboardType: TextInputType.emailAddress,
///   textInputAction: TextInputAction.next,
///   decoration: const InputDecoration(labelText: 'Email'),
/// )
/// ```
class SignalTextField extends StatefulWidget {
  final Field<dynamic> field;
  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final bool autofocus;
  final FocusNode? focusNode;

  const SignalTextField({
    super.key,
    required this.field,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.inputFormatters,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<SignalTextField> createState() => _SignalTextFieldState();
}

class _SignalTextFieldState extends State<SignalTextField> {
  late final TextEditingController _controller;
  late final FocusNode _internalFocusNode;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.field.text ?? '');
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
    widget.field.focusNode = _effectiveFocusNode;
    _effectiveFocusNode.addListener(_onFocusChange);
    widget.field.addListener(_onFieldChange);
  }

  void _onFocusChange() {
    if (!_effectiveFocusNode.hasFocus) {
      widget.field.touch();
    }
  }

  void _onFieldChange() {
    if (_controller.text != widget.field.text) {
      final newValue = widget.field.text ?? '';
      final oldSelection = _controller.selection;

      int newCursorPosition = newValue.length;
      if (oldSelection.isValid) {
        if (oldSelection.end == _controller.text.length) {
          newCursorPosition = newValue.length;
        } else {
          final diff = newValue.length - _controller.text.length;
          newCursorPosition = (oldSelection.start + diff).clamp(0, newValue.length);
        }
      }

      _controller.value = _controller.value.copyWith(
        text: newValue,
        selection: TextSelection.collapsed(offset: newCursorPosition),
      );
    }
  }

  @override
  void didUpdateWidget(SignalTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      if (oldWidget.focusNode == null) _internalFocusNode.removeListener(_onFocusChange);

      if (widget.focusNode == null) {
        _internalFocusNode = FocusNode();
      }
      widget.field.focusNode = _effectiveFocusNode;
      _effectiveFocusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _internalFocusNode.dispose();
    widget.field.removeListener(_onFieldChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.field,
      builder: (context, _) {
        return TextField(
          controller: _controller,
          focusNode: _effectiveFocusNode,
          decoration: widget.decoration.copyWith(
            errorText: widget.field.isTouched ? widget.field.error : null,
          ),
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          textInputAction: widget.textInputAction,
          onChanged: (value) {
            widget.field.value = value;
            widget.onChanged?.call(value);
            if (_controller.text != widget.field.text) {
              _onFieldChange();
            }
          },
          onEditingComplete: widget.onEditingComplete,
          onSubmitted: widget.onSubmitted,
          enabled: widget.enabled,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          autofocus: widget.autofocus,
        );
      },
    );
  }
}
