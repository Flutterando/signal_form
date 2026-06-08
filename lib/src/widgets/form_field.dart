import 'package:flutter/material.dart';
import '../core.dart';

/// A generic reactive wrapper that rebuilds whenever [field] changes.
///
/// Use [SignalFormField] to bind any [Field<T>] to a custom widget tree.
/// The [builder] is called inside a [ListenableBuilder], so it re-runs
/// whenever [Field.notifyListeners] fires — on value change, validation
/// completion, or loading-state changes.
///
/// [T] is the value type of the backing [field].
/// [field] is the reactive [Field] driving rebuilds.
/// [builder] receives the current [BuildContext] and the [field] itself,
/// giving access to [Field.value], [Field.error], [Field.isTouched], etc.
///
/// Example:
/// ```dart
/// SignalFormField<String>(
///   field: nameField,
///   builder: (context, field) {
///     return Column(
///       crossAxisAlignment: CrossAxisAlignment.start,
///       children: [
///         TextFormField(
///           initialValue: field.value,
///           onChanged: (v) => field.value = v,
///           decoration: InputDecoration(
///             errorText: field.isTouched ? field.error : null,
///           ),
///         ),
///       ],
///     );
///   },
/// )
/// ```
class SignalFormField<T> extends StatelessWidget {
  final Field<T> field;
  final Widget Function(BuildContext context, Field<T> field) builder;

  const SignalFormField({
    super.key,
    required this.field,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: field,
      builder: (context, _) => builder(context, field),
    );
  }
}

/// A labelled value for selection widgets such as [SignalRadioGroup],
/// [SignalCheckboxGroup], [SignalFilterChip], and [SignalChoiceChip].
///
/// Each option carries a typed [value] that is written to the backing
/// [Field] when selected, and either a [child] widget or a plain [label]
/// string to display. At least one of [child] or [label] must be provided.
///
/// [T] is the type of [value] and must match the field's value type.
/// [value] is the data stored in the field when this option is chosen.
/// [child] is an arbitrary widget rendered as the option label.
/// [label] is a convenience shorthand — produces a [Text] widget.
///
/// Example:
/// ```dart
/// final options = [
///   SignalFieldOption(value: 'dart', label: 'Dart'),
///   SignalFieldOption(value: 'flutter', label: 'Flutter'),
///   SignalFieldOption(
///     value: 'firebase',
///     child: Row(children: [Icon(Icons.cloud), Text('Firebase')]),
///   ),
/// ];
/// ```
class SignalFieldOption<T> {
  final T value;
  final Widget? child;
  final String? label;

  const SignalFieldOption({
    required this.value,
    this.child,
    this.label,
  }) : assert(child != null || label != null);

  Widget get widget => child ?? Text(label!);
}
