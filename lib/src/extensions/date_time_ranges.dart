import 'package:flutter/material.dart';
import '../core.dart';

/// Validation extensions for [Field<DateTimeRange>].
///
/// All methods return `this` to allow method chaining on the field builder.
extension DateTimeRangeFieldValidators on Field<DateTimeRange> {
  /// Validates that the value is not `null`.
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final vacation = Field<DateTimeRange>('vacation')
  ///   ..required(message: 'Select a vacation range');
  /// ```
  Field<DateTimeRange> required({String message = '', bool exposed = false}) {
    return addValidator(message, (val) => val == null, exposedMessage: exposed);
  }

  /// Validates that the duration of the selected date range is at least [min].
  ///
  /// [min] is the minimum allowed duration.
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final vacation = Field<DateTimeRange>('vacation')
  ///   ..minDuration(const Duration(days: 3), message: 'Must select at least 3 days');
  /// ```
  Field<DateTimeRange> minDuration(Duration min, {String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.duration < min,
      exposedMessage: exposed,
    );
  }

  /// Validates that the duration of the selected date range is at most [max].
  ///
  /// [max] is the maximum allowed duration.
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final vacation = Field<DateTimeRange>('vacation')
  ///   ..maxDuration(const Duration(days: 30), message: 'Cannot exceed 30 days');
  /// ```
  Field<DateTimeRange> maxDuration(Duration max, {String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.duration > max,
      exposedMessage: exposed,
    );
  }

  /// Validates that the range starts strictly after the fixed [date].
  ///
  /// [date] is a constant date to compare against.
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final vacation = Field<DateTimeRange>('vacation')
  ///   ..startsAfter(DateTime.now(), message: 'Must start after today');
  /// ```
  Field<DateTimeRange> startsAfter(DateTime date, {String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && !val.start.isAfter(date),
      exposedMessage: exposed,
    );
  }

  /// Validates that the range starts strictly before the fixed [date].
  ///
  /// [date] is a constant date to compare against.
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  Field<DateTimeRange> startsBefore(DateTime date, {String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && !val.start.isBefore(date),
      exposedMessage: exposed,
    );
  }

  /// Validates that the range ends strictly after the fixed [date].
  ///
  /// [date] is a constant date to compare against.
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  Field<DateTimeRange> endsAfter(DateTime date, {String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && !val.end.isAfter(date),
      exposedMessage: exposed,
    );
  }

  /// Validates that the range ends strictly before the fixed [date].
  ///
  /// [date] is a constant date to compare against.
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  Field<DateTimeRange> endsBefore(DateTime date, {String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && !val.end.isBefore(date),
      exposedMessage: exposed,
    );
  }
}
