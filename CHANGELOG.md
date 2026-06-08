## 0.0.1

* Initial release.
* Schema-based form management with strongly typed `Field<T>` declarations.
* Fluent validation API — chain sync and async validators in a single expression.
* Built-in validators for strings, numbers, dates, booleans, lists, and date ranges.
* Validation modes: `onChange`, `onBlur`, and `onSubmit`.
* Conditional validation with `applyWhen` and cross-field references via `valueOf`.
* Input masking with automatic JSON stripping.
* Debounce support for keystroke-heavy fields.
* Auto-scroll to first invalid field on `submit()` and `trigger()`.
* Ready-made Material widgets: `SignalTextField`, `SignalDropdown`, `SignalCheckbox`, `SignalSwitch`, `SignalRadioGroup`, `SignalCheckboxGroup`, `SignalSlider`, `SignalRangeSlider`, `SignalDateTimePicker`, `SignalDateRangePicker`, `SignalChoiceChip`, `SignalFilterChip`.
* `SignalFormField<T>` escape hatch to wrap any custom widget.
