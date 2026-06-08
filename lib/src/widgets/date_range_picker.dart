import 'package:flutter/material.dart';
import '../core.dart';

/// A reactive date-range picker bound to a [Field<DateTimeRange>].
///
/// Tapping the widget opens the Material [showDateRangePicker] dialog. When
/// the user confirms a range, it is written to [field.value] as a
/// [DateTimeRange] and [Field.touch] is called. [Field.error] surfaces inside
/// the [InputDecorator] once touched.
///
/// The selected range is displayed as `YYYY-MM-DD - YYYY-MM-DD` inside an
/// [InputDecorator]. When no range is selected, the content is empty.
///
/// [field] is the backing [Field<DateTimeRange>].
/// [firstDate] is the earliest selectable date.
/// [lastDate] is the latest selectable date.
/// [decoration] wraps the picker with a Material [InputDecoration].
/// [helpText] overrides the dialog header label.
/// [cancelText] overrides the cancel button label.
/// [confirmText] overrides the confirm button label.
/// [saveText] overrides the save button label shown in the input mode.
/// [errorFormatText] overrides the message shown for an invalid date format.
/// [errorInvalidText] overrides the message shown for a date outside the
/// allowed range.
/// [errorInvalidRangeText] overrides the message shown when the end date is
/// before the start date.
/// [enabled] — when `false`, tapping does not open the picker.
/// [focusNode] overrides the internally managed [FocusNode].
///
/// Example:
/// ```dart
/// final vacation = Field<DateTimeRange>('vacation')
///   ..required(message: 'Selecione o período');
///
/// SignalDateRangePicker(
///   field: vacation,
///   firstDate: DateTime.now(),
///   lastDate: DateTime.now().add(const Duration(days: 365)),
///   decoration: const InputDecoration(
///     labelText: 'Período de férias',
///     suffixIcon: Icon(Icons.date_range),
///   ),
/// )
/// ```
class SignalDateRangePicker extends StatefulWidget {
  final Field<DateTimeRange> field;
  final InputDecoration decoration;
  final DateTime firstDate;
  final DateTime lastDate;
  final String? helpText;
  final String? cancelText;
  final String? confirmText;
  final String? saveText;
  final String? errorFormatText;
  final String? errorInvalidText;
  final String? errorInvalidRangeText;
  final bool enabled;
  final FocusNode? focusNode;

  const SignalDateRangePicker({
    super.key,
    required this.field,
    required this.firstDate,
    required this.lastDate,
    this.decoration = const InputDecoration(),
    this.helpText,
    this.cancelText,
    this.confirmText,
    this.saveText,
    this.errorFormatText,
    this.errorInvalidText,
    this.errorInvalidRangeText,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<SignalDateRangePicker> createState() => _SignalDateRangePickerState();
}

class _SignalDateRangePickerState extends State<SignalDateRangePicker> {
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
  void didUpdateWidget(SignalDateRangePicker oldWidget) {
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
                  final pickedRange = await showDateRangePicker(
                    context: context,
                    initialDateRange: widget.field.value,
                    firstDate: widget.firstDate,
                    lastDate: widget.lastDate,
                    helpText: widget.helpText,
                    cancelText: widget.cancelText,
                    confirmText: widget.confirmText,
                    saveText: widget.saveText,
                    errorFormatText: widget.errorFormatText,
                    errorInvalidText: widget.errorInvalidText,
                    errorInvalidRangeText: widget.errorInvalidRangeText,
                  );
                  if (pickedRange != null) {
                    widget.field.value = pickedRange;
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
              widget.field.value == null
                  ? ''
                  : '${widget.field.value!.start.toString().split(' ')[0]} - ${widget.field.value!.end.toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        );
      },
    );
  }
}
