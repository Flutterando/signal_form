import '../core.dart';

/// Validation and mutation extensions for [Field<List<T>>].
///
/// All validator methods return `this` to allow method chaining on the field
/// builder. Mutation methods ([addItem], [removeItem], [removeAt], [clear])
/// update [Field.value] directly and trigger the normal value-change cycle
/// (masking, dirty tracking, validation based on mode, listener notification).
extension ListFieldValidators<T> on Field<List<T>> {
  /// The current list of items, or an empty list when [Field.value] is `null`.
  ///
  /// Example:
  /// ```dart
  /// final tags = Field<List<String>>('tags');
  /// tags.addItem('flutter');
  /// print(tags.items); // ['flutter']
  /// ```
  List<T> get items => value ?? [];

  /// Validates that the list is not `null` and not empty.
  ///
  /// [message] is the error string shown when validation fails.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final tags = Field<List<String>>('tags')
  ///   .required(message: 'Selecione ao menos uma tag');
  /// ```
  Field<List<T>> required({String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val == null || val.isEmpty,
      exposedMessage: exposed,
    );
  }

  /// Validates that the list has at least [count] items.
  ///
  /// [count] is the minimum number of items required.
  /// [message] is the error string shown when the list has fewer items.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final photos = Field<List<String>>('photos')
  ///   .minItems(1, message: 'Adicione ao menos 1 foto')
  ///   .maxItems(5, message: 'Máximo de 5 fotos');
  /// ```
  Field<List<T>> minItems(
    int count, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val == null || val.length < count,
      exposedMessage: exposed,
    );
  }

  /// Validates that the list has at most [count] items.
  ///
  /// [count] is the maximum number of items allowed.
  /// [message] is the error string shown when the list exceeds the limit.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final selected = Field<List<int>>('selected')
  ///   .maxItems(3, message: 'Selecione no máximo 3 itens');
  /// ```
  Field<List<T>> maxItems(
    int count, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && val.length > count,
      exposedMessage: exposed,
    );
  }

  /// Validates that the list has exactly [count] items.
  ///
  /// [count] is the exact number of items required.
  /// [message] is the error string shown when the count does not match.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final coordinates = Field<List<double>>('point')
  ///   .itemCount(2, message: 'Informe latitude e longitude');
  /// ```
  Field<List<T>> itemCount(
    int count, {
    String message = '',
    bool exposed = false,
  }) {
    return addValidator(
      message,
      (val) => val != null && val.length != count,
      exposedMessage: exposed,
    );
  }

  /// Validates that the list contains [item].
  ///
  /// [item] is the value that must be present in the list.
  /// [message] is the error string shown when [item] is not found.
  /// [exposed] — when `true`, the rule appears in [Field.exposedRules].
  ///
  /// Returns `this` to allow method chaining.
  ///
  /// Example:
  /// ```dart
  /// final roles = Field<List<String>>('roles')
  ///   .contains('admin', message: 'Requer permissão de administrador');
  /// ```
  Field<List<T>> contains(T item, {String message = '', bool exposed = false}) {
    return addValidator(
      message,
      (val) => val != null && !val.contains(item),
      exposedMessage: exposed,
    );
  }

  /// Appends [item] to the end of the current list and updates the field value.
  ///
  /// Creates a new list instance (does not mutate the existing one). Triggers
  /// the normal value-change cycle — dirty tracking, validation, and listener
  /// notification.
  ///
  /// Example:
  /// ```dart
  /// final tags = Field<List<String>>('tags');
  /// tags.addItem('flutter');
  /// tags.addItem('dart');
  /// print(tags.value); // ['flutter', 'dart']
  /// ```
  void addItem(T item) {
    value = [...items, item];
  }

  /// Removes the first occurrence of [item] from the list by equality.
  ///
  /// If [item] is not present, the list is unchanged.
  ///
  /// Example:
  /// ```dart
  /// final tags = Field<List<String>>('tags', ['flutter', 'dart']);
  /// tags.removeItem('dart');
  /// print(tags.value); // ['flutter']
  /// ```
  void removeItem(T item) {
    value = items.where((i) => i != item).toList();
  }

  /// Removes the item at [index] from the list.
  ///
  /// Has no effect if [index] is out of bounds.
  ///
  /// Example:
  /// ```dart
  /// final tags = Field<List<String>>('tags', ['a', 'b', 'c']);
  /// tags.removeAt(1);
  /// print(tags.value); // ['a', 'c']
  /// ```
  void removeAt(int index) {
    if (index >= 0 && index < items.length) {
      final newList = [...items];
      newList.removeAt(index);
      value = newList;
    }
  }

  /// Clears all items by setting the field value to an empty list.
  ///
  /// Example:
  /// ```dart
  /// final tags = Field<List<String>>('tags', ['a', 'b']);
  /// tags.clear();
  /// print(tags.value); // []
  /// ```
  void clear() {
    value = <T>[];
  }
}
