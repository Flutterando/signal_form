import '../core.dart';

/// Validation extensions for [Field<DateTime>].
///
/// All methods return `this` to allow method chaining on the field builder.
///
/// Methods that accept a [ValueOf] parameter can reference sibling fields by
/// their dot-notation path, enabling cross-field date comparisons (e.g.
/// "end date must be after start date").
extension DateTimeFieldValidators on Field<DateTime> {
  /// Validates that the value is not `null`.
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final birthDate = Field<DateTime>('birthDate')
  ///   .required(message: 'Informe sua data de nascimento');
  /// ```
  Field<DateTime> required({String message = '', bool exposed = false}) {
    return addValidator(message, (val) => val == null, exposedMessage: exposed);
  }

  /// Validates that this date is strictly after the date returned by
  /// [getOtherDate].
  ///
  /// [getOtherDate] receives a [ValueOf] function to read another field's
  /// value by path. If the other field's value is `null`, the rule is skipped.
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final endDate = Field<DateTime>('endDate')
  ///   .after(
  ///     (valueOf) => valueOf<DateTime>('startDate').value,
  ///     message: 'Data final deve ser após a data inicial',
  ///   );
  /// ```
  Field<DateTime> after(
    DateTime? Function(ValueOf valueOf) getOtherDate, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(message, (val) {
      if (val == null) return false;
      Field<T> valueOf<T>(String path) => form!.getField<T>(path);
      final otherDate = getOtherDate(valueOf);
      if (otherDate == null) return false;
      return !val.isAfter(otherDate);
    }, exposedMessage: exposed);
  }

