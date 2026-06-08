import '../core.dart';

/// Validation extensions for [Field<num>] (covers both `int` and `double`).
///
/// All methods return `this` to allow method chaining on the field builder.
extension NumFieldValidators on Field<num> {
  /// Validates that the value is not `null`.
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final quantity = Field<num>('quantity')
  ///   .required(message: 'Informe a quantidade');
  /// ```
  Field<num> required({String message = '', bool exposed = false}) {
    return addValidator(message, (val) => val == null, exposedMessage: exposed);
  }

  /// Validates that the value is greater than or equal to [minValue].
  ///
  /// [minValue] is the minimum allowed value (inclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final price = Field<num>('price')
  ///   .min(0.01, message: 'Preço deve ser maior que zero');
  /// ```
  Field<num> min(num minValue, {String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val < minValue,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is less than or equal to [maxValue].
  ///
  /// [maxValue] is the maximum allowed value (inclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final discount = Field<num>('discount')
  ///   .max(100, message: 'Desconto não pode exceder 100%');
  /// ```
  Field<num> max(num maxValue, {String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val > maxValue,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is within [[minValue], [maxValue]] inclusive.
  ///
  /// [minValue] is the minimum allowed value (inclusive).
  /// [maxValue] is the maximum allowed value (inclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final rating = Field<num>('rating')
  ///   .range(1, 5, message: 'Avaliação deve ser entre 1 e 5');
  /// ```
  Field<num> range(
    num minValue,
    num maxValue, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && (val < minValue || val > maxValue),
    );
  }

  /// Validates that the value is strictly greater than zero (> 0).
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final amount = Field<num>('amount')
  ///   .positive(message: 'Valor deve ser positivo');
  /// ```
  Field<num> positive({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val <= 0,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is strictly less than zero (< 0).
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final adjustment = Field<num>('adjustment')
  ///   .negative(message: 'Ajuste deve ser negativo');
  /// ```
  Field<num> negative({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val >= 0,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is not zero (≠ 0).
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final divisor = Field<num>('divisor')
  ///   .nonZero(message: 'Divisor não pode ser zero');
  /// ```
  Field<num> nonZero({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val == 0,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is strictly greater than [minValue] (>).
  ///
  /// [minValue] is the lower bound (exclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final score = Field<num>('score')
  ///   .greaterThan(0, message: 'Pontuação deve ser maior que 0');
  /// ```
  Field<num> greaterThan(
    num minValue, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && val <= minValue,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is strictly less than [maxValue] (<).
  ///
  /// [maxValue] is the upper bound (exclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final speed = Field<num>('speed')
  ///   .lessThan(300, message: 'Velocidade deve ser menor que 300');
  /// ```
  Field<num> lessThan(
    num maxValue, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && val >= maxValue,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is zero or greater (≥ 0).
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final stock = Field<num>('stock')
  ///   .nonnegative(message: 'Estoque não pode ser negativo');
  /// ```
  Field<num> nonnegative({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val < 0,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is an exact multiple of [divisor].
  ///
  /// [divisor] is the number the value must be divisible by.
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final quantity = Field<num>('quantity')
  ///   .multipleOf(5, message: 'Quantidade deve ser múltiplo de 5');
  /// ```
  Field<num> multipleOf(
    num divisor, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && val % divisor != 0,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is an exact multiple of [stepValue].
  ///
  /// Alias for [multipleOf] with a name more familiar in form/slider contexts.
  ///
  /// [stepValue] is the step size the value must align to.
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final volume = Field<num>('volume')
  ///   .step(0.5, message: 'Volume deve ser múltiplo de 0.5');
  /// ```
  Field<num> step(num stepValue, {String message = '', bool exposed = false}) {
    return multipleOf(stepValue, message: message, exposed: exposed);
  }
}

/// Validation extensions for [Field<int>].
///
/// All methods return `this` to allow method chaining on the field builder.
extension IntFieldValidators on Field<int> {
  /// Validates that the value is not `null`.
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final age = Field<int>('age')
  ///   .required(message: 'Informe sua idade');
  /// ```
  Field<int> required({String message = '', bool exposed = false}) {
    return addValidator(message, (val) => val == null, exposedMessage: exposed);
  }

  /// Validates that the value is greater than or equal to [minValue].
  ///
  /// [minValue] is the minimum allowed value (inclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final age = Field<int>('age')
  ///   .min(18, message: 'Idade mínima: 18 anos');
  /// ```
  Field<int> min(int minValue, {String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val < minValue,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is less than or equal to [maxValue].
  ///
  /// [maxValue] is the maximum allowed value (inclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final age = Field<int>('age')
  ///   .max(120, message: 'Idade máxima: 120 anos');
  /// ```
  Field<int> max(int maxValue, {String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val > maxValue,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is within [[minValue], [maxValue]] inclusive.
  ///
  /// [minValue] is the minimum allowed value (inclusive).
  /// [maxValue] is the maximum allowed value (inclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final installments = Field<int>('installments')
  ///   .range(1, 12, message: 'Parcelas: de 1 a 12');
  /// ```
  Field<int> range(
    int minValue,
    int maxValue, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && (val < minValue || val > maxValue),
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is strictly greater than zero (> 0).
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final count = Field<int>('count')
  ///   .positive(message: 'Quantidade deve ser positiva');
  /// ```
  Field<int> positive({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val <= 0,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is strictly less than zero (< 0).
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final delta = Field<int>('delta')
  ///   .negative(message: 'Delta deve ser negativo');
  /// ```
  Field<int> negative({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val >= 0,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is even (divisible by 2).
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final columns = Field<int>('columns')
  ///   .even(message: 'Número de colunas deve ser par');
  /// ```
  Field<int> even({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val % 2 != 0,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is odd (not divisible by 2).
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final players = Field<int>('players')
  ///   .odd(message: 'Número de jogadores deve ser ímpar');
  /// ```
  Field<int> odd({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val % 2 == 0,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is strictly greater than [minValue] (>).
  ///
  /// [minValue] is the lower bound (exclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final level = Field<int>('level')
  ///   .greaterThan(0, message: 'Nível deve ser maior que 0');
  /// ```
  Field<int> greaterThan(
    int minValue, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && val <= minValue,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is strictly less than [maxValue] (<).
  ///
  /// [maxValue] is the upper bound (exclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final page = Field<int>('page')
  ///   .lessThan(totalPages, message: 'Página inválida');
  /// ```
  Field<int> lessThan(
    int maxValue, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && val >= maxValue,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is zero or greater (≥ 0).
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final index = Field<int>('index')
  ///   .nonnegative(message: 'Índice não pode ser negativo');
  /// ```
  Field<int> nonnegative({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val < 0,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is an exact multiple of [divisor].
  ///
  /// [divisor] is the number the value must be divisible by.
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final boxes = Field<int>('boxes')
  ///   .multipleOf(6, message: 'Quantidade deve ser múltiplo de 6');
  /// ```
  Field<int> multipleOf(
    int divisor, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && val % divisor != 0,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is an exact multiple of [stepValue].
  ///
  /// Alias for [multipleOf] with a name more familiar in form/stepper contexts.
  ///
  /// [stepValue] is the step size the value must align to.
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final quantity = Field<int>('quantity')
  ///   .step(10, message: 'Quantidade deve ser múltiplo de 10');
  /// ```
  Field<int> step(int stepValue, {String message = '', bool exposed = false}) {
    return multipleOf(stepValue, message: message, exposed: exposed);
  }
}

/// Validation extensions for [Field<double>].
///
/// All methods return `this` to allow method chaining on the field builder.
extension DoubleFieldValidators on Field<double> {
  /// Validates that the value is not `null`.
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final price = Field<double>('price')
  ///   .required(message: 'Informe o preço');
  /// ```
  Field<double> required({String message = '', bool exposed = false}) {
    return addValidator(message, (val) => val == null, exposedMessage: exposed);
  }

  /// Validates that the value is greater than or equal to [minValue].
  ///
  /// [minValue] is the minimum allowed value (inclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final price = Field<double>('price')
  ///   .min(0.01, message: 'Preço mínimo: R$ 0,01');
  /// ```
  Field<double> min(
    double minValue, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && val < minValue,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is less than or equal to [maxValue].
  ///
  /// [maxValue] is the maximum allowed value (inclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final discount = Field<double>('discount')
  ///   .max(1.0, message: 'Desconto máximo: 100%');
  /// ```
  Field<double> max(
    double maxValue, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && val > maxValue,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is within [[minValue], [maxValue]] inclusive.
  ///
  /// [minValue] is the minimum allowed value (inclusive).
  /// [maxValue] is the maximum allowed value (inclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final rate = Field<double>('rate')
  ///   .range(0.0, 1.0, message: 'Taxa deve estar entre 0 e 1');
  /// ```
  Field<double> range(
    double minValue,
    double maxValue, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && (val < minValue || val > maxValue),
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is strictly greater than zero (> 0.0).
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final weight = Field<double>('weight')
  ///   .positive(message: 'Peso deve ser positivo');
  /// ```
  Field<double> positive({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val <= 0,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is strictly less than zero (< 0.0).
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final offset = Field<double>('offset')
  ///   .negative(message: 'Offset deve ser negativo');
  /// ```
  Field<double> negative({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val >= 0,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is strictly greater than [minValue] (>).
  ///
  /// [minValue] is the lower bound (exclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final amount = Field<double>('amount')
  ///   .greaterThan(0.0, message: 'Valor deve ser maior que zero');
  /// ```
  Field<double> greaterThan(
    double minValue, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && val <= minValue,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is strictly less than [maxValue] (<).
  ///
  /// [maxValue] is the upper bound (exclusive).
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final probability = Field<double>('probability')
  ///   .lessThan(1.0, message: 'Probabilidade deve ser menor que 1');
  /// ```
  Field<double> lessThan(
    double maxValue, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && val >= maxValue,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is zero or greater (≥ 0.0).
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final balance = Field<double>('balance')
  ///   .nonnegative(message: 'Saldo não pode ser negativo');
  /// ```
  Field<double> nonnegative({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && val < 0,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is an exact multiple of [divisor].
  ///
  /// [divisor] is the number the value must be divisible by.
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final price = Field<double>('price')
  ///   .multipleOf(0.5, message: 'Valor deve ser múltiplo de R$ 0,50');
  /// ```
  Field<double> multipleOf(
    double divisor, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && val % divisor != 0,
      exposedMessage: exposed,
    );
  }

  /// Validates that the value is an exact multiple of [stepValue].
  ///
  /// Alias for [multipleOf] with a name more familiar in form/slider contexts.
  ///
  /// [stepValue] is the step size the value must align to.
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final volume = Field<double>('volume')
  ///   .step(0.25, message: 'Volume deve ser múltiplo de 0.25');
  /// ```
  Field<double> step(
    double stepValue, {
    String message = '',
    bool exposed = false,
  }) {
    return multipleOf(stepValue, message: message, exposed: exposed);
  }
}
