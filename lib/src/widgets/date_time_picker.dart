import 'package:flutter/material.dart';
import '../core.dart';

/// A reactive date picker bound to a [Field<DateTime>].
///
/// Tapping the widget opens the Material [showDatePicker] dialog. When the
/// user confirms a date, it is written to [field.value] and [Field.touch] is
/// called. [Field.error] surfaces inside the [InputDecorator] once touched.
///
/// The selected date is displayed as `YYYY-MM-DD` inside an [InputDecorator].
/// When no date is selected, the decorator content is empty.
///
/// [field] is the backing [Field<DateTime>].
/// [firstDate] is the earliest selectable date in the calendar.
/// [lastDate] is the latest selectable date in the calendar.
/// [decoration] wraps the picker with a Material [InputDecoration].
/// [initialDatePickerMode] controls whether the calendar opens to the day view
/// or the year view (defaults to [DatePickerMode.day]).
/// [helpText] overrides the dialog header label (e.g. "Selecione uma data").
/// [cancelText] overrides the cancel button label.
/// [confirmText] overrides the confirm button label.
/// [enabled] — when `false`, tapping does not open the picker.
/// [focusNode] overrides the internally managed [FocusNode].
///
/// Example:
/// ```dart
/// final birthDate = Field<DateTime>('birthDate')
///   ..required(message: 'Informe sua data de nascimento')
///   ..inPast(message: 'Data deve ser no passado');
///
/// SignalDateTimePicker(
///   field: birthDate,
///   firstDate: DateTime(1900),
///   lastDate: DateTime.now(),
///   decoration: const InputDecoration(
///     labelText: 'Data de nascimento',
///     suffixIcon: Icon(Icons.calendar_today),
///   ),
/// )
/// ```
class SignalDateTimePicker extends StatefulWidget {
  final Field<DateTime> field;
  final InputDecoration decoration;
  final DateTime firstDate;
  final DateTime lastDate;
  final DatePickerMode initialDatePickerMode;
  final String? helpText;
  final String? cancelText;
  final String? confirmText;
  final bool enabled;
  final FocusNode? focusNode;

  const SignalDateTimePicker({
    super.key,
    required this.field,
    required this.firstDate,
    required this.lastDate,
    this.decoration = const InputDecoration(),
    this.initialDatePickerMode = DatePickerMode.day,
    this.helpText,
    this.cancelText,
    this.confirmText,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<SignalDateTimePicker> createState() => _SignalDateTimePickerState();
}

class _SignalDateTimePickerState extends State<SignalDateTimePicker> {
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
  void didUpdateWidget(SignalDateTimePicker oldWidget) {
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
        return InkWell(
          focusNode: _effectiveFocusNode,
          onTap: widget.enabled
              ? () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: widget.field.value ?? DateTime.now(),
                    firstDate: widget.firstDate,
                    lastDate: widget.lastDate,
                    initialDatePickerMode: widget.initialDatePickerMode,
                    helpText: widget.helpText,
                    cancelText: widget.cancelText,
                    confirmText: widget.confirmText,
                  );
                  if (pickedDate != null) {
                    widget.field.value = pickedDate;
                    widget.field.touch();
                  }
                }
              : null,
          child: InputDecorator(
            decoration: widget.decoration.copyWith(
              errorText: widget.field.isTouched ? widget.field.error : null,
              enabled: widget.enabled,
            ),
            child: Text(
              widget.field.value == null ? '' : widget.field.value.toString().split(' ')[0],
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        );
      },
    );
  }
}
