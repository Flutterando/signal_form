import 'dart:async';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/widgets.dart' show FocusNode, Scrollable;

final RegExp _maskRegExp = RegExp(r'[^0-9a-zA-Z]');

// =============================================================================
// 1. FORM TRACKER - STATE AND TREE MANAGEMENT
// =============================================================================

/// Context for building forms, avoiding static state issues
class FormBuildContext {
  final List<Field> fields = [];
  final List<String> pathStack = [];

  String buildFullPath(String localName) {
    if (pathStack.isEmpty) return localName;
    return '${pathStack.join('.')}.$localName';
  }
}

class FormTracker {
  static FormBuildContext? _currentContext;
  static bool pauseTracking = false;

  static void register(Field field) {
    if (pauseTracking) return;
    _currentContext?.fields.add(field);
  }

  static String buildFullPath(String localName) {
    return _currentContext?.buildFullPath(localName) ?? localName;
  }

  static void pushPath(String name) {
    _currentContext?.pathStack.add(name);
  }

  static void popPath() {
    _currentContext?.pathStack.removeLast();
  }

  static T runInContext<T>(T Function() builder) {
    final previousContext = _currentContext;
    _currentContext = FormBuildContext();
    try {
      final result = builder();
      return result;
    } finally {
      _currentContext = previousContext;
    }
  }

  static List<Field> getCapturedFields() {
    return List.from(_currentContext?.fields ?? []);
  }
}

/// Defines a named group of fields within a [formCtrl] builder, scoping
/// all [Field]s created inside [builder] under the given [name] prefix.
///
/// Every field constructed inside [builder] receives a dot-notation path
/// prefixed with [name] (e.g. a field named `'city'` inside a group
/// named `'address'` becomes `'address.city'`). Groups can be nested
/// arbitrarily deep.
///
/// [name] is the path segment to prepend to every nested field.
/// [builder] is a function that creates and returns the grouped fields —
/// any return type is accepted (record, class, list, etc.).
///
/// Returns the value produced by [builder], typically a record or object
/// holding the created [Field] instances.
///
/// Example:
/// ```dart
/// final form = formCtrl(() =>
///   final address = formGroup('address', () => (
///     street: Field<String>('street'),
///     city:   Field<String>('city'),
///   ));
/// ```
T formGroup<T>(String name, T Function() builder) {
  FormTracker.pushPath(name);
  try {
    return builder();
  } finally {
    FormTracker.popPath();
  }
}

/// A function type used inside conditional validators to look up another
/// field's current value by its dot-notation path.
///
/// Used as the parameter type for the [Field.applyWhen] condition callback,
/// allowing validators to depend on values from sibling fields.
///
/// Example:
/// ```dart
/// field.applyWhen(
///   (valueOf) => valueOf<bool>('hasDiscount').value == true,
///   (f) => f.addValidator('Desconto inválido', (v) => v == null),
/// );
/// ```
typedef ValueOf = Field<T> Function<T>(String path);

// =============================================================================
// 2. VALIDATION MODE ENUM
// =============================================================================

/// Controls when a [Field] runs its validators automatically.
///
/// Configure this on a field via [Field.validationMode].
enum ValidationMode {
  /// Validates on every value change (default).
  ///
  /// Each time [Field.value] is set to a different value, validation is
  /// triggered immediately (or after the debounce delay if configured).
  onChange,

  /// Validates only when [FormController.trigger] or [FormController.submit]
  /// is called explicitly.
  ///
  /// Use this mode for fields that should not show errors while the user
  /// is still typing.
  onSubmit,

  /// Validates once after the field loses focus for the first time.
  ///
  /// Calls [Field.touch] internally; subsequent changes re-validate on
  /// every change once the field has been touched.
  onBlur,
}

// =============================================================================
// 3. FIELD CLASS - CORE FORM FIELD
// =============================================================================

/// A reactive form field that holds a typed value, runs validators,
/// and notifies listeners whenever its state changes.
///
/// [T] is the value type (e.g. `String`, `int`, `DateTime`).
///
/// Build the field's behavior through the fluent API:
/// [validationMode], [debounce], [mask], [addValidator],
/// [addValidatorAsync], [transformToJson], [apply], [applyWhen],
/// [applyEach].
///
/// Observe lifecycle events through the callback fields:
/// [onValueChanged], [onValidationStart], [onValidationEnd],
/// [onAsyncValidationStart], [onAsyncValidationEnd].
///
/// Always call [dispose] when the field is no longer used to release
/// the debounce timer and the listener list.
class Field<T> extends ChangeNotifier {
  /// The resolved dot-notation path of this field (e.g. `'address.city'`).
  ///
  /// Set automatically by the constructor based on the active [formGroup]
  /// scope at construction time.
  late final String name;
  T? _value;
  T? _initialValue;

  /// The [FormController] this field belongs to, set automatically when
  /// the field is captured by [formCtrl].
  FormController<dynamic>? form;

  /// Optional [FocusNode] used by [invalidate] and [FormController.trigger]
  /// to request focus or scroll to this field when validation fails.
  FocusNode? focusNode;

  bool _isLoading = false;
  String? _error;
  bool _isDirty = false;
  bool _isTouched = false;

  // Version control to prevent race conditions in async validation
  int _validationVersion = 0;

  // Debounce support
  Duration? _debounceDuration;
  Timer? _debounceTimer;

  // Validation mode
  ValidationMode _validationMode = ValidationMode.onChange;

  bool Function(ValueOf valueOf)? _activeCondition;

  final List<
    ({
      String message,
      String Function(T?)? dynamicMessage,
      bool Function(T?) hasError,
      bool exposedMessage,
    })
  >
  _syncValidators = [];

  final List<
    ({
      String message,
      String Function(T?)? dynamicMessage,
      Future<bool> Function(T?) hasError,
    })
  >
  _asyncValidators = [];

  dynamic Function(T?)? _toJsonTransformer;
  String? _maskPattern;

  late final List<String> pathSegments;

  /// Called whenever [value] changes to a different value.
  ///
  /// Receives the previous value as [oldValue] and the new value as [newValue].
  ///
  /// Example:
  /// ```dart
  /// field.onValueChanged = (old, next) {
  ///   print('changed from $old to $next');
  /// };
  /// ```
  void Function(T? oldValue, T? newValue)? onValueChanged;

