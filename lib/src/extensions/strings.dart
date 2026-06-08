import '../core.dart';

/// Validation and helper extensions for [Field<String>].
///
/// All validator methods return `this` to allow method chaining on the field
/// builder. The shared [message] and [exposed] parameters follow the same
/// convention as [Field.addValidator]:
///
/// - [message] — static error string shown when validation fails.
/// - [exposed] — when `true`, the rule appears in [Field.exposedRules].
extension StringFieldValidators on Field<String> {
  static final _nonDigitRegex = RegExp(r'[^0-9]');
  static final _repeatedDigitsRegex11 = RegExp(r'^(\d)\1{10}$');
  static final _repeatedDigitsRegex13 = RegExp(r'^(\d)\1{13}$');
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$',
  );
  static final _urlPatternRegex = RegExp(
    r'^(?:https?://)?[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(?:\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+/?.*$',
    caseSensitive: false,
  );
  static final _urlSchemeRegex = RegExp(r'https?://', caseSensitive: false);
  static final _alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
  static final _numericRegex = RegExp(r'^[0-9]+$');
  static final _lowercaseCharRegex = RegExp(r'[a-z]');
  static final _uppercaseCharRegex = RegExp(r'[A-Z]');
  static final _digitCharRegex = RegExp(r'[0-9]');
  static final _specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
  static final _cepRegex = RegExp(r'^\d{5}-?\d{3}$');
  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static final _uuidv4Regex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static final _uuidv6Regex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-6[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static final _uuidv7Regex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static final _cuidRegex = RegExp(r'^c[a-z0-9]{24}$');
  static final _cuid2Regex = RegExp(r'^[a-z][a-z0-9]{23}$');
  static final _ulidRegex = RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$');
  static final _dateRegex = RegExp(
    r'^\d{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12]\d|3[01])$',
  );
  static final _timeRegex = RegExp(
    r'^(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d+)?$',
  );
  static final _datetimeRegex = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?$',
  );
  static final _isoTimeRegex = RegExp(
    r'^(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?$',
  );
  static final _isoDurationRegex = RegExp(
    r'^P(?:\d+Y)?(?:\d+M)?(?:\d+W)?(?:\d+D)?(?:T(?:\d+H)?(?:\d+M)?(?:\d+(?:\.\d+)?S)?)?$',
  );
  static final _httpUrlRegex = RegExp(
    r'^https?://[^\s/$.?#].[^\s]*$',
    caseSensitive: false,
  );
  static final _hostnameRegex = RegExp(
    r'^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$',
  );
  static final _ipv4Regex = RegExp(
    r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
  );
  static final _ipv6Regex = RegExp(
    r'^(?:'
    r'(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|'
    r'(?:[0-9a-fA-F]{1,4}:){1,7}:|'
    r'(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|'
    r'(?:[0-9a-fA-F]{1,4}:){1,5}(?::[0-9a-fA-F]{1,4}){1,2}|'
    r'(?:[0-9a-fA-F]{1,4}:){1,4}(?::[0-9a-fA-F]{1,4}){1,3}|'
    r'(?:[0-9a-fA-F]{1,4}:){1,3}(?::[0-9a-fA-F]{1,4}){1,4}|'
    r'(?:[0-9a-fA-F]{1,4}:){1,2}(?::[0-9a-fA-F]{1,4}){1,5}|'
    r'[0-9a-fA-F]{1,4}:(?::[0-9a-fA-F]{1,4}){1,6}|'
    r':(?::[0-9a-fA-F]{1,4}){1,7}|'
    r'::)$',
  );
  static final _macRegex = RegExp(r'^(?:[0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2}$');
  static final _cidrv4Regex = RegExp(
    r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}'
    r'(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/(?:3[0-2]|[12]?[0-9])$',
  );
  static final _cidrv6Regex = RegExp(
    r'^[0-9a-fA-F:]+/(?:12[0-8]|1[01][0-9]|[1-9]?[0-9])$',
  );
  static final _base64Regex = RegExp(
    r'^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{4})$',
  );
  static final _base64urlRegex = RegExp(r'^[A-Za-z0-9_-]*={0,2}$');
  static final _hexRegex = RegExp(r'^[0-9a-fA-F]+$');
  static final _jwtRegex = RegExp(
    r'^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$',
  );

  /// The current value as a non-nullable string, or an empty string when
  /// [Field.value] is `null`.
  ///
  /// Useful in widget `build` methods to avoid null-check boilerplate when
  /// binding to a [TextEditingController].
  ///
  /// Example:
  /// ```dart
  /// TextEditingController(text: nameField.text)
  /// ```
  String get text => value ?? '';

  /// Validates that the value is not `null` and not blank (not empty after trim).
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final name = Field<String>('name')
  ///   .required(message: 'Nome é obrigatório');
  /// ```
  Field<String> required({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val == null || val.trim().isEmpty,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is one of [allowedValues].
  ///
  /// An empty or null value passes (pair with [required] to also reject empty).
  ///
  /// [allowedValues] is the list of accepted strings.
  /// [message] is the error string shown when the value is not in the list.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final role = Field<String>('role')
  ///   .oneOf(['admin', 'editor', 'viewer'], message: 'Perfil inválido');
  /// ```
  Field<String> oneOf(
    List<String> allowedValues, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      '$message ${allowedValues.join(', ')}',
      (val) => val != null && val.isNotEmpty && !allowedValues.contains(val),
      exposedMessage: exposed,
    );
  }

  /// Makes [required] conditional on [condition] evaluating to `true`.
  ///
  /// When [condition] returns `false`, the field is not validated.
  /// [condition] receives a [ValueOf] function to read sibling fields by path.
  ///
  /// [message] is the error string shown when the field is blank and the
  /// condition is active.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final companyName = Field<String>('companyName')
  ///   .when(
  ///     (valueOf) => valueOf<String>('accountType').value == 'company',
  ///     message: 'Razão social é obrigatória para empresas',
  ///   );
  /// ```
  Field<String> when(
    bool Function(ValueOf valueOf) condition, {
    String message = '',
  }) {
    return applyWhen(condition, (f) => f.required(message: message));
  }

  /// Validates that the string has at least [length] characters.
  ///
  /// A `null` value is treated as length 0 and fails this rule.
  ///
  /// [length] is the minimum character count (inclusive).
  /// [message] is the error string shown when the string is shorter.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final password = Field<String>('password')
  ///   .minLength(8, message: 'Senha deve ter no mínimo 8 caracteres');
  /// ```
  Field<String> minLength(
    int length, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val == null || val.length < length,
      exposedMessage: exposed,
    );
  }

  /// Validates that the string has at most [length] characters.
  ///
  /// A `null` value passes this rule (pair with [required] to also reject null).
  ///
  /// [length] is the maximum character count (inclusive).
  /// [message] is the error string shown when the string is longer.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final bio = Field<String>('bio')
  ///   .maxLength(280, message: 'Bio deve ter no máximo 280 caracteres');
  /// ```
  Field<String> maxLength(
    int length, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && val.length > length,
      exposedMessage: exposed,
    );
  }

  /// Validates that the string has exactly [exactLength] characters.
  ///
  /// [exactLength] is the required character count.
  /// [message] is the error string shown when the length does not match.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final code = Field<String>('verificationCode')
  ///   .length(6, message: 'Código deve ter 6 dígitos');
  /// ```
  Field<String> length(
    int exactLength, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && val.length != exactLength,
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is a well-formed email address.
  ///
  /// Uses RFC-5321 compatible regex. An empty or null value passes (pair with
  /// [required] to also reject blank values).
  ///
  /// [message] is the error string shown when the format is invalid.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final email = Field<String>('email')
  ///   .required(message: 'Obrigatório')
  ///   .email(message: 'Email inválido');
  /// ```
  Field<String> email({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_emailRegex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is a valid URL (with or without scheme).
  ///
  /// Accepts `http://`, `https://`, or scheme-less URLs (e.g. `example.com`).
  /// Validates host structure and presence of a domain extension.
  ///
  /// [message] is the error string shown when the URL is invalid.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final website = Field<String>('website')
  ///   .validUrl(message: 'URL inválida');
  /// ```
  Field<String> validUrl({String message = '', bool exposed = false}) {
    return addValidator(message, (val) {
      if (val == null || val.trim().isEmpty) return false;
      if (!_urlPatternRegex.hasMatch(val.trim())) return true;
      final uriString = val.trim().startsWith(_urlSchemeRegex)
          ? val.trim()
          : 'https://${val.trim()}';
      final uri = Uri.tryParse(uriString);
      return uri == null || uri.host.isEmpty || !uri.host.contains('.');
    }, exposedMessage: exposed);
  }

  /// Validates that the string matches the given [regex].
  ///
  /// An empty or null value passes (pair with [required] to also reject blank).
  ///
  /// [regex] is the regular expression the value must match.
  /// [message] is the error string shown when the value does not match.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final plate = Field<String>('plate')
  ///   .pattern(RegExp(r'^[A-Z]{3}-\d{4}$'), message: 'Placa inválida');
  /// ```
  Field<String> pattern(
    RegExp regex, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && !regex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string contains only alphanumeric characters (a–z, A–Z, 0–9).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final username = Field<String>('username')
  ///   .alphanumeric(message: 'Apenas letras e números');
  /// ```
  Field<String> alphanumeric({String message = '', bool exposed = false}) {
    return pattern(_alphanumericRegex, message: message, exposed: exposed);
  }

  /// Validates that the string contains only digit characters (0–9).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final pin = Field<String>('pin')
  ///   .numeric(message: 'PIN deve conter apenas números');
  /// ```
  Field<String> numeric({String message = '', bool exposed = false}) {
    return pattern(_numericRegex, message: message, exposed: exposed);
  }

  /// Validates that the string contains [substring].
  ///
  /// [substring] is the character sequence that must appear somewhere in the value.
  /// [message] is the error string shown when the substring is absent.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final domain = Field<String>('email')
  ///   .contains('@empresa.com', message: 'Use seu email corporativo');
  /// ```
  Field<String> contains(
    String substring, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && !val.contains(substring),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string starts with [prefix].
  ///
  /// [prefix] is the character sequence the value must begin with.
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final url = Field<String>('url')
  ///   .startsWith('https://', message: 'URL deve começar com https://');
  /// ```
  Field<String> startsWith(
    String prefix, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && !val.startsWith(prefix),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string ends with [suffix].
  ///
  /// [suffix] is the character sequence the value must end with.
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final file = Field<String>('filename')
  ///   .endsWith('.pdf', message: 'Arquivo deve ser PDF');
  /// ```
  Field<String> endsWith(
    String suffix, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && !val.endsWith(suffix),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string contains at least one lowercase letter (a–z).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final password = Field<String>('password')
  ///   .mustHaveLowercase(message: 'Deve conter letra minúscula',
  ///       exposed: true);
  /// ```
  Field<String> mustHaveLowercase({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val == null || !_lowercaseCharRegex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string contains at least one uppercase letter (A–Z).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final password = Field<String>('password')
  ///   .mustHaveUppercase(message: 'Deve conter letra maiúscula',
  ///       exposed: true);
  /// ```
  Field<String> mustHaveUppercase({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val == null || !_uppercaseCharRegex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string contains at least one digit (0–9).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final password = Field<String>('password')
  ///   .mustHaveNumber(message: 'Deve conter um número', exposed: true);
  /// ```
  Field<String> mustHaveNumber({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val == null || !_digitCharRegex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string contains at least one special character
  /// from the set `!@#$%^&*(),.?":{}|<>`.
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final password = Field<String>('password')
  ///   .mustHaveSpecialChar(message: 'Deve conter caractere especial',
  ///       exposed: true);
  /// ```
  Field<String> mustHaveSpecialChar({
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val == null || !_specialCharRegex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that this field's value equals the value of the field at
  /// [otherFieldPath] in the same form.
  ///
  /// Requires the field to be part of a [FormController]. If the other field
  /// does not exist or the form is not set, the rule is skipped.
  ///
  /// [otherFieldPath] is the dot-notation path of the field to compare with.
  /// [message] is the error string shown when the values differ.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final confirmPassword = Field<String>('confirmPassword')
  ///   .matches('password', message: 'Senhas não coincidem');
  /// ```
  Field<String> matches(
    String otherFieldPath, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(message, (val) {
      if (form == null) return false;
      final otherField = form!.tryGetField<String>(otherFieldPath);
      return otherField != null && val != otherField.value;
    }, exposedMessage: exposed);
  }

  /// Validates that this field's value equals the value of the field returned
  /// by [getOtherField].
  ///
  /// [getOtherField] receives a [ValueOf] function and must return the
  /// [Field<String>] to compare against. An empty or null value passes.
  ///
  /// [message] is the error string shown when the values differ.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final confirmPassword = Field<String>('confirmPassword')
  ///   .required()
  ///   .equals(
  ///     (valueOf) => valueOf<String>('account.password'),
  ///     message: 'As senhas não coincidem',
  ///   );
  /// ```
  Field<String> equals(
    Field<String> Function(ValueOf valueOf) getOtherField, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(message, (val) {
      if (form == null || val == null || val.isEmpty) return false;
      Field<T> valueOf<T>(String path) => form!.getField<T>(path);
      final otherField = getOtherField(valueOf);
      return val != otherField.value;
    }, exposedMessage: exposed);
  }

  /// Validates that the string is not empty (and not `null`).
  ///
  /// Trims the value before checking. Alias of [required] for semantic clarity.
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final title = Field<String>('title')
  ///   .notEmpty(message: 'Título não pode ser vazio');
  /// ```
  Field<String> notEmpty({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val == null || val.trim().isEmpty,
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is empty (or `null`).
  ///
  /// Trims the value before checking. Use when a field must be intentionally
  /// left blank (e.g. an unused legacy field).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final legacy = Field<String>('legacyCode')
  ///   ..isEmpty(message: 'Este campo deve estar em branco');
  /// ```
  Field<String> isEmpty({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.trim().isNotEmpty,
      exposedMessage: exposed,
    );
  }

  /// Validates that the string matches [regex].
  ///
  /// Alias for [pattern] with a more descriptive name.
  ///
  /// [regex] is the regular expression the value must match.
  /// [message] is the error string shown when the value does not match.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final code = Field<String>('code')
  ///   .matchesPattern(RegExp(r'^[A-Z]{2}\d{4}$'),
  ///       message: 'Formato: 2 letras + 4 números');
  /// ```
  Field<String> matchesPattern(
    RegExp regex, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && !regex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string contains at least one digit (0–9).
  ///
  /// Alias for [mustHaveNumber].
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final password = Field<String>('password')
  ///   .mustHaveNumbers(message: 'Deve conter números', exposed: true);
  /// ```
  Field<String> mustHaveNumbers({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val == null || !_digitCharRegex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string contains at least one special character.
  ///
  /// Alias for [mustHaveSpecialChar].
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final password = Field<String>('password')
  ///   .mustHaveSpecialCharacter(message: 'Deve conter caractere especial');
  /// ```
  Field<String> mustHaveSpecialCharacter({
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val == null || !_specialCharRegex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is a valid Brazilian CPF number.
  ///
  /// Accepts both formatted (`123.456.789-09`) and unformatted (`12345678909`)
  /// inputs. Checks length, repeated-digit sequences, and both check digits.
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final cpf = Field<String>('cpf')
  ///   .validCPF(message: 'CPF inválido');
  /// ```
  Field<String> validCPF({String message = ''}) {
    return addValidator(message, (val) {
      if (val == null || val.isEmpty) return false;
      final cleanCpf = val.replaceAll(_nonDigitRegex, '');
      if (cleanCpf.length != 11) return true;
      if (_repeatedDigitsRegex11.hasMatch(cleanCpf)) return true;

      var sum = 0;
      for (var i = 0; i < 9; i++) {
        sum += int.parse(cleanCpf[i]) * (10 - i);
      }
      var checkDigit1 = 11 - (sum % 11);
      if (checkDigit1 >= 10) checkDigit1 = 0;
      if (int.parse(cleanCpf[9]) != checkDigit1) return true;

      sum = 0;
      for (var i = 0; i < 10; i++) {
        sum += int.parse(cleanCpf[i]) * (11 - i);
      }
      var checkDigit2 = 11 - (sum % 11);
      if (checkDigit2 >= 10) checkDigit2 = 0;
      if (int.parse(cleanCpf[10]) != checkDigit2) return true;

      return false;
    });
  }

  /// Validates that the string is a valid Brazilian CNPJ number.
  ///
  /// Accepts both formatted (`12.345.678/0001-90`) and unformatted inputs.
  /// Checks length, repeated-digit sequences, and both check digits.
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final cnpj = Field<String>('cnpj')
  ///   .validCNPJ(message: 'CNPJ inválido');
  /// ```
  Field<String> validCNPJ({String message = ''}) {
    return addValidator(message, (val) {
      if (val == null || val.isEmpty) return false;
      final cleanCnpj = val.replaceAll(_nonDigitRegex, '');
      if (cleanCnpj.length != 14) return true;
      if (_repeatedDigitsRegex13.hasMatch(cleanCnpj)) return true;

      final weight1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
      var sum = 0;
      for (var i = 0; i < 12; i++) {
        sum += int.parse(cleanCnpj[i]) * weight1[i];
      }
      var digit1 = sum % 11;
      digit1 = digit1 < 2 ? 0 : 11 - digit1;
      if (int.parse(cleanCnpj[12]) != digit1) return true;

      final weight2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
      sum = 0;
      for (var i = 0; i < 13; i++) {
        sum += int.parse(cleanCnpj[i]) * weight2[i];
      }
      var digit2 = sum % 11;
      digit2 = digit2 < 2 ? 0 : 11 - digit2;
      if (int.parse(cleanCnpj[13]) != digit2) return true;

      return false;
    });
  }

  /// Validates that the string is a valid Brazilian CEP (postal code).
  ///
  /// Accepts both formatted (`01310-100`) and unformatted (`01310100`) inputs.
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final zip = Field<String>('zip')
  ///   .validCEP(message: 'CEP inválido');
  /// ```
  Field<String> validCEP({String message = ''}) {
    return addValidator(message, (val) {
      if (val == null || val.isEmpty) return false;
      return !_cepRegex.hasMatch(val);
    });
  }

  /// Validates that the string is a valid Brazilian CPF or CNPJ number.
  ///
  /// Automatically detects whether the clean digit count (11 = CPF, 14 = CNPJ)
  /// and applies the corresponding check-digit algorithm.
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final document = Field<String>('document')
  ///   .validCPFOrCNPJ(message: 'CPF ou CNPJ inválido');
  /// ```
  Field<String> validCPFOrCNPJ({String message = ''}) {
    return addValidator(message, (val) {
      if (val == null || val.isEmpty) return false;
      final clean = val.replaceAll(_nonDigitRegex, '');
      if (clean.length == 11) {
        if (_repeatedDigitsRegex11.hasMatch(clean)) return true;
        var sum = 0;
        for (var i = 0; i < 9; i++) {
          sum += int.parse(clean[i]) * (10 - i);
        }
        var checkDigit1 = 11 - (sum % 11);
        if (checkDigit1 >= 10) checkDigit1 = 0;
        if (int.parse(clean[9]) != checkDigit1) return true;

        sum = 0;
        for (var i = 0; i < 10; i++) {
          sum += int.parse(clean[i]) * (11 - i);
        }
        var checkDigit2 = 11 - (sum % 11);
        if (checkDigit2 >= 10) checkDigit2 = 0;
        if (int.parse(clean[10]) != checkDigit2) return true;

        return false;
      } else if (clean.length == 14) {
        final weight1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
        var sum = 0;
        for (var i = 0; i < 12; i++) {
          sum += int.parse(clean[i]) * weight1[i];
        }
        var digit1 = sum % 11;
        digit1 = digit1 < 2 ? 0 : 11 - digit1;
        if (int.parse(clean[12]) != digit1) return true;

        final weight2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
        sum = 0;
        for (var i = 0; i < 13; i++) {
          sum += int.parse(clean[i]) * weight2[i];
        }
        var digit2 = sum % 11;
        digit2 = digit2 < 2 ? 0 : 11 - digit2;
        if (int.parse(clean[13]) != digit2) return true;

        return false;
      }
      return true;
    });
  }

  /// Validates that the string is a valid credit card number using the
  /// Luhn algorithm.
  ///
  /// Accepts 13–19 digit numbers with or without spaces/hyphens.
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final card = Field<String>('cardNumber')
  ///   .validCreditCard(message: 'Número de cartão inválido');
  /// ```
  Field<String> validCreditCard({String message = ''}) {
    return addValidator(message, (val) {
      if (val == null || val.isEmpty) return false;
      final clean = val.replaceAll(_nonDigitRegex, '');
      if (clean.length < 13 || clean.length > 19) return true;

      var sum = 0;
      var alternate = false;
      for (var i = clean.length - 1; i >= 0; i--) {
        var n = int.parse(clean[i]);
        if (alternate) {
          n *= 2;
          if (n > 9) n -= 9;
        }
        sum += n;
        alternate = !alternate;
      }
      return sum % 10 != 0;
    });
  }

  /// Validates that the string is a valid Brazilian mobile phone number
  /// in the format `xx9xxxxxxxx` (11 digits, DDD + 9 + 8 digits).
  ///
  /// Accepts formatted inputs (e.g. `(11) 99999-9999`).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final phone = Field<String>('phone')
  ///   .validPhoneBR(message: 'Telefone inválido');
  /// ```
  Field<String> validPhoneBR({String message = ''}) {
    return addValidator(message, (val) {
      if (val == null || val.isEmpty) return false;
      final clean = val.replaceAll(_nonDigitRegex, '');
      if (clean.length != 11) return true;
      return clean[2] != '9';
    });
  }

  /// Validates that the string is a valid Brazilian phone number including
  /// the country code `55` (format `55xx9xxxxxxxx`, 13 digits).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final phone = Field<String>('phone')
  ///   .validPhoneWithCountryCodeBR(message: 'Telefone com DDI inválido');
  /// ```
  Field<String> validPhoneWithCountryCodeBR({String message = ''}) {
    return addValidator(message, (val) {
      if (val == null || val.isEmpty) return false;
      final clean = val.replaceAll(_nonDigitRegex, '');
      if (clean.length != 13) return true;
      return !clean.startsWith('55') || clean[4] != '9';
    });
  }

  /// Validates that the string does not contain a run of [maxRepeated] or more
  /// identical consecutive characters.
  ///
  /// [maxRepeated] is the maximum allowed run length (default 3). A run of
  /// exactly [maxRepeated] identical characters triggers an error.
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final password = Field<String>('password')
  ///   .hasNoSequentialRepeatedCharacters(
  ///       maxRepeated: 3,
  ///       message: 'Não use caracteres repetidos em sequência');
  /// ```
  Field<String> hasNoSequentialRepeatedCharacters({
    int maxRepeated = 3,
    String message = '',
  }) {
    return addValidator(message, (val) {
      if (val == null || val.isEmpty) return false;
      final regex = RegExp('(.)\\1{${maxRepeated - 1}}');
      return regex.hasMatch(val);
    });
  }

  /// Validates that the string does not contain ascending or descending
  /// sequential character runs of length [seqLength] or more.
  ///
  /// Detects both character sequences (`abc`, `xyz`) and digit sequences
  /// (`123`, `987`), in both ascending and descending order.
  ///
  /// [seqLength] is the minimum sequential run length that triggers an error
  /// (default 3).
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final password = Field<String>('password')
  ///   .hasNoSequentialCharacters(
  ///       seqLength: 3,
  ///       message: 'Não use sequências como abc ou 123');
  /// ```
  Field<String> hasNoSequentialCharacters({
    int seqLength = 3,
    String message = '',
  }) {
    return addValidator(message, (val) {
      if (val == null || val.isEmpty) return false;
      for (var i = 0; i <= val.length - seqLength; i++) {
        final chunk = val.substring(i, i + seqLength);
        if (_isSequential(chunk)) return true;
      }
      return false;
    });
  }

  /// Validates that the string is a well-formed UUID (any version).
  ///
  /// Format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` (hex, case-insensitive).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final id = Field<String>('id')
  ///   .uuid(message: 'ID inválido');
  /// ```
  Field<String> uuid({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_uuidRegex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is a well-formed UUID v4.
  ///
  /// UUID v4 has `4` as the version digit and `[89ab]` as the variant nibble.
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final sessionId = Field<String>('sessionId')
  ///   .uuidv4(message: 'Session ID deve ser UUID v4');
  /// ```
  Field<String> uuidv4({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_uuidv4Regex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is a well-formed UUID v6.
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  Field<String> uuidv6({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_uuidv6Regex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is a well-formed UUID v7.
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  Field<String> uuidv7({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_uuidv7Regex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is a well-formed GUID (alias for [uuidv4]).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  Field<String> guid({String message = '', bool exposed = false}) {
    return uuidv4(message: message, exposed: exposed);
  }

  /// Validates that the string is a well-formed CUID identifier.
  ///
  /// Format: starts with `c` followed by 24 lowercase alphanumeric characters.
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  Field<String> cuid({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_cuidRegex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is a well-formed CUID2 identifier.
  ///
  /// Format: starts with a lowercase letter followed by 23 lowercase
  /// alphanumeric characters.
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  Field<String> cuid2({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_cuid2Regex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is a well-formed Nano ID of the given [size].
  ///
  /// [size] is the expected character count (default 21). Allowed characters
  /// are `A–Z`, `a–z`, `0–9`, `_`, `-`.
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final id = Field<String>('id')
  ///   .nanoid(size: 21, message: 'ID inválido');
  /// ```
  Field<String> nanoid({
    int size = 21,
    String message = '',
    bool exposed = false,
  }) {
    final regex = RegExp('^[A-Za-z0-9_-]{$size}\$');
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !regex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is a well-formed ULID (Universally Unique
  /// Lexicographically Sortable Identifier).
  ///
  /// Format: 26 characters from the Crockford Base32 alphabet.
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  Field<String> ulid({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_ulidRegex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is a date in `YYYY-MM-DD` format.
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final birthDate = Field<String>('birthDate')
  ///   .date(message: 'Use o formato YYYY-MM-DD');
  /// ```
  Field<String> date({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_dateRegex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is a time in `HH:mm:ss` format with optional
  /// milliseconds (e.g. `14:30:00` or `14:30:00.123`).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  Field<String> time({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_timeRegex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is an ISO 8601 datetime
  /// (e.g. `2024-06-01T14:30:00Z`).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  Field<String> datetime({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_datetimeRegex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is an ISO date in `YYYY-MM-DD` format.
  ///
  /// Alias for [date].
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  Field<String> isoDate({String message = '', bool exposed = false}) {
    return date(message: message, exposed: exposed);
  }

  /// Validates that the string is an ISO time with optional timezone offset
  /// (e.g. `14:30:00Z` or `14:30:00+03:00`).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  Field<String> isoTime({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_isoTimeRegex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is an ISO 8601 datetime. Alias for [datetime].
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  Field<String> isoDatetime({String message = '', bool exposed = false}) {
    return datetime(message: message, exposed: exposed);
  }

  /// Validates that the string is an ISO 8601 duration
  /// (e.g. `P1Y2M3DT4H5M6S`).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  Field<String> isoDuration({String message = '', bool exposed = false}) {
    return addValidator(message, (val) {
      if (val == null || val.isEmpty) return false;
      return !_isoDurationRegex.hasMatch(val) || val.length < 3;
    }, exposedMessage: exposed);
  }

  /// Validates that the string is an absolute HTTP or HTTPS URL.
  ///
  /// The scheme (`http://` or `https://`) is required.
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final webhook = Field<String>('webhookUrl')
  ///   .httpUrl(message: 'Informe uma URL HTTP/HTTPS válida');
  /// ```
  Field<String> httpUrl({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_httpUrlRegex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is a well-formed hostname (e.g. `example.com`).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  Field<String> hostname({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_hostnameRegex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is a valid IPv4 address (e.g. `192.168.0.1`).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  Field<String> ipv4({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_ipv4Regex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is a valid IPv6 address.
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  Field<String> ipv6({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_ipv6Regex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is a valid MAC address, with colons or hyphens
  /// (e.g. `00:1A:2B:3C:4D:5E` or `00-1A-2B-3C-4D-5E`).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  Field<String> mac({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_macRegex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is an IPv4 CIDR notation address
  /// (e.g. `192.168.0.0/24`).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  Field<String> cidrv4({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_cidrv4Regex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is an IPv6 CIDR notation address
  /// (e.g. `2001:db8::/32`).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  Field<String> cidrv6({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_cidrv6Regex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is a valid standard base64 encoded string.
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  Field<String> base64({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_base64Regex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is a valid URL-safe base64 encoded string
  /// (uses `-` and `_` instead of `+` and `/`).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  Field<String> base64url({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_base64urlRegex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string contains only hexadecimal characters (0–9, a–f,
  /// A–F).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final color = Field<String>('hexColor')
  ///   .hex(message: 'Valor hexadecimal inválido');
  /// ```
  Field<String> hex({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_hexRegex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string is a well-formed JSON Web Token
  /// (`header.payload.signature`, each part base64url-encoded).
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  Field<String> jwt({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val.isNotEmpty && !_jwtRegex.hasMatch(val),
      exposedMessage: exposed,
    );
  }

  /// Validates that the string contains at least one emoji character.
  ///
  /// Detects emoji from common Unicode blocks (Emoticons, Miscellaneous Symbols,
  /// Mahjong/Domino tiles, Enclosed Alphanumeric Supplement).
  ///
  /// [message] is the error string shown when no emoji is found.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final reaction = Field<String>('reaction')
  ///   .emoji(message: 'Adicione ao menos um emoji');
  /// ```
  Field<String> emoji({String message = '', bool exposed = false}) {
    return addValidator(message, (val) {
      if (val == null || val.isEmpty) return false;
      return !val.runes.any(
        (r) =>
            (r >= 0x1F300 && r <= 0x1FAFF) ||
            (r >= 0x2600 && r <= 0x27BF) ||
            (r >= 0x1F000 && r <= 0x1F02F) ||
            (r >= 0x1F0A0 && r <= 0x1F0FF),
      );
    }, exposedMessage: exposed);
  }

  /// Validates that the string is a valid cryptographic hash for the given
  /// [algorithm].
  ///
  /// Supported algorithms: `md5` (32), `sha1` (40), `sha224` (56),
  /// `sha256` (64), `sha384` (96), `sha512` (128). The value must be
  /// a hexadecimal string of the expected length.
  ///
  /// [algorithm] is the hash algorithm name (case-insensitive).
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final checksum = Field<String>('checksum')
  ///   .hash('sha256', message: 'Checksum SHA-256 inválido');
  /// ```
  Field<String> hash(
    String algorithm, {
    String message = '',
    bool exposed = false,
  }) {
    const lengths = {
      'md5': 32,
      'sha1': 40,
      'sha224': 56,
      'sha256': 64,
      'sha384': 96,
      'sha512': 128,
    };
    final expectedLength = lengths[algorithm.toLowerCase()];
    return addValidator(message, (val) {
      if (val == null || val.isEmpty) return false;
      if (!_hexRegex.hasMatch(val)) return true;
      if (expectedLength != null && val.length != expectedLength) return true;
      return false;
    }, exposedMessage: exposed);
  }

  /// Validates that all characters in the string are uppercase.
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final countryCode = Field<String>('country')
  ///   .uppercase(message: 'Código do país deve ser maiúsculo (ex: BR)');
  /// ```
  Field<String> uppercase({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val != val.toUpperCase(),
      exposedMessage: exposed,
    );
  }

  /// Validates that all characters in the string are lowercase.
  ///
  /// [message] is the error string shown when validation fails.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final slug = Field<String>('slug')
  ///   .lowercase(message: 'Slug deve ser minúsculo');
  /// ```
  Field<String> lowercase({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val != val.toLowerCase(),
      exposedMessage: exposed,
    );
  }

  /// Applies a dynamic CPF/CNPJ mask that switches format based on the
  /// number of digits typed.
  ///
  /// - Up to 11 digits: formats as CPF `###.###.###-##`
  /// - 12–14 digits: formats as CNPJ `##.###.###/####-##`
  ///
  /// [removeMaskOnJson] controls whether punctuation is stripped when
  /// [Field.jsonValue] is accessed (default `true`).
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final document = Field<String>('document')
  ///   .maskCPFOrCNPJ()
  ///   .validCPFOrCNPJ(message: 'Documento inválido');
  ///
  /// document.value = '12345678909';
  /// print(document.value); // '123.456.789-09'
  /// ```
  Field<String> maskCPFOrCNPJ({bool removeMaskOnJson = true}) {
    if (removeMaskOnJson) {
      transformToJson((val) {
        if (val is String) return val.replaceAll(_nonDigitRegex, '');
        return val;
      });
    }
    onValueChanged = (oldValue, newValue) {
      if (newValue == null) return;
      final clean = newValue.replaceAll(_nonDigitRegex, '');
      String formatted;
      if (clean.length <= 11) {
        final buffer = StringBuffer();
        for (var i = 0; i < clean.length; i++) {
          if (i == 3 || i == 6) buffer.write('.');
          if (i == 9) buffer.write('-');
          buffer.write(clean[i]);
        }
        formatted = buffer.toString();
      } else {
        final limitClean = clean.substring(0, clean.length.clamp(0, 14));
        final buffer = StringBuffer();
        for (var i = 0; i < limitClean.length; i++) {
          if (i == 2 || i == 5) buffer.write('.');
          if (i == 8) buffer.write('/');
          if (i == 12) buffer.write('-');
          buffer.write(limitClean[i]);
        }
        formatted = buffer.toString();
      }
      if (newValue != formatted) {
        value = formatted;
      }
    };
    return this;
  }

  bool _isSequential(String chunk) {
    if (chunk.isEmpty) return false;
    final codes = chunk.runes.toList();
    var ascending = true;
    var descending = true;
    for (var i = 1; i < codes.length; i++) {
      if (codes[i] != codes[i - 1] + 1) ascending = false;
      if (codes[i] != codes[i - 1] - 1) descending = false;
    }
    return ascending || descending;
  }
}
