import '../core.dart';

/// Validation extensions for [Field<bool>].
///
/// All methods return `this` to allow method chaining on the field builder.
extension BoolFieldValidators on Field<bool> {
  /// Whether the field's current value is `true`.
  ///
  /// Convenience getter — equivalent to `value == true`.
  ///
  /// Example:
  /// ```dart
  /// final terms = Field<bool>('acceptTerms');
  /// terms.value = true;
  /// print(terms.isChecked); // true
  /// ```
  bool get isChecked => value == true;

  /// Validates that the value is exactly `true`.
  ///
  /// Commonly used for terms-of-service acceptance checkboxes where the user
  /// must actively check the box to proceed.
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final terms = Field<bool>('acceptTerms')
  ///   ..mustBeTrue(message: 'Você deve aceitar os termos');
  ///
  /// terms.value = false;
  /// terms.validate();
  /// print(terms.error); // 'Você deve aceitar os termos'
  /// ```
  Field<bool> mustBeTrue({String message = '', bool exposed = false}) {
    return addValidator(message, (val) => val != true, exposedMessage: exposed);
  }

  /// Validates that the value is exactly `false`.
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final consent = Field<bool>('marketingOptOut')
  ///   ..mustBeFalse(message: 'Opção inválida');
  /// ```
  Field<bool> mustBeFalse({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != false,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is not `null` (either `true` or `false`).
  ///
  /// Use when the user must explicitly make a boolean choice but either
  /// `true` or `false` is acceptable.
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final newsletter = Field<bool>('newsletter')
  ///   ..required(message: 'Selecione uma opção');
  ///
  /// newsletter.validate(); // null → error
  /// newsletter.value = false;
  /// newsletter.validate(); // false is valid → no error
  /// ```
  Field<bool> required({String message = '', bool exposed = false}) {
    return addValidator(message, (val) => val == null, exposedMessage: exposed);
  }
}
