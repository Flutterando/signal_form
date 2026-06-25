## 0.1.0

### New features — `Field<T>`

* **`field.parse(fn)`** — Registers a `String → T` converter applied automatically when a string value is assigned. Enables connecting a `TextField` to a typed field like `Field<int>` or `Field<DateTime>` without a separate adapter layer. When used together with `mask`, the mask runs first, then parse — so `Field<DateTime>('birth').mask('##/##/####').parse(parseDate)` receives the already-formatted string.
* **`field.transform(fn)`** — Normalizes the value before storing it (e.g. trim, lowercase, force prefix). Runs after mask and parse in the assignment pipeline. Composable via chaining.
* **`field.reset({to})`** — `reset()` without arguments continues to restore `initialValue`. The new named parameter `to:` resets to an arbitrary value instead; `isDirty` reflects the comparison against `initialValue`. Supports `reset(to: null)` to explicitly set null.
* **`field.clearError()`** — Clears the current validation error without re-running validators. Useful for dismissing errors from `setErrors` or `invalidate` without triggering a full re-validation cycle.
* **`field.disable()` / `field.enable()`** — Disable a field to skip all its validators and exclude it from form-level checks. Re-enable to restore normal behavior. Disabled fields can be excluded from `toJson` via `omitDisabled: true`.
* **`Field.detached<T>(name, [initialValue])`** — Static factory that creates a `Field` outside any `formCtrl` tracking context. Intended for tests and reusable helper functions.
* **`Field.computed<T>(name, (valueOf) => value)`** — Static factory that creates a derived, read-only field. The value is recomputed automatically whenever any field in the form changes. The setter throws `UnsupportedError`; `isDirty` is always `false`; `reset()` is a no-op. Computed fields appear in `toJson` and are excluded from `completionPercent`.

### New features — `FormController`

* **`form.fromJson(map, {setAsInitial: false})`** — Populates fields from a JSON map (nested maps are automatically flattened to dot-notation paths). When `setAsInitial: true`, also updates each field's `initialValue` so that a subsequent `reset()` returns to the loaded data and `dirtyValues()` diffs correctly. Designed for edit-form (CRUD) patterns.
* **`form.dirtyValues()`** — Returns a nested map containing only the fields whose value differs from `initialValue`. Use as the body of a PATCH request to send only what the user changed.
* **`form.clearErrors({path})`** — Clears all validation errors across the form in a single batched notification. Pass `path:` to restrict clearing to a specific field or group prefix.
* **`form.setErrors(Map<String, String>, {shouldFocusFirst, shouldScrollFirst})`** — Batch-applies server-side validation errors. Each map key is a dot-notation field path; unmatched keys are silently ignored. All updates are batched into a single notification.
* **`form.toQueryString({omitNulls: true})`** — Serializes the form as a URL query string. Nested maps are flattened with dot notation; values are percent-encoded.
* **`form.completionPercent`** — Returns a `double` from `0.0` to `1.0` representing the fraction of non-disabled, non-computed fields that have a non-null, non-empty value.

### Breaking changes

* **`Field.value` setter now accepts `dynamic` instead of `T?`.** This enables assigning string input directly to typed fields (e.g. `field<int>.value = '25'` routes through `parse`). Side effect: untyped empty list literals lose type inference — `field.value = []` on a `Field<List<String>>` raises a runtime cast error. Use `field.value = <String>[]` instead. Non-empty literals (`['a', 'b']`) and typed variables are unaffected.

### Bug fixes

* **`oneOf` error message no longer concatenates the allowed values.** Previously the error was `'$message admin, editor, viewer'`; it is now `'$message'` exactly as provided.
* **`required()` generic validator now works correctly on any `Field<T>`.** The generic extension on `Field<T>` checks for `null`. On `Field<String>`, the more specific string extension continues to apply (also checks empty/whitespace).

---

## 0.0.1

* Initial release.
* Schema-based form management with strongly typed `Field<T>` declarations.
* Fluent validation API — chain sync and async validators in a single expression.
* Built-in validators for strings, numbers, dates, booleans, lists, and date ranges.
* Validation modes: `onChange`, `onBlur`, and `onSubmit`.
* Conditional validation with `applyWhen` and cross-field references via `valueOf`.
* Debounce support for keystroke-heavy fields.
* Auto-scroll to first invalid field on `submit()` and `trigger()`.
* Ready-made Material widgets: `SignalTextField`, `SignalDropdown`, `SignalCheckbox`, `SignalSwitch`, `SignalRadioGroup`, `SignalCheckboxGroup`, `SignalSlider`, `SignalRangeSlider`, `SignalDateTimePicker`, `SignalDateRangePicker`, `SignalChoiceChip`, `SignalFilterChip`.
* `SignalFormField<T>` escape hatch to wrap any custom widget.

#### Input masking

Generic mask via `field.mask(pattern)` where `#` matches any alphanumeric character. Mask characters are stripped from `toJson` output by default (`removeMaskOnJson: true`).

Brazilian ready-made formatters:

| Method | Format |
|---|---|
| `maskCPF()` | `XXX.XXX.XXX-XX` |
| `maskCNPJ()` | `99.999.999/9999-99` |
| `maskCNPJAlfanumerico()` | `XX.XXX.XXX/XXXX-XX` (alphanumeric, 2024 format) |
| `maskCPFOrCNPJ()` | dynamic — CPF up to 11 digits, CNPJ from 12 |
| `maskCEP({ponto})` | `XX.XXX-XXX` / `XXXXX-XXX` |
| `maskCelular()` | `(99) 99999-9999` |
| `maskData()` | `DD/MM/YYYY` |
| `maskHora()` | `HH:mm` |
| `maskDecimal({casasDecimais})` | `9.999.999.999,00` |
| `maskReal()` | `999.999.999.999` |
| `maskCartaoCredito()` | `0000 1111 2222 3333` |
| `maskCartaoTelefone()` | `000 1111 2222 3333` |
| `maskAltura()` | `1,82` |
| `maskPeso()` | `103,8` |
| `maskTemperatura()` | `10,8` |
| `maskKm()` | `000.000` |
| `maskValidade({maxLength})` | `MM/AA` / `MM/AAAA` |
| `maskIOF()` | `1,234567` |
| `maskNCM()` | `XXXX.XX.XX` |
| `maskCEST()` | `XX.XXX.XX` |
| `maskNUP()` | `XXXXXXX-XX.XXXX.X.XX.XXXX` |
| `maskPlacaVeiculo()` | `XXX-XXXX` (old and Mercosul, uppercased) |
| `maskCertidaoNascimento()` | birth certificate (32 digits) |
