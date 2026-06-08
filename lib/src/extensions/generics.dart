import '../core.dart';

/// Generic validation extensions available on any [Field<T>].
///
/// These methods work regardless of the field's value type and return `this`
/// to allow method chaining on the field builder.
extension GenericFieldValidators<T> on Field<T> {
  /// Validates using a custom predicate where `true` means the value is valid.
  ///
  /// [isValid] receives the current [value] and must return `true` when the
  /// value is acceptable. This is the inverse of [Field.addValidator]'s
  /// `hasError` convention.
  ///
  /// [message] is the error string shown when [isValid] returns `false`.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final score = Field<int>('score')
  ///   .must((v) => v != null && v >= 0 && v <= 100,
  ///       message: 'Pontuação deve estar entre 0 e 100');
  /// ```
  Field<T> must(
    bool Function(T? value) isValid, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => !isValid(val),
      exposedMessage: exposed,
    );
  }

  /// Validates using a custom predicate that also has access to other fields.
  ///
  /// [isValid] receives the current [value] and a [ValueOf] function that
  /// looks up sibling fields by their dot-notation path. Must return `true`
  /// when the value is acceptable.
  ///
  /// [message] is the error string shown when [isValid] returns `false`.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final endDate = Field<DateTime>('endDate')
  ///   .mustWith(
  ///     (val, valueOf) {
  ///       final start = valueOf<DateTime>('startDate').value;
  ///       return val != null && start != null && val.isAfter(start);
  ///     },
  ///     message: 'Data final deve ser após a data inicial',
  ///   );
  /// ```
  Field<T> mustWith(
    bool Function(T? value, ValueOf valueOf) isValid, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(message, (val) {
      if (form == null) return false;
      Field<O> valueOf<O>(String path) => form!.getField<O>(path);
      return !isValid(val, valueOf);
    }, exposedMessage: exposed);
  }

  /// Validates that the value is equal to [otherValue].
  ///
  /// [otherValue] is the exact value the field must match.
  /// [message] is the error string shown when they are not equal.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final inviteCode = Field<String>('inviteCode')
  ///   .equalTo('PROMO2024', message: 'Código inválido');
  /// ```
  Field<T> equalTo(T otherValue, {String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != otherValue,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is `null`.
  ///
  /// [message] is the error string shown when the value is not `null`.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final unused = Field<String>('legacy')
  ///   .isNull(message: 'Este campo deve estar vazio');
  /// ```
  Field<T> isNull({String message = '', bool exposed = false}) {
    return addValidator(message, (val) => val != null, exposedMessage: exposed);
  }

  /// Validates that the value is not `null`.
  ///
  /// [message] is the error string shown when the value is `null`.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final category = Field<String>('category')
  ///   ..isNotNull(message: 'Selecione uma categoria');
  /// ```
  Field<T> isNotNull({String message = '', bool exposed = false}) {
    return addValidator(message, (val) => val == null, exposedMessage: exposed);
  }

  /// Validates that the value is one of the allowed values.
  ///
  /// An empty or null value passes (pair with `required` to also reject empty).
  ///
  /// Parameters:
  /// * [allowedValues]: The list of accepted values of type [T].
  /// * [message]: The error string shown when the value is not in the list.
  /// * [exposed] (optional): When `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final role = Field<String>('role')
  ///   .oneOf(['admin', 'editor', 'viewer'], message: 'Perfil inválido');
  /// ```
  Field<T> oneOf(
    List<T> allowedValues, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator('$message ${allowedValues.join(', ')}', (val) {
      if (val == null) return false;
      if (val is String && val.isEmpty) return false;
      if (val is Iterable && val.isEmpty) return false;
      return !allowedValues.contains(val);
    }, exposedMessage: exposed);
  }
}