  /// Called at the very start of every validation cycle, before sync
  /// validators run.
  ///
  /// Fires for both [validate] and [validateAsync] calls.
  ///
  /// Example:
  /// ```dart
  /// field.onValidationStart = () => setState(() => isValidating = true);
  /// ```
  void Function()? onValidationStart;

  /// Called at the end of every validation cycle, after all validators
  /// (sync and async) have finished.
  ///
  /// [isValid] is `true` if the field passed all validators.
  /// [error] is the first error message, or `null` if valid.
  ///
  /// Example:
  /// ```dart
  /// field.onValidationEnd = (isValid, error) {
  ///   print(isValid ? 'ok' : 'error: $error');
  /// };
  /// ```
  void Function(bool isValid, String? error)? onValidationEnd;

  /// Called immediately before the async validators are awaited, but only
  /// when there is at least one async validator and all sync validators
  /// have already passed.
  ///
  /// Example:
  /// ```dart
  /// field.onAsyncValidationStart = () => showSpinner();
  /// ```
  void Function()? onAsyncValidationStart;

  /// Called immediately after all async validators finish, but only when
  /// async validators were actually executed.
  ///
  /// [isValid] is `true` if all async validators passed.
  /// [error] is the first async error message, or `null` if valid.
  ///
  /// Example:
  /// ```dart
  /// field.onAsyncValidationEnd = (isValid, error) => hideSpinner();
  /// ```
  void Function(bool isValid, String? error)? onAsyncValidationEnd;

  /// Creates a field with [localName] as its local path segment and an
  /// optional [initialValue].
  ///
  /// When constructed inside a [formCtrl] builder (or nested [formGroup]
  /// calls), the full dot-notation path is resolved automatically —
  /// e.g. a field named `'city'` inside a `formGroup('address', ...)` will
  /// have [name] equal to `'address.city'`.
  ///
  /// [initialValue] sets the starting [value] and acts as the reference
  /// value for [reset] and [isDirty] comparisons.
  ///
  /// Example:
  /// ```dart
  /// final username = Field<String>('username', 'alice');
  /// print(username.value);        // 'alice'
  /// print(username.initialValue); // 'alice'
  /// username.value = 'bob';
  /// print(username.isDirty);      // true
  /// username.reset();
  /// print(username.value);        // 'alice'
  /// ```
  Field(String localName, [T? initialValue]) {
    name = FormTracker.buildFullPath(localName);
    pathSegments = name.split('.');
    FormTracker.register(this);
    _initialValue = initialValue;
    if (initialValue != null) {
      _value = initialValue;
    }
  }

  /// The current value of the field.
  ///
  /// When a [mask] pattern is configured, the returned value is the masked
  /// string (e.g. `'(11) 9999-9999'`). Use [jsonValue] to access the
  /// unmasked representation for serialization.
  T? get value => _value;

  /// Whether an async validator is currently running for this field.
  ///
  /// Becomes `true` after [onAsyncValidationStart] fires and returns to
  /// `false` once all async validators resolve.
  bool get isLoading => _isLoading;

  /// The current validation error message, or `null` if the field is valid
  /// or has not been validated yet.
  String? get error => _error;

  /// Whether the current [value] differs from [initialValue].
  ///
  /// Resets to `false` when [reset] is called.
  bool get isDirty => _isDirty;

  /// Whether [touch] has been called on this field at least once.
  ///
  /// Typically set to `true` when the user leaves the field (blur event).
  /// Resets to `false` when [reset] is called.
  bool get isTouched => _isTouched;

  /// The value this field was initialized with, used as the baseline for
  /// [isDirty] comparisons and restored by [reset].
  T? get initialValue => _initialValue;

  /// The list of sync validators registered with `exposedMessage: true`,
  /// each paired with its current validity state.
  ///
  /// Useful for rendering inline password-strength checklists or similar
  /// UIs that show individual rule status.
  ///
  /// Returns a list of records with [message] and [isValid] fields.
  ///
  /// Example:
  /// ```dart
  /// final password = Field<String>('password')
  ///   ..addValidator('Min 8 chars',  (v) => v != null && v.length < 8,  exposedMessage: true)
  ///   ..addValidator('Has uppercase',(v) => v != null && !v.contains(RegExp(r'[A-Z]')), exposedMessage: true);
  ///
  /// for (final rule in password.exposedRules) {
  ///   print('${rule.isValid ? '✓' : '✗'} ${rule.message}');
  /// }
  /// ```
  List<({String message, bool isValid})> get exposedRules {
    return _syncValidators
        .where((v) => v.exposedMessage)
        .map((v) => (message: v.message, isValid: !v.hasError(value)))
        .toList();
  }

  /// Manually overrides the loading state of the field.
  ///
  /// Notifies listeners if the value changes. Normally managed internally
  /// by [validateAsync]; use this only when controlling loading state
  /// from outside the validation cycle.
  set isLoading(bool val) {
    if (_isLoading != val) {
      _isLoading = val;
      _notifyIfMounted();
    }
  }

  bool _isDisposed = false;

  void _notifyIfMounted() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Sets the field's value, applies mask if configured, updates [isDirty],
  /// notifies listeners, and triggers validation based on [ValidationMode].
  ///
  /// If [val] equals the current [value], the setter is a no-op and
  /// listeners are not notified.
  ///
  /// When a mask pattern is set via [mask], [val] is automatically formatted
  /// before being stored. Setting [val] to `null` clears the field.
  ///
  /// Example:
  /// ```dart
  /// final phone = Field<String>('phone')..mask('(##) #####-####');
  /// phone.value = '11999999999';
  /// print(phone.value); // '(11) 99999-9999'
  /// ```
  set value(T? val) {
    final oldValue = _value;
    T? newValue;

    if (val != null && val is String && _maskPattern != null) {
      newValue = _applyMask(val, _maskPattern!) as T;
    } else {
      newValue = val;
    }

    if (_value != newValue) {
      _value = newValue;
      _isDirty = newValue != _initialValue;

      // Notify UI immediately
      _notifyIfMounted();

      // Trigger lifecycle callback
      onValueChanged?.call(oldValue, newValue);

      // Invalidate form cache
      form?._invalidateCache();

      // Handle validation based on mode
      if (_validationMode == ValidationMode.onChange) {
        _scheduleValidation();
      }
    }
  }