  /// Validates that this date is strictly after the fixed [date].
  ///
  /// [date] is a constant date to compare against.
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final eventDate = Field<DateTime>('eventDate')
  ///   .afterDate(DateTime.now(), message: 'Evento deve ser no futuro');
  /// ```
  Field<DateTime> afterDate(
    DateTime date, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && !val.isAfter(date),
      exposedMessage: exposed,
    );
  }

  /// Validates that this date is strictly before the date returned by
  /// [getOtherDate].
  ///
  /// [getOtherDate] receives a [ValueOf] function to read another field's
  /// value by path. If the other field's value is `null`, the rule is skipped.
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final startDate = Field<DateTime>('startDate')
  ///   .before(
  ///     (valueOf) => valueOf<DateTime>('endDate').value,
  ///     message: 'Data inicial deve ser antes da data final',
  ///   );
  /// ```
  Field<DateTime> before(
    DateTime? Function(ValueOf valueOf) getOtherDate, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(message, (val) {
      if (val == null) return false;
      Field<T> valueOf<T>(String path) => form!.getField<T>(path);
      final otherDate = getOtherDate(valueOf);
      if (otherDate == null) return false;
      return !val.isBefore(otherDate);
    }, exposedMessage: exposed);
  }

  /// Validates that this date is strictly before the fixed [date].
  ///
  /// [date] is a constant date to compare against.
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final birthDate = Field<DateTime>('birthDate')
  ///   .beforeDate(DateTime.now(), message: 'Data de nascimento inválida');
  /// ```
  Field<DateTime> beforeDate(
    DateTime date, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && !val.isBefore(date),
      exposedMessage: exposed,
    );
  }

  /// Validates that the date is in the past (strictly before `DateTime.now()`).
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final birthDate = Field<DateTime>('birthDate')
  ///   .inPast(message: 'Data de nascimento deve ser no passado');
  /// ```
  Field<DateTime> inPast({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && !val.isBefore(DateTime.now()),
      exposedMessage: exposed,
    );
  }

  /// Validates that the date is in the future (strictly after `DateTime.now()`).
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final expiryDate = Field<DateTime>('expiryDate')
  ///   .inFuture(message: 'Data de validade deve ser no futuro');
  /// ```
  Field<DateTime> inFuture({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && !val.isAfter(DateTime.now()),
      exposedMessage: exposed,
    );
  }

  /// Validates that the date falls within the range [[start], [end]] inclusive.
  ///
  /// [start] is the earliest allowed date (inclusive).
  /// [end] is the latest allowed date (inclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final checkIn = Field<DateTime>('checkIn')
  ///   .between(
  ///     DateTime(2024, 1, 1),
  ///     DateTime(2024, 12, 31),
  ///     message: 'Check-in deve ser em 2024',
  ///   );
  /// ```
  Field<DateTime> between(
    DateTime start,
    DateTime end, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && (val.isBefore(start) || val.isAfter(end)),
      exposedMessage: exposed,
    );
  }

  /// Validates that the date is on or after [minDate] (≥).
  ///
  /// [minDate] is the earliest allowed date (inclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final startDate = Field<DateTime>('startDate')
  ///   .greaterThanOrEqualTo(DateTime(2020, 1, 1),
  ///       message: 'Data deve ser a partir de 01/01/2020');
  /// ```
  Field<DateTime> greaterThanOrEqualTo(
    DateTime minDate, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && val.isBefore(minDate),
      exposedMessage: exposed,
    );
  }

  /// Validates that the date is strictly after [minDate] (>).
  ///
  /// [minDate] is the lower bound (exclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final endDate = Field<DateTime>('endDate')
  ///   .greaterThan(DateTime.now(), message: 'Deve ser após hoje');
  /// ```
  Field<DateTime> greaterThan(
    DateTime minDate, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && !val.isAfter(minDate),
      exposedMessage: exposed,
    );
  }

  /// Validates that the date is on or before [maxDate] (≤).
  ///
  /// [maxDate] is the latest allowed date (inclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final birthDate = Field<DateTime>('birthDate')
  ///   .lessThanOrEqualTo(DateTime.now(),
  ///       message: 'Data não pode ser no futuro');
  /// ```
  Field<DateTime> lessThanOrEqualTo(
    DateTime maxDate, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && val.isAfter(maxDate),
      exposedMessage: exposed,
    );
  }

  /// Validates that the date is strictly before [maxDate] (<).
  ///
  /// [maxDate] is the upper bound (exclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final deadline = Field<DateTime>('deadline')
  ///   .lessThan(DateTime(2025, 1, 1), message: 'Deve ser antes de 2025');
  /// ```
  Field<DateTime> lessThan(
    DateTime maxDate, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && !val.isBefore(maxDate),
      exposedMessage: exposed,
    );
  }

  /// Validates that the date falls within [[start], [end]] inclusive.
  ///
  /// Alias for [between] with explicit "inclusive" semantics in the name.
  ///
  /// [start] is the earliest allowed date (inclusive).
  /// [end] is the latest allowed date (inclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final date = Field<DateTime>('date')
  ///   .inclusiveBetween(
  ///     DateTime(2024, 6, 1),
  ///     DateTime(2024, 6, 30),
  ///     message: 'Data deve estar em junho de 2024',
  ///   );
  /// ```
  Field<DateTime> inclusiveBetween(
    DateTime start,
    DateTime end, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && (val.isBefore(start) || val.isAfter(end)),
      exposedMessage: exposed,
    );
  }

  /// Validates that the date falls strictly within ([start], [end]) exclusive.
  ///
  /// The date must be strictly after [start] AND strictly before [end].
  ///
  /// [start] is the lower bound (exclusive).
  /// [end] is the upper bound (exclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final date = Field<DateTime>('date')
  ///   ..exclusiveBetween(
  ///     DateTime(2024, 1, 1),
  ///     DateTime(2024, 12, 31),
  ///     message: 'Data deve ser estritamente dentro de 2024',
  ///   );
  /// ```
  Field<DateTime> exclusiveBetween(
    DateTime start,
    DateTime end, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && (!val.isAfter(start) || !val.isBefore(end)),
      exposedMessage: exposed,
    );
  }
}
