import 'package:flutter/material.dart';
import '../core.dart';

/// A reactive [SwitchListTile] bound to a [Field<bool>].
///
/// Writes `true` or `false` to [field.value] on toggle and calls
/// [Field.touch] immediately. The error from [Field.error] replaces
/// [subtitle] once the field has been touched.
///
/// [field] is the backing [Field<bool>].
/// [title] is the primary label shown next to the switch.
/// [subtitle] is the secondary label; replaced by the error text when the
/// field is touched and has an error.
/// [secondary] is an optional widget shown on the opposite side of the tile.
/// [activeColor] overrides the thumb color when the switch is on.
/// [activeTrackColor] overrides the track color when the switch is on.
/// [inactiveThumbColor] overrides the thumb color when the switch is off.
/// [inactiveTrackColor] overrides the track color when the switch is off.
/// [activeThumbImage] is an image painted on the thumb when the switch is on.
/// [inactiveThumbImage] is an image painted on the thumb when the switch is off.
/// [controlAffinity] controls which side the switch appears on (defaults to
/// [ListTileControlAffinity.trailing]).
/// [enabled] — when `false`, toggling is disabled and the tile is dimmed.
/// [focusNode] overrides the internally managed [FocusNode].
///
/// Example:
/// ```dart
/// final notifications = Field<bool>('notifications');
///
/// SignalSwitch(
///   field: notifications,
///   title: const Text('Receber notificações'),
///   subtitle: const Text('Push e email'),
/// )
/// ```
class SignalSwitch extends StatefulWidget {
  final Field<bool> field;
  final Widget title;
  final Widget? subtitle;
  final Widget? secondary;
  final Color? activeColor;
  final Color? activeTrackColor;
  final Color? inactiveThumbColor;
  final Color? inactiveTrackColor;
  final ImageProvider? activeThumbImage;
  final ImageProvider? inactiveThumbImage;
  final ListTileControlAffinity controlAffinity;
  final bool enabled;
  final FocusNode? focusNode;

  const SignalSwitch({
    super.key,
    required this.field,
    required this.title,
    this.subtitle,
    this.secondary,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.activeThumbImage,
    this.inactiveThumbImage,
    this.controlAffinity = ListTileControlAffinity.trailing,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<SignalSwitch> createState() => _SignalSwitchState();
}

class _SignalSwitchState extends State<SignalSwitch> {
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
  void didUpdateWidget(SignalSwitch oldWidget) {
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
        return SwitchListTile(
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
          activeThumbColor: widget.activeColor,
          activeTrackColor: widget.activeTrackColor,
          inactiveThumbColor: widget.inactiveThumbColor,
          inactiveTrackColor: widget.inactiveTrackColor,
          activeThumbImage: widget.activeThumbImage,
          inactiveThumbImage: widget.inactiveThumbImage,
          controlAffinity: widget.controlAffinity,
        );
      },
    );
  }
}