  void _scheduleValidation() {
    if (_debounceDuration != null) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(_debounceDuration!, () {
        validateAsync();
      });
    } else {
      validateAsync();
    }
  }

  /// Marks the field as touched and, if [ValidationMode.onBlur] is active,
  /// triggers validation immediately.
  ///
  /// Call this in the `onBlur` / `focusNode.addListener` callback of your
  /// input widget. Has no effect if the field is already touched.
  ///
  /// Example:
  /// ```dart
  /// final email = Field<String>('email')..validationMode(ValidationMode.onBlur);
  /// focusNode.addListener(() {
  ///   if (!focusNode.hasFocus) email.touch();
  /// });
  /// ```
  void touch() {
    if (!_isTouched) {
      _isTouched = true;
      if (_validationMode == ValidationMode.onBlur) {
        validateAsync();
      }
      _notifyIfMounted();
    }
  }

  void _markAsTouched() {
    if (!_isTouched) {
      _isTouched = true;
      _notifyIfMounted();
    }
  }

  /// Resets the field to its [initialValue] and clears all validation state.
  ///
  /// After reset: [value] == [initialValue], [error] is `null`,
  /// [isDirty] is `false`, [isTouched] is `false`, [isLoading] is `false`.
  /// Any pending debounce timer is also cancelled.
  ///
  /// Example:
  /// ```dart
  /// final name = Field<String>('name', 'Alice');
  /// name.value = 'Bob';
  /// print(name.isDirty); // true
  /// name.reset();
  /// print(name.value);   // 'Alice'
  /// print(name.isDirty); // false
  /// ```
  void reset() {
    _debounceTimer?.cancel();
    _value = _initialValue;
    _error = null;
    _isDirty = false;
    _isTouched = false;
    _isLoading = false;
    _validationVersion++;
    _notifyIfMounted();
  }

  /// Sets the [ValidationMode] that controls when validators run automatically.
  ///
  /// [mode] determines when validation is triggered — on every change,
  /// only on submit, or on blur. Defaults to [ValidationMode.onChange].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final email = Field<String>('email')
  ///   ..validationMode(ValidationMode.onBlur)
  ///   ..addValidator('Email inválido', (v) => !v!.contains('@'));
  /// ```
  Field<T> validationMode(ValidationMode mode) {
    _validationMode = mode;
    return this;
  }

  /// Adds a debounce delay before validation runs after a value change.
  ///
  /// When [ValidationMode.onChange] is active, each new value assignment
  /// cancels the previous pending validation and restarts a new timer with
  /// [duration]. Only the last value in a rapid-input burst is validated,
  /// reducing unnecessary API calls.
  ///
  /// [duration] is the idle time to wait after the last change before
  /// validators are executed.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final search = Field<String>('search')
  ///   ..debounce(const Duration(milliseconds: 300))
  ///   ..addValidatorAsync('Sem resultados', (v) async {
  ///     final results = await api.search(v);
  ///     return results.isEmpty;
  ///   });
  /// ```
  Field<T> debounce(Duration duration) {
    _debounceDuration = duration;
    return this;
  }

  /// Applies an input mask to the field using [pattern], formatting the value
  /// as the user types.
  ///
  /// [pattern] uses `#` as a placeholder for each alphanumeric digit and any
  /// other character as a literal separator (e.g. `'(##) #####-####'` for
  /// Brazilian phone numbers, `'##/##/####'` for dates).
  ///
  /// [removeMaskOnJson] controls whether the mask separators are stripped
  /// when [jsonValue] is accessed. Defaults to `true`, so `toJson()` returns
  /// only the raw digits (e.g. `'11999999999'` instead of `'(11) 99999-9999'`).
  /// Set to `false` to keep the formatted string in the JSON output.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final phone = Field<String>('phone')
  ///   ..mask('(##) #####-####');
  ///
  /// phone.value = '11999999999';
  /// print(phone.value);     // '(11) 99999-9999'
  /// print(phone.jsonValue); // '11999999999'  (mask stripped)
  /// ```
  Field<T> mask(String pattern, {bool removeMaskOnJson = true}) {
    _maskPattern = pattern;
    if (removeMaskOnJson) {
      transformToJson((val) {
        if (val is String) return val.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
        return val;
      });
    } else {
      _toJsonTransformer = null;
    }
    if (_value != null) value = _value;
    return this;
  }

  String _applyMask(String text, String pattern) {
    String cleanText = text.replaceAll(_maskRegExp, '');
    var result = StringBuffer();
    var textIndex = 0;
    for (var i = 0; i < pattern.length; i++) {
      if (textIndex >= cleanText.length) break;
      if (pattern[i] == '#') {
        result.write(cleanText[textIndex]);
        textIndex++;
      } else {
        result.write(pattern[i]);
      }
    }
    return result.toString();
  }

  /// Runs [buildValidators] with this field as the argument, enabling reusable
  /// validator sets to be applied fluently.
  ///
  /// [buildValidators] receives the field instance and should call
  /// [addValidator] / [addValidatorAsync] on it.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// void requiredString(Field<String> f) {
  ///   f.addValidator('Obrigatório', (v) => v == null || v.isEmpty);
  /// }
  ///
  /// final name = Field<String>('name')..apply(requiredString);
  /// ```
  Field<T> apply(void Function(Field<T> self) buildValidators) {
    buildValidators(this);
    return this;
  }

  /// Conditionally applies validators only when [condition] returns `true`.
  ///
  /// [condition] receives a [ValueOf] function to read other fields' values
  /// by their dot-notation path. Validators added inside [buildValidators]
  /// are skipped entirely when [condition] returns `false`.
  ///
  /// [buildValidators] should call [addValidator] / [addValidatorAsync] on
  /// the field; those validators will be wrapped with the condition check.
  ///
  /// Multiple [applyWhen] calls are composed — all conditions must be `true`
  /// for the validators to run.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final form = formCtrl(() {
  ///   final hasCoupon = Field<bool>('hasCoupon');
  ///   final couponCode = Field<String>('couponCode')
  ///     ..applyWhen(
  ///       (valueOf) => valueOf<bool>('hasCoupon').value == true,
  ///       (f) => f.addValidator('Código obrigatório', (v) => v == null || v.isEmpty),
  ///     );
  ///   return (hasCoupon: hasCoupon, couponCode: couponCode);
  /// });
  /// ```
  Field<T> applyWhen(
    bool Function(ValueOf valueOf) condition,
    void Function(Field<T> self) buildValidators,
  ) {
    final previousCondition = _activeCondition;
    _activeCondition = (valueOf) {
      if (previousCondition != null && !previousCondition(valueOf)) {
        return false;
      }
      return condition(valueOf);
    };
    buildValidators(this);
    _activeCondition = previousCondition;
    return this;
  }

  /// Validates each item of an [Iterable] value using per-item validators.
  ///
  /// Use this on a `Field<List<I>>` (or any iterable) to declare validators
  /// that apply to each individual element rather than the collection as a whole.
  /// Validation stops at the first failing item and sets the field's error.
  ///
  /// [I] is the type of each element in the iterable.
  /// [buildValidators] receives a temporary field of type `Field<I>` and should
  /// register validators on it via [addValidator] / [addValidatorAsync].
  /// [formatError] is an optional callback to customize the error message,
  /// receiving the failing item's [index] and the original [itemError] string.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final tags = Field<List<String>>('tags')
  ///   ..applyEach<String>(
  ///     (item) => item.addValidator('Tag muito curta', (v) => v != null && v.length < 2),
  ///     formatError: (i, msg) => 'Tag[$i]: $msg',
  ///   );
  ///
  /// tags.value = ['ok', 'x', 'fine'];
  /// tags.validate();
  /// print(tags.error); // 'Tag[1]: Tag muito curta'
  /// ```
  Field<T> applyEach<I>(
    void Function(Field<I> itemField) buildValidators, {
    String Function(int index, String itemError)? formatError,
  }) {
    FormTracker.pauseTracking = true;
    final dummyField = Field<I>('dummy');
    FormTracker.pauseTracking = false;

    buildValidators(dummyField);

    String lastErrorMessage = '';

    if (dummyField._syncValidators.isNotEmpty) {
      addValidator('', (val) {
        if (val == null || val is! Iterable) return false;
        final iterable = val;
        int i = 0;
        for (final item in iterable) {
          final typedItem = item as I;
          for (var rule in dummyField._syncValidators) {
            if (rule.hasError(typedItem)) {
              final msg = rule.dynamicMessage?.call(typedItem) ?? rule.message;
              lastErrorMessage = formatError?.call(i, msg) ?? msg;
              return true;
            }
          }
          i++;
        }
        return false;
      }, dynamicMessage: (_) => lastErrorMessage);
    }

    if (dummyField._asyncValidators.isNotEmpty) {
      addValidatorAsync('', (val) async {
        if (val == null || val is! Iterable) return false;
        final iterable = val;
        int i = 0;
        for (final item in iterable) {
          final typedItem = item as I;
          for (var rule in dummyField._asyncValidators) {
            if (await rule.hasError(typedItem)) {
              final msg = rule.dynamicMessage?.call(typedItem) ?? rule.message;
              lastErrorMessage = formatError?.call(i, msg) ?? msg;
              return true;
            }
          }
          i++;
        }
        return false;
      }, dynamicMessage: (_) => lastErrorMessage);
    }

    return this;
  }

  /// Registers a synchronous validation rule for this field.
  ///
  /// [message] is the static error string shown when the rule fails.
  /// [hasError] is a predicate that receives the current [value] and returns
  /// `true` when there **is** an error (i.e. the value is invalid).
  /// [exposedMessage] — when `true`, the rule appears in [exposedRules],
  /// allowing the UI to display individual rule status (e.g. password strength).
  /// [dynamicMessage] overrides [message] with a computed string based on the
  /// current value; useful when the error text depends on the value itself.
  ///
  /// Validators are evaluated in registration order and short-circuit on the
  /// first failure — subsequent validators are not called.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final age = Field<int>('age')
  ///   ..addValidator('Obrigatório',  (v) => v == null)
  ///   ..addValidator('Maior de 18', (v) => v != null && v < 18)
  ///   ..addValidator('Menor de 120',(v) => v != null && v > 120);
  /// ```
  Field<T> addValidator(
    String message,
    bool Function(T?) hasError, {
    bool exposedMessage = false,
    String Function(T?)? dynamicMessage,
  }) {
    final activeCondition = _activeCondition;
    _syncValidators.add((
      message: message,
      dynamicMessage: dynamicMessage,
      hasError: (val) {
        if (activeCondition != null) {
          if (form == null) return false;
          Field<O> valueOf<O>(String path) => form!.getField<O>(path);
          if (!activeCondition(valueOf)) return false;
        }
        return hasError(val);
      },
      exposedMessage: exposedMessage,
    ));
    return this;
  }

  /// Registers an asynchronous validation rule for this field.
  ///
  /// Async validators run after all sync validators pass. They are executed
  /// sequentially and short-circuit on the first failure.
  ///
  /// [message] is the static error string shown when the rule fails.
  /// [hasError] is an async predicate that returns `true` when there **is**
  /// an error (e.g. a username already taken confirmed by an API call).
  /// [exposedMessage] behaves the same as in [addValidator].
  /// [dynamicMessage] overrides [message] with a computed string.
  ///
  /// Race conditions are handled automatically — if the field's value changes
  /// while an async validator is running, the stale result is discarded.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final username = Field<String>('username')
  ///   ..addValidator('Obrigatório', (v) => v == null || v.isEmpty)
  ///   ..addValidatorAsync('Username já em uso', (v) async {
  ///     final exists = await userRepository.exists(v!);
  ///     return exists; // true = error
  ///   });
  /// ```
  Field<T> addValidatorAsync(
    String message,
    Future<bool> Function(T?) hasError, {
    bool exposedMessage = false,
    String Function(T?)? dynamicMessage,
  }) {
    final activeCondition = _activeCondition;
    _asyncValidators.add((
      message: message,
      dynamicMessage: dynamicMessage,
      hasError: (val) async {
        if (activeCondition != null) {
          if (form == null) return false;
          Field<O> valueOf<O>(String path) => form!.getField<O>(path);
          if (!activeCondition(valueOf)) return false;
        }
        return await hasError(val);
      },
    ));
    return this;
  }

  /// Sets a custom serialization function used when this field's value is
  /// included in [FormController.toJson].
  ///
  /// [transformer] receives the current [value] and returns any JSON-compatible
  /// type. Use this to convert domain objects (e.g. `DateTime`, enums) into
  /// their serialized form, or to apply custom formatting.
  ///
  /// Note: calling [mask] with `removeMaskOnJson: true` (the default) sets
  /// this transformer automatically.
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final birthDate = Field<DateTime>('birthDate')
  ///   ..transformToJson((v) => v?.toIso8601String().substring(0, 10));
  ///
  /// birthDate.value = DateTime(1990, 3, 15);
  /// // form.toJson() → {'birthDate': '1990-03-15'}
  /// ```
  Field<T> transformToJson(dynamic Function(T?) transformer) {
    _toJsonTransformer = transformer;
    return this;
  }

  /// Runs all synchronous validators against the current [value].
  ///
  /// Updates [error] with the first failing validator's message and notifies
  /// listeners if the error state changed. Validators are short-circuited —
  /// evaluation stops at the first failure.
  ///
  /// Returns `true` if all sync validators pass, `false` otherwise.
  ///
  /// This method does **not** run async validators. To run the full validation
  /// pipeline (sync + async), use [validateAsync].
  ///
  /// Example:
  /// ```dart
  /// final name = Field<String>('name')
  ///   ..addValidator('Obrigatório', (v) => v == null || v.isEmpty);
  ///
  /// name.value = '';
  /// print(name.validate()); // false
  /// print(name.error);      // 'Obrigatório'
  /// ```
  bool validate() {
    final oldError = _error;
    _error = null;
    for (var validator in _syncValidators) {
      if (validator.hasError(value)) {
        _error = validator.dynamicMessage?.call(value) ?? validator.message;
        break;
      }
    }
    if (oldError != _error) _notifyIfMounted();
    return _error == null;
  }

  /// Runs the full validation pipeline: sync validators first, then async.
  ///
  /// Execution order:
  /// 1. [onValidationStart] fires.
  /// 2. All sync validators run via [validate]. If any fail, stops here and
  ///    calls [onValidationEnd] with the sync error.
  /// 3. If there are async validators, [onAsyncValidationStart] fires,
  ///    [isLoading] becomes `true`, and async validators are awaited in order.
  /// 4. [onAsyncValidationEnd] fires with the async result.
  /// 5. [onValidationEnd] fires with the final result.
  ///
  /// Race conditions are handled via an internal version counter — if [value]
  /// changes while async validators are running, the stale result is silently
  /// discarded and `false` is returned without updating [error].
  ///
  /// Returns `true` if the field is valid, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// final username = Field<String>('username')
  ///   ..addValidator('Obrigatório', (v) => v == null || v.isEmpty)
  ///   ..addValidatorAsync('Já em uso', (v) async => await api.exists(v!));
  ///
  /// final isValid = await username.validateAsync();
  /// print(username.error); // null or error message
  /// ```
  Future<bool> validateAsync() async {
    _debounceTimer?.cancel();
    final currentVersion = ++_validationVersion;

    onValidationStart?.call();

    if (!validate()) {
      onValidationEnd?.call(false, _error);
      return false;
    }

    if (_asyncValidators.isEmpty) {
      onValidationEnd?.call(true, null);
      return true;
    }

    onAsyncValidationStart?.call();
    _isLoading = true;
    _notifyIfMounted();

    bool isValid = true;
    String? asyncError;

    for (var validator in _asyncValidators) {
      if (await validator.hasError(value)) {
        asyncError = validator.dynamicMessage?.call(value) ?? validator.message;
        isValid = false;
        break;
      }
    }

    // Abort if user continued typing while API was processing
    if (currentVersion != _validationVersion) {
      return false;
    }

    _error = asyncError;
    _isLoading = false;
    _notifyIfMounted();

    onAsyncValidationEnd?.call(isValid, asyncError);
    onValidationEnd?.call(isValid, asyncError);
    return isValid;
  }

  /// The serializable representation of this field's value.
  ///
  /// If a [transformToJson] transformer is set, it is applied to [value].
  /// If [value] is a [DateTime] and no transformer is set, it is converted
  /// to an ISO 8601 string automatically.
  /// Otherwise, [value] is returned as-is.
  ///
  /// This is the value used by [FormController.toJson] when building the
  /// form's JSON map.
  ///
  /// Example:
  /// ```dart
  /// final date = Field<DateTime>('createdAt');
  /// date.value = DateTime(2024, 6, 1);
  /// print(date.jsonValue); // '2024-06-01T00:00:00.000'
  /// ```
  dynamic get jsonValue {
    if (_toJsonTransformer != null) {
      return _toJsonTransformer!(value);
    }
    if (value is DateTime) {
      return (value as DateTime).toIso8601String();
    }
    return value;
  }

  /// Manually sets an external validation error on this field.
  ///
  /// Use this to apply server-side errors returned after a form submission
  /// (e.g. `'Email already registered'`).
  ///
  /// [message] is the error string to display.
  /// [shouldFocus] — when `true` and [focusNode] is set, requests focus on
  /// this field so the user's cursor moves to it.
  /// [shouldScroll] — when `true`, scrolls the field into view using
  /// [Scrollable.ensureVisible].
  ///
  /// Example:
  /// ```dart
  /// await form.submit((ctrl) async {
  ///   try {
  ///     await api.register(ctrl.toJson());
  ///   } on ApiError catch (e) {
  ///     form.fields.email.invalidate(e.message, shouldFocus: true);
  ///   }
  /// });
  /// ```
  void invalidate(
    String message, {
    bool shouldFocus = false,
    bool shouldScroll = false,
  }) {
    _error = message;
    _notifyIfMounted();
    if (shouldFocus || shouldScroll) {
      _focusAndScroll(shouldFocus, shouldScroll);
    }
  }

  void _focusAndScroll(bool shouldFocus, bool shouldScroll) {
    final node = focusNode;
    if (node != null) {
      if (shouldFocus) {
        node.requestFocus();
      }
      final context = node.context;
      if (shouldScroll && context != null && context.mounted) {
        Scrollable.ensureVisible(context);
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// =============================================================================
// 4. FORM CONTROLLER
// =============================================================================

/// Manages a group of [Field]s created by [formCtrl], coordinating their
/// validation, state, and serialization as a single reactive unit.
///
/// [T] is the type of the [fields] record/object returned by the [formCtrl]
/// builder — any Dart type is accepted (record, class, list, etc.).
///
/// Notifies listeners whenever any captured field changes state. Listener
/// notifications during bulk operations ([reset], [patchValue], [touchAll],
/// [trigger]) are batched into a single call.
///
/// Always call [dispose] when the controller is no longer needed. This removes
/// all internal field listeners and disposes every captured field.
class FormController<T> extends ChangeNotifier {
  /// The value returned by the [formCtrl] builder — holds all typed [Field]
  /// references for direct access.
  ///
  /// Example:
  /// ```dart
  /// final form = formCtrl(() => (name: Field<String>('name')));
  /// form.fields.name.value = 'Alice';
  /// ```
  final T fields;
  final List<Field> _capturedFields;
  final Map<String, Field> _fieldMap;

  // Prefix index: 'account' → [account.name, account.age], built once in constructor
  final Map<String, List<Field>> _prefixIndex;

  // Per-field listener closures (needed to removeListener correctly on dispose)
  final Map<Field, void Function()> _fieldListeners = {};

  // Previous state snapshot per field — used to maintain O(1) counters
  final Map<Field, ({bool isDirty, bool isTouched, bool isLoading})>
  _prevFieldState = {};

  // O(1) counters updated incrementally on each field change
  int _dirtyCount = 0;
  int _touchedCount = 0;
  int _loadingCount = 0;

  // Batch notification: suppress intermediate notifyListeners() during bulk ops
  int _batchDepth = 0;
  bool _pendingNotification = false;

  bool _isSubmitting = false;

  // Cache for toJson and errors
  Map<String, dynamic>? _jsonCache;
  Map<String, String>? _errorsCache;

  /// Called when [submit] starts executing [onSubmit], after all validators
  /// have passed. Use this to show a loading indicator.
  ///
  /// Example:
  /// ```dart
  /// form.onSubmitStart = () => setState(() => isLoading = true);
  /// ```
  void Function()? onSubmitStart;

  /// Called when [submit] finishes, whether the [onSubmit] callback
  /// succeeded or threw an exception.
  ///
  /// [success] is `true` if [onSubmit] completed without throwing.
  ///
  /// Example:
  /// ```dart
  /// form.onSubmitEnd = (success) => setState(() => isLoading = false);
  /// ```
  void Function(bool success)? onSubmitEnd;

  /// Called after [reset] has restored all fields to their initial values.
  ///
  /// Example:
  /// ```dart
  /// form.onReset = () => print('Form cleared');
  /// ```
  void Function()? onReset;

  FormController(this.fields, this._capturedFields)
    : _fieldMap = {for (var f in _capturedFields) f.name: f},
      _prefixIndex = _buildPrefixIndex(_capturedFields) {
    for (var field in _capturedFields) {
      field.form = this;
      _prevFieldState[field] = (
        isDirty: field.isDirty,
        isTouched: field.isTouched,
        isLoading: field.isLoading,
      );
      void listener() => _onSpecificFieldChanged(field);
      _fieldListeners[field] = listener;
      field.addListener(listener);
    }
  }

  // Builds a map from every path prefix to the fields nested under it.
  // 'account.personal.name' is indexed under 'account', 'account.personal',
  // and 'account.personal.name', enabling O(1) trigger(path) lookup.
  static Map<String, List<Field>> _buildPrefixIndex(List<Field> fields) {
    final index = <String, List<Field>>{};
    for (final field in fields) {
      final segments = field.pathSegments;
      for (var i = 1; i <= segments.length; i++) {
        final prefix = segments.sublist(0, i).join('.');
        index.putIfAbsent(prefix, () => []).add(field);
      }
    }
    return index;
  }

  void _onSpecificFieldChanged(Field field) {
    _invalidateCache();

    final prev = _prevFieldState[field]!;
    if (prev.isDirty != field.isDirty) _dirtyCount += field.isDirty ? 1 : -1;
    if (prev.isTouched != field.isTouched) {
      _touchedCount += field.isTouched ? 1 : -1;
    }
    if (prev.isLoading != field.isLoading) {
      _loadingCount += field.isLoading ? 1 : -1;
    }
    _prevFieldState[field] = (
      isDirty: field.isDirty,
      isTouched: field.isTouched,
      isLoading: field.isLoading,
    );

    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (_batchDepth > 0) {
      _pendingNotification = true;
    } else {
      super.notifyListeners();
    }
  }

  void _beginBatch() => _batchDepth++;

  void _endBatch() {
    _batchDepth--;
    if (_batchDepth == 0 && _pendingNotification) {
      _pendingNotification = false;
      super.notifyListeners();
    }
  }

  void _invalidateCache() {
    _jsonCache = null;
    _errorsCache = null;
  }

  /// An unmodifiable view of all [Field]s captured by [formCtrl], in
  /// construction order. Intended for debugging and testing purposes.
  List<Field> get debugFields => List.unmodifiable(_capturedFields);

  /// Returns the [Field] registered under [fieldName] (its dot-notation path).
  ///
  /// Lookup is O(1) via an internal `HashMap`. Throws [ArgumentError] if no
  /// field with that name exists in this form.
  ///
  /// [O] is the expected value type of the field.
  /// [fieldName] is the full dot-notation path (e.g. `'address.city'`).
  ///
  /// Example:
  /// ```dart
  /// final city = form.getField<String>('address.city');
  /// print(city.value);
  /// ```
  Field<O> getField<O>(String fieldName) {
    final field = _fieldMap[fieldName];
    if (field == null) {
      throw ArgumentError('Field "$fieldName" not found in form');
    }
    return field as Field<O>;
  }

  /// Returns the [Field] registered under [fieldName], or `null` if not found.
  ///
  /// Non-throwing alternative to [getField]. Use when the field's existence
  /// is conditional or unknown at compile time.
  ///
  /// [O] is the expected value type of the field.
  /// [fieldName] is the full dot-notation path (e.g. `'address.city'`).
  ///
  /// Example:
  /// ```dart
  /// final optional = form.tryGetField<String>('billing.address');
  /// optional?.value = 'Rua das Flores';
  /// ```
  Field<O>? tryGetField<O>(String fieldName) {
    return _fieldMap[fieldName] as Field<O>?;
  }

  /// Whether any field in the form is currently running async validators.
  ///
  /// Maintained as an O(1) counter — does not scan all fields.
  bool get isValidating => _loadingCount > 0;

  /// Whether [submit] is currently executing its [onSubmit] callback.
  bool get isSubmitting => _isSubmitting;

  /// Whether the form has no validation errors.
  ///
  /// Delegates to [errors] — `true` when [errors] is empty.
  bool get valid => errors.isEmpty;

  /// Whether any field's current value differs from its [Field.initialValue].
  ///
  /// Maintained as an O(1) counter — does not scan all fields.
  bool get isDirty => _dirtyCount > 0;

  /// Whether [Field.touch] has been called on any field in the form.
  ///
  /// Maintained as an O(1) counter — does not scan all fields.
  bool get isTouched => _touchedCount > 0;

  /// A map of field path → error message for every field with a current error.
  ///
  /// The result is cached and invalidated automatically whenever any field
  /// changes state. Repeated reads with no intervening changes return the same
  /// `Map` instance (identity equality).
  ///
  /// Returns an unmodifiable, empty map when the form is valid.
  ///
  /// Example:
  /// ```dart
  /// await form.trigger();
  /// if (form.errors.isNotEmpty) {
  ///   print(form.errors); // {'email': 'Email inválido', 'age': 'Maior de 18'}
  /// }
  /// ```
  Map<String, String> get errors {
    if (_errorsCache != null) {
      return _errorsCache!;
    }

    final map = <String, String>{};
    for (var field in _capturedFields) {
      if (field.error != null) {
        map[field.name] = field.error!;
      }
    }
    _errorsCache = Map.unmodifiable(map);
    return _errorsCache!;
  }

  /// Resets all fields to their initial values and clears all validation state.
  ///
  /// Equivalent to calling [Field.reset] on every field, but batched so that
  /// listeners receive exactly **one** notification regardless of the number
  /// of fields. [onReset] is called after all fields are reset.
  ///
  /// Example:
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: form.reset,
  ///   child: const Text('Limpar'),
  /// )
  /// ```
  void reset() {
    _beginBatch();
    _pendingNotification = true; // garante notificação mesmo em form vazio
    try {
      for (var field in _capturedFields) {
        field.reset();
      }
      _invalidateCache();
      onReset?.call();
    } finally {
      _endBatch();
    }
  }

  /// Resets a single field identified by its dot-notation [path].
  ///
  /// Has no effect if [path] does not match any registered field.
  ///
  /// Example:
  /// ```dart
  /// form.resetField('address.zip'); // resets only the zip field
  /// ```
  void resetField(String path) {
    final field = _fieldMap[path];
    if (field != null) {
      field.reset();
      _invalidateCache();
    }
  }

  /// Updates multiple field values in a single batched operation.
  ///
  /// [values] maps dot-notation field paths to their new values. Fields not
  /// present in [values] are left unchanged. Unknown keys are silently ignored.
  ///
  /// All value assignments are batched so listeners receive exactly **one**
  /// notification regardless of how many fields are updated.
  ///
  /// Example:
  /// ```dart
  /// form.patchValue({
  ///   'name':  'Alice',
  ///   'email': 'alice@example.com',
  ///   'age':   30,
  /// });
  /// ```
  void patchValue(Map<String, dynamic> values) {
    _beginBatch();
    try {
      for (var entry in values.entries) {
        final field = _fieldMap[entry.key];
        if (field != null) field.value = entry.value;
      }
    } finally {
      _endBatch();
    }
  }

  /// Sets the value of a single field identified by its dot-notation [path].
  ///
  /// [V] is the value type of the target field.
  /// Has no effect if [path] does not match any registered field.
  ///
  /// Example:
  /// ```dart
  /// form.setValue<String>('address.city', 'São Paulo');
  /// ```
  void setValue<V>(String path, V value) {
    final field = _fieldMap[path];
    if (field != null) {
      field.value = value;
    }
  }

  /// Marks all fields as touched in a single batched operation.
  ///
  /// Equivalent to calling [Field.touch] on every field, but batched so
  /// listeners receive exactly **one** notification. Typically called before
  /// [trigger] or at the start of [submit] to reveal all pending errors.
  ///
  /// Example:
  /// ```dart
  /// // Show all errors on first submit attempt
  /// form.touchAll();
  /// await form.trigger();
  /// ```
  void touchAll() {
    _beginBatch();
    try {
      for (var field in _capturedFields) {
        field.touch();
      }
    } finally {
      _endBatch();
    }
  }

  /// Validates fields by path prefix, running both sync and async validators.
  ///
  /// When [path] is `null` or empty, all fields in the form are validated.
  /// When [path] is provided, only fields whose dot-notation name starts with
  /// [path] are validated — e.g. `trigger('address')` validates
  /// `address.street`, `address.city`, etc. Lookup is O(1) via an internal
  /// prefix index.
  ///
  /// All matched fields are marked as touched before validation begins,
  /// batched into a single notification.
  ///
  /// [shouldFocus] — when `true` and a [FocusNode] is set, requests focus on
  /// the first invalid field.
  /// [shouldScroll] — when `true`, scrolls the first invalid field into view.
  ///
  /// Returns `true` if all matched fields are valid, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// // Validate only the 'payment' group before proceeding to the next step
  /// final ok = await form.trigger('payment');
  /// if (ok) goToNextStep();
  ///
  /// // Validate the entire form
  /// final allValid = await form.trigger();
  /// ```
  Future<bool> trigger({
    String? path,
    bool shouldFocus = false,
    bool shouldScroll = false,
  }) async {
    final matchingFields = (path == null || path.isEmpty)
        ? _capturedFields
        : (_prefixIndex[path] ?? const []);

    if (matchingFields.isEmpty) return true;

    // Batch the touch marks so they emit 1 notification instead of N
    _beginBatch();
    try {
      for (var f in matchingFields) {
        f._markAsTouched();
      }
    } finally {
      _endBatch();
    }

    final results = await Future.wait(
      matchingFields.map((f) => f.validateAsync()),
    );

    final isValid = !results.contains(false);

    if (!isValid && (shouldFocus || shouldScroll)) {
      for (int i = 0; i < matchingFields.length; i++) {
        if (!results[i]) {
          matchingFields[i]._focusAndScroll(shouldFocus, shouldScroll);
          break; // Focus/Scroll only on the first invalid field
        }
      }
    }

    return isValid;
  }

  /// Manually sets an error on the field identified by [path].
  ///
  /// Convenience wrapper around [Field.invalidate] for use at the form level,
  /// typically to apply server-side validation errors after a failed submission.
  ///
  /// [path] is the field's dot-notation name.
  /// [message] is the error string to display.
  /// [shouldFocus] and [shouldScroll] behave as in [Field.invalidate].
  /// Has no effect if [path] does not match any registered field.
  ///
  /// Example:
  /// ```dart
  /// await form.submit((ctrl) async {
  ///   final res = await api.register(ctrl.toJson());
  ///   if (res.error == 'email_taken') {
  ///     form.invalidateField('email', 'Este email já está cadastrado',
  ///         shouldFocus: true);
  ///   }
  /// });
  /// ```
  void invalidateField(
    String path,
    String message, {
    bool shouldFocus = false,
    bool shouldScroll = false,
  }) {
    final field = _fieldMap[path];
    if (field != null) {
      field.invalidate(
        message,
        shouldFocus: shouldFocus,
        shouldScroll: shouldScroll,
      );
    }
  }

  /// Validates all fields and, if the form is valid, executes [onSubmit].
  ///
  /// Execution flow:
  /// 1. [touchAll] is called so all fields show their errors.
  /// 2. [trigger] runs all validators. If any field is invalid, [onSubmit]
  ///    is not called and the method returns.
  /// 3. [isSubmitting] becomes `true` and [onSubmitStart] fires.
  /// 4. [onSubmit] is awaited with the [FormController] as argument.
  /// 5. [onSubmitEnd] fires with `success: true` on completion, or
  ///    `success: false` if [onSubmit] throws (the exception is re-thrown).
  /// 6. [isSubmitting] returns to `false`.
  ///
  /// [shouldFocus] and [shouldScroll] are forwarded to [trigger] to move the
  /// cursor to the first invalid field when validation fails.
  ///
  /// Example:
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: () => form.submit((ctrl) async {
  ///     await api.save(ctrl.toJson());
  ///   }),
  ///   child: const Text('Salvar'),
  /// )
  /// ```
  Future<void> submit(
    FutureOr<void> Function(FormController<T> data) onSubmit, {
    bool shouldFocus = true,
    bool shouldScroll = true,
  }) async {
    touchAll();
    final isValidForm = await trigger(
      shouldFocus: shouldFocus,
      shouldScroll: shouldScroll,
    );

    if (isValidForm) {
      _isSubmitting = true;
      onSubmitStart?.call();
      notifyListeners();

      try {
        await onSubmit(this);
        onSubmitEnd?.call(true);
      } catch (e) {
        onSubmitEnd?.call(false);
        rethrow;
      } finally {
        _isSubmitting = false;
        notifyListeners();
      }
    }
  }

  /// Serializes all field values to a nested `Map<String, dynamic>`.
  ///
  /// Dot-notation field paths are expanded into nested maps:
  /// a field named `'address.city'` appears as `{'address': {'city': ...}}`.
  ///
  /// Each field's [Field.jsonValue] is used, so mask stripping and custom
  /// [Field.transformToJson] transformers are applied automatically.
  ///
  /// The result is cached and invalidated whenever any field value changes.
  /// Repeated calls with no intervening changes return the same `Map` instance
  /// (identity equality), making this O(1) after the first call.
  ///
  /// Example:
  /// ```dart
  /// final form = formCtrl(() => (
  ///   name:  Field<String>('name', 'Alice'),
  ///   email: Field<String>('email', 'alice@example.com'),
  /// ));
  ///
  /// print(form.toJson()); // {'name': 'Alice', 'email': 'alice@example.com'}
  /// ```
  Map<String, dynamic> toJson() {
    if (_jsonCache != null) {
      return _jsonCache!;
    }

    final map = <String, dynamic>{};
    for (var field in _capturedFields) {
      _putNestedValue(map, field.pathSegments, field.jsonValue);
    }
    _jsonCache = map;
    return map;
  }

  void _putNestedValue(
    Map<String, dynamic> map,
    List<String> keys,
    dynamic value,
  ) {
    var current = map;
    for (int i = 0; i < keys.length - 1; i++) {
      current[keys[i]] ??= <String, dynamic>{};
      current = current[keys[i]];
    }
    current[keys.last] = value;
  }

  /// Removes all internal field listeners and disposes every captured [Field].
  ///
  /// Must be called when the form is no longer needed (e.g. in a
  /// `StatefulWidget.dispose`). After this call the controller must not be
  /// used again.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void dispose() {
  ///   form.dispose();
  ///   super.dispose();
  /// }
  /// ```
  @override
  void dispose() {
    for (var field in _capturedFields) {
      final listener = _fieldListeners[field];
      if (listener != null) field.removeListener(listener);
      field.dispose();
    }
    super.dispose();
  }
}

/// Creates a [FormController] by running [builder] inside a tracked context
/// that captures every [Field] constructed during the call.
///
/// [T] can be any Dart type — record, class, list, or even a single [Field].
/// The return value of [builder] becomes [FormController.fields], giving
/// typed access to each field.
///
/// Fields created outside [builder] are not captured and will not be managed
/// by the returned controller.
///
/// Always call [FormController.dispose] when the form is no longer needed.
///
/// Example:
/// ```dart
/// final form = formCtrl(() => (
///   name:  Field<String>('name'),
///   email: Field<String>('email')
///     ..addValidator('Email inválido', (v) => !v!.contains('@')),
/// ));
///
/// form.fields.name.value = 'Alice';
/// await form.submit((ctrl) async {
///   await api.save(ctrl.toJson());
/// });
///
/// form.dispose();
/// ```
FormController<T> formCtrl<T>(T Function() builder) {
  return FormTracker.runInContext(() {
    final record = builder();
    final capturedFields = FormTracker.getCapturedFields();
    return FormController<T>(record, capturedFields);
  });
}
