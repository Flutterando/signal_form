# signal_form

> 🇧🇷 [Leia em Português](README.pt-br.md)

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#installation">Installation</a></li>
    <li>
      <a href="#quick-start">Quick start</a>
      <ol>
        <li><a href="#1-define-the-schema">1. Define the schema</a></li>
        <li><a href="#2-wire-the-widgets">2. Wire the widgets</a></li>
        <li><a href="#3-dispose">3. Dispose</a></li>
        <li><a href="#recommended-project-organization">Recommended Project Organization</a></li>
      </ol>
    </li>
    <li>
      <a href="#motivation">Motivation</a>
      <ol>
        <li><a href="#detailed-feature-list">Detailed Feature List</a></li>
      </ol>
    </li>
    <li>
      <a href="#core-api">Core API</a>
      <ol>
        <li><a href="#fieldt">Field&lt;T&gt;</a></li>
        <li><a href="#formcontrollert">FormController&lt;T&gt;</a></li>
        <li><a href="#nested-groups--formgroup">Nested groups — formGroup</a></li>
      </ol>
    </li>
    <li><a href="#validation-modes">Validation modes</a></li>
    <li>
      <a href="#custom-validators">Custom validators</a>
      <ol>
        <li><a href="#sync--must">Sync — must</a></li>
        <li><a href="#cross-field--mustwith">Cross-field — mustWith</a></li>
        <li><a href="#low-level--addvalidator">Low-level — addValidator</a></li>
      </ol>
    </li>
    <li><a href="#async-validators">Async validators</a></li>
    <li><a href="#conditional-validation--applywhen">Conditional validation — applyWhen</a></li>
    <li>
      <a href="#conditional-routing--switchwith">Conditional routing — switchWith</a>
      <ol>
        <li><a href="#typed-keys-with-sealed-classes">Typed keys with sealed classes</a></li>
      </ol>
    </li>
    <li><a href="#exposed-rules-password-strength-indicator">Exposed rules (password strength indicator)</a></li>
    <li>
      <a href="#input-masking">Input masking</a>
      <ol>
        <li><a href="#mask-reference">Mask reference</a></li>
      </ol>
    </li>
    <li><a href="#tojson-transformer">toJson transformer</a></li>
    <li><a href="#lifecycle-callbacks">Lifecycle callbacks</a></li>
    <li>
      <a href="#widgets">Widgets</a>
      <ol>
        <li><a href="#signaltextfield">SignalTextField</a></li>
        <li><a href="#signaldropdownt">SignalDropdown&lt;T&gt;</a></li>
        <li><a href="#signalcheckbox">SignalCheckbox</a></li>
        <li><a href="#signalswitch">SignalSwitch</a></li>
        <li><a href="#signalradiogroupt">SignalRadioGroup&lt;T&gt;</a></li>
        <li><a href="#signalcheckboxgroupt">SignalCheckboxGroup&lt;T&gt;</a></li>
        <li><a href="#signalslider">SignalSlider</a></li>
        <li><a href="#signalrangeslider">SignalRangeSlider</a></li>
        <li><a href="#signaldatetimepicker">SignalDateTimePicker</a></li>
        <li><a href="#signaldaterangepicker">SignalDateRangePicker</a></li>
        <li><a href="#signalchoicechipt-and-signalfilterchipt">SignalChoiceChip&lt;T&gt; and SignalFilterChip&lt;T&gt;</a></li>
      </ol>
    </li>
    <li><a href="#vanilla-flutter-inputs--signalformfieldt">Vanilla Flutter inputs — SignalFormField&lt;T&gt;</a></li>
    <li><a href="#validation-reference">Validation reference</a></li>
    <li><a href="#extending-with-custom-validators">Extending with custom validators</a></li>
    <li><a href="#ai-assisted-development">AI-Assisted Development</a></li>
  </ol>
</details>

## Installation

```yaml
dependencies:
  signal_form: ^0.0.1
```

```dart
import 'package:signal_form/signal_form.dart';
```

---

## Quick start

### 1. Define the schema

```dart
final form = formCtrl(() {
  return (
    name: Field<String>('name')
      .required(message: 'Name is required')
      .minLength(3, message: 'At least 3 characters'),
    email: Field<String>('email')
      .required(message: 'E-mail is required')
      .email(message: 'Invalid e-mail'),
    age: Field<int>('age')
      .required(message: 'Age is required')
      .min(18, message: 'Must be 18 or older'),
  );
});
```

`formCtrl` captures every `Field` created inside the builder and returns a typed `FormController`.

### 2. Wire the widgets

Use `ListenableBuilder` to make your UI react to global form state (like validation status and submission loading states):

```dart
Column(
  children: [
    SignalTextField(
      field: form.fields.name,
      decoration: const InputDecoration(labelText: 'Name'),
    ),
    SignalTextField(
      field: form.fields.email,
      decoration: const InputDecoration(labelText: 'E-mail'),
      keyboardType: TextInputType.emailAddress,
    ),
    ListenableBuilder(
      listenable: form,
      builder: (context, _) {
        return ElevatedButton(
          // Disable button if form is invalid or submitting
          onPressed: form.valid && !form.isSubmitting
              ? () => form.submit((f) async {
                  await myApi.save(f.toJson());
                })
              : null,
          child: form.isSubmitting
              ? const CircularProgressIndicator()
              : const Text('Submit'),
        );
      },
    ),
  ],
)
```

### 3. Dispose

Always call `form.dispose()` in your `StatefulWidget`'s `dispose` method to release captured fields and internal listeners to prevent memory leaks:

```dart
@override
void dispose() {
  form.dispose();
  super.dispose();
}
```

### Recommended Project Organization

For larger or more maintainable projects, it is a best practice to split your form schema definition from your UI screen into separate files. This keeps your validation and data transformation logic completely independent of Flutter widgets.

Here is a recommended pattern:

#### 1. The Schema File (`login_schema.dart`)

This file contains the schema record definition, the builder function, and any data mapping extensions:

```dart
// login_schema.dart
typedef LoginFormSchema = ({Field<String> email, Field<String> password});

LoginFormSchema loginFormSchema() => (
  // email
  email: Field<String>('email')
      .required(message: 'O e-mail é obrigatório')
      .email(message: 'E-mail inválido'),
  // password
  password: Field<String>('password')
      .required(message: 'A senha é obrigatória')
      .minLength(6, message: 'A senha deve ter pelo menos 6 caracteres'),
);

extension ParseFormExtension on FormController<LoginFormSchema> {
  LoginDto toDto() {
    return LoginDto(
      email: fields.email.value!,
      password: fields.password.value!,
    );
  }
}
```

#### 2. The Screen File (`login_screen.dart`)

This file instantiates the form controller and builds the user interface:

```dart
// login_screen.dart

late final form = formCtrl(loginFormSchema);

void submit() => form.submit((data) async => api.login(data.toDto()));

// In your build method:
Column(
  children: [
    SignalTextField(
      field: form.fields.email,
      decoration: const InputDecoration(labelText: 'E-mail'),
      keyboardType: TextInputType.emailAddress,
    ),
    SignalTextField(
      field: form.fields.password,
      decoration: const InputDecoration(labelText: 'Senha'),
      obscureText: true,
    ),
    ListenableBuilder(
      listenable: form,
      builder: (context, _) {
        return ElevatedButton(
          // Disable button if form is invalid or submitting
          onPressed: form.valid && !form.isSubmitting
              ? submit
              : null,
          child: form.isSubmitting
              ? const CircularProgressIndicator()
              : const Text('Submit'),
        );
      },
    ),
  ],
)
```

## Motivation

Managing complex forms in Flutter often means juggling `TextEditingController`, `GlobalKey<FormState>`, scattered validation logic, and imperative state updates. **signal_form** was built to unify and simplify all of that.

Inspired by [Angular Signal Forms](https://angular.dev/essentials/signal-forms), it brings a **schema-based, strongly typed** approach to Flutter forms: you declare your fields and validation rules once, in a single place, and the library takes care of the rest.

- **Declarative validation** — rules live next to the field they belong to, not scattered across the widget tree
- **Fluent API** — chain validators in a single expression with low verbosity and high readability
- **High performance** — fields notify only their own listeners; the form-level cache avoids redundant recomputation
- **Data formatting and transformation** — built-in input masking and `toJson` transformers keep raw and serialized values in sync automatically
- **Ready-made widgets** — drop-in Material components (`SignalTextField`, `SignalDropdown`, `SignalCheckbox`, and more) with error display, focus handling, and automatic scroll to the first invalid field wired up out of the box
- **Extensible** — add your own sync or async validators as plain Dart extension methods, indistinguishable from the built-ins

### Detailed Feature List

- **Schema-first** — define your form structure in pure Dart records; no `GlobalKey<FormState>` or `TextEditingController` to manage
- **Fluent validation API** — chain validators directly on each `Field` declaration
- **Sync & async validators** — built-in race-condition protection for async checks
- **Debounce** — throttle validation on keystroke-heavy fields
- **Validation modes** — `onChange`, `onBlur`, or `onSubmit`
- **Conditional validation** — `applyWhen` activates rules only when another field satisfies a condition
- **Cross-field validation** — compare or reference sibling fields via `valueOf`
- **Input masking** — built-in `mask()` with automatic JSON stripping
- **Auto-scroll on error** — `submit()` and `trigger()` focus/scroll to the first invalid field
- **Ready-made widgets** — `SignalTextField`, `SignalDropdown`, `SignalCheckbox`, `SignalSwitch`, `SignalRadioGroup`, `SignalCheckboxGroup`, `SignalSlider`, `SignalRangeSlider`, `SignalDateTimePicker`, `SignalDateRangePicker`, `SignalChoiceChip`, `SignalFilterChip`
- **High performance** — fields notify only their own listeners; a form-level cache avoids redundant recomputation on every rebuild
- **Strongly typed** — every `Field<T>`, validator, and `toJson` value is fully typed end-to-end; no `dynamic` leaks at the form level
- **Escape hatch** — `SignalFormField<T>` lets you wrap any Flutter widget with full field reactivity

---

## Core API

### `Field<T>`

The building block. Every field is typed, reactive, and self-contained.

```dart
Field<String>('username')
  .required(message: 'Required')
  .minLength(3, message: 'Min 3 chars')
  .maxLength(20, message: 'Max 20 chars');
```

| Property | Type | Description |
|---|---|---|
| `value` | `T?` | Current value (read/write) |
| `error` | `String?` | Current validation error |
| `isDirty` | `bool` | Value differs from initial value |
| `isTouched` | `bool` | Field has been interacted with |
| `isLoading` | `bool` | Async validation in progress |
| `isDisabled` | `bool` | Field is disabled (validators skipped) |
| `initialValue` | `T?` | Value the field was initialized with |
| `exposedRules` | `List<({String message, bool isValid})>` | Rules marked with `exposed: true` |

| Method | Description |
|---|---|
| `touch()` | Mark field as touched |
| `reset()` | Restore to initial value, clear errors |
| `reset({to})` | Restore to initial value, or to an arbitrary value via the named `to` parameter |
| `parse(fn)` | Converts raw string input to the field's value type (e.g. `String → int`) |
| `transform(fn)` | Normalizes the value before storing (trim, lowercase, etc.) |
| `invalidate(message)` | Set a manual error |
| `clearError()` | Clear the current error without re-running validators |
| `disable()` | Disable the field — all validators are skipped |
| `enable()` | Re-enable the field — restores normal validation |
| `validate()` | Run sync validators, returns `bool` |
| `validateAsync()` | Run all validators, returns `Future<bool>` |
| `debounce(duration)` | Throttle validation |
| `validationMode(mode)` | Set `onChange`, `onBlur`, or `onSubmit` |

#### `parse(fn)` — type conversion from text input

`parse` registers a converter that turns a raw `String` into the field's typed value. This is the bridge between a `TextField` (which always emits `String`) and a strongly-typed field like `Field<int>` or `Field<DateTime>`.

```dart
final age   = Field<int>('age').parse(int.tryParse);
final birth = Field<DateTime>('birth')
    .mask('##/##/####')
    .parse((s) {
      final p = s.split('/');
      return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
    });

age.value = '25';          // stored as int 25
birth.value = '25121990';  // mask → '25/12/1990' → parse → DateTime(1990,12,25)
```

**How the setter works.** `Field.value` accepts `dynamic`. When the incoming value is a `String`, the pipeline is:

```
String input  →  mask (if set)  →  parse (if set)  →  transform (if set)  →  stored as T
```

When the value is not a `String` (e.g. programmatic assignment of an already-typed value), it is cast directly to `T?` — the parse and mask steps are skipped.

**Empty-list caveat.** Because the setter accepts `dynamic`, Dart cannot infer the element type of an untyped list literal — `[]` becomes `List<dynamic>` and the runtime cast to `List<String>` fails. Always supply the element type when assigning an empty list literal to a typed list field:

```dart
// ✗ runtime error — List<dynamic> is not List<String>
tags.value = [];

// ✓ explicit element type
tags.value = <String>[];
```

Non-empty literals (`['a', 'b']`) and variables (`final list = <String>[]; tags.value = list;`) work without annotation because Dart infers their type from the elements or the declaration.

#### `Field.detached<T>` factory

Creates a `Field` that is **not tracked** by the enclosing `formCtrl`. Use it inside tests or helper functions to avoid accidentally registering a stray field on a form:

```dart
final standalone = Field.detached<String>('label');
// or with initial value:
final standalone = Field.detached<int>('count', 0);
```

#### `Field.computed<T>` factory

Creates a **derived, read-only** field whose value is recomputed automatically whenever any field in the form changes. The computed field appears in `toJson`, is excluded from `completionPercent`, and its `isDirty` is always `false`.

```dart
final form = formCtrl(() => (
  qty:   Field<int>('qty', 1),
  price: Field<double>('price', 99.9),
  total: Field.computed<double>('total', (valueOf) {
    final q = valueOf<int>('qty').value ?? 0;
    final p = valueOf<double>('price').value ?? 0;
    return q * p;
  }),
));

form.fields.qty.value = 3;
print(form.fields.total.value); // 299.7
```

### `FormController<T>`

Returned by `formCtrl`. Holds all fields and coordinates validation.

```dart
form.submit((f) async { ... });          // validate all, call on success
form.trigger();                           // validate all without submitting
form.trigger(path: 'email');              // validate only a specific field/group
form.reset();                             // reset all fields
form.resetField('email');                 // reset one field
form.patchValue({'name': 'John'});        // set multiple values
form.setValue('email', 'a@b.com');
form.fromJson(map);                       // populate fields from a JSON map (nested maps are flattened)
form.fromJson(map, setAsInitial: true);   // same, but also updates initialValue (edit-form pattern)
form.toJson();                            // { name: 'John', email: 'a@b.com', ... }
form.toJson(omitNulls: true);             // prune null fields and empty nested groups
form.toJson(omitDisabled: true);          // exclude disabled fields from the output
form.dirtyValues();                       // subset map containing only fields that changed
form.clearErrors();                       // clear all validation errors at once
form.clearErrors(path: 'addr');           // clear errors for a field/group prefix
form.setErrors({'email': 'Already taken', 'cpf': 'Invalid'}); // apply server-side errors in bulk
form.toQueryString();                     // convert form to URL query parameters
form.completionPercent;                   // fraction (0.0–1.0) of non-disabled, non-computed fields that have a value
form.errors;                              // Map<String, String> of current errors
form.valid;                               // true if errors is empty
form.isDirty;                             // true if any field is dirty
form.isTouched;                           // true if any field is touched
form.isSubmitting;                        // true during submit callback
form.isValidating;                        // true while async validation runs
form.getField<String>('email');           // O(1) lookup
```

`submit()` automatically calls `touchAll()` and `trigger()` before invoking the callback. By default, it will automatically focus and scroll the first invalid field into view.

#### Focus & Scroll on Error
Built-in widgets (like `SignalTextField`) automatically register their `FocusNode` on the backing `Field`'s `focusNode` property during mounting. When validation fails on `submit` (or via `trigger(shouldFocus: true, shouldScroll: true)`):
1. The form controller identifies the first invalid field.
2. It requests focus on its registered node via `node.requestFocus()`.
3. It obtains the widget's context and scrolls it into view using `Scrollable.ensureVisible(context)`.

*Note: For vanilla or custom widgets, manually assign a focus node to the field (`field.focusNode = myFocusNode`) to leverage this behavior.*

#### Form Editing (CRUD) & Reset
- **Patch Value**: To load data into a form for editing (e.g. from an API), use `form.patchValue(Map<String, dynamic> values)`. It takes dot-notation paths (e.g., `'personal.age'`) and updates field values in a single batched operation (notifying UI listeners exactly once).
- **Load from JSON**: `form.fromJson(map)` accepts any JSON map — including nested objects — and populates the matching fields. Pass `setAsInitial: true` to also update each field's `initialValue`, so that a subsequent `reset()` returns to the loaded data instead of the original defaults.
- **Reset**: Call `form.reset()` to restore all fields to their `initialValue` and clear all active errors. You can set the `form.onReset` callback to react to this lifecycle event. Use `form.resetField('path')` to reset a single field.

#### Edit-form pattern

```dart
// After fetching data from an API:
final user = await api.getUser(id);
form.fromJson(user, setAsInitial: true);
// Now isDirty is false, and reset() returns to the loaded values.

// On save — send only what the user actually changed:
await api.patchUser(id, form.dirtyValues());
```

### Nested groups — `formGroup`

```dart
final form = formCtrl(() {
  return (
    account: formGroup('account', () => (
      email: Field<String>('email').required(),
      password: Field<String>('password').required().minLength(8),
    )),
    profile: formGroup('profile', () => (
      name: Field<String>('name').required(),
      age: Field<int>('age').min(0),
    )),
  );
});

// Access:
form.fields.account.email.value;

// toJson produces nested objects:
// { account: { email: '...', password: '...' }, profile: { name: '...', age: 0 } }
```

#### Conditional group — `applyWhen`

Pass `applyWhen:` to apply a shared condition to **every field** inside the group. All fields only validate when the condition is met.

```dart
final form = formCtrl(() => (
  hasBilling: Field<bool>('hasBilling', false),
  billing: formGroup('billing', () => (
    address: Field<String>('address').required(),
    city: Field<String>('city').required(),
  ), applyWhen: (valueOf) => valueOf<bool>('hasBilling').value == true),
));
// address and city validate only when hasBilling is true
```

---

## Validation modes

```dart
// Validate on every keystroke (default)
Field<String>('search').validationMode(ValidationMode.onChange);

// Validate only on blur
Field<String>('email').validationMode(ValidationMode.onBlur);

// Validate only when trigger() or submit() is called
Field<String>('code').validationMode(ValidationMode.onSubmit);
```

---

## Custom validators

### Sync — `must`

```dart
Field<String>('username')
  .must((val) => val != null && !val.contains(' '), message: 'No spaces allowed');
```

### Cross-field — `mustWith`

```dart
Field<DateTime>('endDate')
  .required()
  .mustWith(
    (val, valueOf) => val == null || valueOf<DateTime>('startDate').value == null || val.isAfter(valueOf<DateTime>('startDate').value!),
    message: 'End date must be after start date',
  );
```

> [!TIP]
> For simple equality comparisons (like password confirmation), **prefer using the built-in `.equals()` validator** instead of writing a custom `.mustWith()`:
> ```dart
> Field<String>('confirmPassword')
>   .required()
>   .equals(
>     (valueOf) => valueOf<String>('password'),
>     message: 'Passwords do not match',
>   );
> ```

### Low-level — `addValidator`

```dart
Field<String>('slug')
  .addValidator(
    'Only lowercase letters and hyphens',
    (val) => val != null && !RegExp(r'^[a-z-]+$').hasMatch(val),
  );
```

---

## Async validators

```dart
Field<String>('username')
  .required()
  .addValidatorAsync(
    'Username already taken',
    (val) async {
      if (val == null || val.isEmpty) return false;
      final taken = await myApi.checkUsername(val);
      return taken; // return true = has error
    },
  );
```

> [!NOTE]
> The library automatically handles async race conditions by discarding outdated validation results if the field value changes while the validation request is still in progress.

Add `.debounce()` to avoid a request per keystroke:

```dart
Field<String>('username')
  .required()
  .debounce(const Duration(milliseconds: 500))
  .addValidatorAsync('Username taken', (val) async {
    return await myApi.checkUsername(val ?? '');
  });
```

---

## Conditional validation — `applyWhen`

Run a set of validators only when another field satisfies a condition:

```dart
final form = formCtrl(() => (
  hasCompany: Field<bool>('hasCompany'),
  cnpj: Field<String>('cnpj')
    .applyWhen(
      (valueOf) => valueOf<bool>('hasCompany').value == true,
      (f) => f
        .required(message: 'CNPJ is required')
        .validCNPJ(message: 'Invalid CNPJ'),
    ),
));
```

The shorthand `.when()` on `Field<String>` applies `.required()` conditionally:

```dart
Field<String>('coupon').when(
  (valueOf) => valueOf<String>('plan').value == 'premium',
  message: 'Coupon is required for premium plan',
);
```

---

## Conditional routing — `switchWith`

Route an entire set of validators based on a key derived from another field. Only the matching case runs; the rest are skipped.

```dart
final form = formCtrl(() => (
  country: Field<String>('country', 'BR')
    .oneOf(['BR', 'US', 'EU'], message: 'Invalid country'),
  doc: Field<String>('doc')
    .switchWith<String>(
      (valueOf) => valueOf<String>('country').value,
      {
        'BR': (f) => f.validCPF(message: 'Invalid CPF'),
        'US': (f) => f.addValidator('Invalid SSN', (v) => v == null || v.length != 9),
        'EU': (f) => f.addValidator('Invalid VAT', (v) => v == null || v.length < 5),
      },
      orElse: (f) => f.required(message: 'Document required'),
      dependsOn: ['country'],
    ),
));
```

| Parameter | Description |
|---|---|
| `keySelector` | Function that returns the active case key from other fields |
| `cases` | Map from key value to validator builder — only the matching entry runs |
| `orElse` | Fallback builder that runs when no case matches the current key |
| `dependsOn` | Field paths that, when changed, clear the current error and re-schedule validation |

### Typed keys with sealed classes

The key type `K` can be any Dart type. Using a sealed class (or enum) gives compile-time exhaustiveness: the IDE warns if a new subtype is added without a corresponding case.

```dart
sealed class Country { const Country(); }
final class BR extends Country { const BR(); }
final class US extends Country { const US(); }
final class EU extends Country { const EU(); }

Field<String>('doc').switchWith<Country>(
  (valueOf) => switch (valueOf<String>('country').value) {
    'BR' => const BR(),
    'US' => const US(),
    'EU' => const EU(),
    _    => null,
  },
  {
    const BR(): (f) => f.validCPF(message: 'Invalid CPF'),
    const US(): (f) => f.addValidator('Invalid SSN', (v) => v == null || v.length != 9),
    const EU(): (f) => f.addValidator('Invalid VAT', (v) => v == null || v.length < 5),
  },
  dependsOn: ['country'],
)
```

`const` objects of the same type are canonicalized by Dart — `const BR() == const BR()` is `true` without overriding `operator==`.

---

## Exposed rules (password strength indicator)

Mark individual rules with `exposed: true` to surface them in the UI:

```dart
Field<String>('password')
  .required()
  .minLength(8, message: 'At least 8 characters', exposed: true)
  .mustHaveUppercase(message: 'One uppercase letter', exposed: true)
  .mustHaveNumber(message: 'One number', exposed: true)
  .mustHaveSpecialChar(message: 'One special character', exposed: true);
```

```dart
// In your widget:
for (final rule in form.fields.password.exposedRules)
  Row(children: [
    Icon(rule.isValid ? Icons.check : Icons.close),
    Text(rule.message),
  ]),
```

---

## Input masking

```dart
// Fixed mask — '#' is a placeholder for any alphanumeric character
Field<String>('phone').mask('(##) #####-####');

// Dynamic CPF / CNPJ mask (switches at 11 digits)
Field<String>('document').maskCPFOrCNPJ();

// Keep the formatted value in JSON
Field<String>('card').mask('#### #### #### ####', removeMaskOnJson: false);

// Brazilian ready-made masks
Field<String>('cpf').maskCPF();
Field<String>('cnpj').maskCNPJ();
Field<String>('phone').maskCelular();
Field<String>('zip').maskCEP();                        // XX.XXX-XXX
Field<String>('zip').maskCEP(ponto: false);            // XXXXX-XXX
Field<String>('date').maskData();                      // DD/MM/YYYY
Field<String>('time').maskHora();                      // HH:mm
Field<String>('amount').maskDecimal(casasDecimais: 2); // 9.999.999.999,00
```

The JSON value strips mask characters by default (`removeMaskOnJson: true`).

### Mask reference

All masks accept a `removeMaskOnJson` parameter (default `true`) that controls whether formatting is stripped when accessing `field.jsonValue`. Decimal masks convert the comma to a dot in JSON output (e.g. `1,82` → `1.82`).

#### Generic mask

| Method | Format | Description |
|---|---|---|
| `mask(pattern)` | customizable | `#` matches any alphanumeric character |

#### Brazilian formatting masks

Ready-made formatters for the document, currency, and data-entry standards used in Brazil.

| Method | Format | Description |
|---|---|---|
| `maskAltura()` | `1,82` | Height in meters,centimeters (max 3 digits) |
| `maskCartaoCredito()` | `0000 1111 2222 3333` | Credit card (16 digits, groups of 4) |
| `maskCartaoTelefone()` | `000 1111 2222 3333` | Phone card (15 digits: 3 + 4 + 4 + 4) |
| `maskCEP({ponto})` | `XX.XXX-XXX` / `XXXXX-XXX` | Brazilian ZIP — `ponto: false` removes the leading dot |
| `maskCertidaoNascimento()` | `XXXXXX XX XX XXXX X XXXXX XXX XXXXXXX XX` | Birth certificate (32 digits) |
| `maskCEST()` | `XX.XXX.XX` | CEST code (7 digits) |
| `maskCNPJ()` | `99.999.999/9999-99` | Numeric CNPJ |
| `maskCNPJAlfanumerico()` | `XX.XXX.XXX/XXXX-XX` | Alphanumeric CNPJ — new 2024 format (14 chars, uppercased) |
| `maskCPF()` | `XXX.XXX.XXX-XX` | CPF (11 digits) |
| `maskCPFOrCNPJ()` | dynamic | CPF (≤ 11 digits) or CNPJ (12–14 digits) |
| `maskData()` | `DD/MM/YYYY` | Date |
| `maskDecimal({casasDecimais})` | `9.999.999.999,00` | Decimal with BR separators; `casasDecimais` sets decimal places (default: 2) |
| `maskHora()` | `HH:mm` | Time — clamps hour to 0–23 and minute to 0–59 |
| `maskIOF()` | `1,234567` | IOF rate (1 integer digit + 6 decimal digits) |
| `maskKm()` | `000.000` | Odometer reading (6 digits) |
| `maskNCM()` | `XXXX.XX.XX` | NCM tariff code (8 digits) |
| `maskNUP()` | `XXXXXXX-XX.XXXX.X.XX.XXXX` | NUP — unique process number (20 digits) |
| `maskPeso()` | `103,8` | Weight in kg.g — last digit is decimal, no thousands separator |
| `maskPlacaVeiculo()` | `XXX-XXXX` | Vehicle plate (old and Mercosul formats, uppercased) |
| `maskReal()` | `999.999.999.999` | Integer BRL amount with dot thousands separator |
| `maskCelular()` | `(99) 99999-9999` | Brazilian mobile phone (11 digits) |
| `maskTemperatura()` | `10,8` | Temperature in °C — last digit is decimal, no thousands separator |
| `maskValidade({maxLength})` | `MM/AA` / `MM/AAAA` | Card expiry — `maxLength: 4` (default) or `6` |

---

## `toJson` transformer

```dart
Field<String>('birthdate')
  .mask('##/##/####')
  .transformToJson((val) {
    if (val == null) return null;
    final parts = val.split('/');
    return '${parts[2]}-${parts[1]}-${parts[0]}';
  });
```

---

## Lifecycle callbacks

```dart
final field = Field<String>('email')
  ..onValueChanged = (old, next) => print('changed: $old → $next')
  ..onValidationStart = () => print('validating…')
  ..onValidationEnd = (isValid, error) => print('valid=$isValid error=$error');

form
  ..onSubmitStart = () => showLoader()
  ..onSubmitEnd = (success) => hideLoader()
  ..onReset = () => print('form reset');
```

---

## Widgets

All widgets auto-register a `FocusNode`, call `touch()` on blur, and show `field.error` only after the field is touched.

### `SignalTextField`

```dart
SignalTextField(
  field: form.fields.name,
  decoration: const InputDecoration(labelText: 'Name'),
  keyboardType: TextInputType.name,
  obscureText: false,
  maxLines: 1,
);
```

### `SignalDropdown<T>`

```dart
SignalDropdown<String>(
  field: form.fields.country,
  decoration: const InputDecoration(labelText: 'Country'),
  hint: const Text('Select…'),
  items: const [
    DropdownMenuItem(value: 'BR', child: Text('Brazil')),
    DropdownMenuItem(value: 'US', child: Text('United States')),
  ],
);
```

### `SignalCheckbox`

```dart
SignalCheckbox(
  field: form.fields.acceptTerms,
  title: const Text('I accept the terms of service'),
);
```

### `SignalSwitch`

```dart
SignalSwitch(
  field: form.fields.notifications,
  title: const Text('Enable notifications'),
);
```

### `SignalRadioGroup<T>`

```dart
SignalRadioGroup<String>(
  field: form.fields.gender,
  decoration: const InputDecoration(labelText: 'Gender'),
  options: const [
    SignalFieldOption(value: 'M', label: 'Male'),
    SignalFieldOption(value: 'F', label: 'Female'),
    SignalFieldOption(value: 'O', label: 'Other'),
  ],
);
```

### `SignalCheckboxGroup<T>`

```dart
SignalCheckboxGroup<String>(
  field: form.fields.hobbies,
  decoration: const InputDecoration(labelText: 'Hobbies'),
  options: const [
    SignalFieldOption(value: 'music', label: 'Music'),
    SignalFieldOption(value: 'sports', label: 'Sports'),
    SignalFieldOption(value: 'tech', label: 'Tech'),
  ],
);
```

### `SignalSlider`

```dart
SignalSlider(
  field: form.fields.volume,
  min: 0,
  max: 100,
  decoration: const InputDecoration(labelText: 'Volume'),
);
```

### `SignalRangeSlider`

```dart
SignalRangeSlider(
  field: form.fields.priceRange,
  min: 0,
  max: 1000,
  decoration: const InputDecoration(labelText: 'Price range'),
);
```

### `SignalDateTimePicker`

```dart
SignalDateTimePicker(
  field: form.fields.birthdate,
  decoration: const InputDecoration(labelText: 'Birth date'),
  firstDate: DateTime(1900),
  lastDate: DateTime.now(),
);
```

### `SignalDateRangePicker`

```dart
SignalDateRangePicker(
  field: form.fields.period,
  decoration: const InputDecoration(labelText: 'Period'),
  firstDate: DateTime.now(),
  lastDate: DateTime.now().add(const Duration(days: 365)),
);
```

### `SignalChoiceChip<T>` and `SignalFilterChip<T>`

```dart
SignalChoiceChip<String>(
  field: form.fields.size,
  options: const [
    SignalFieldOption(value: 'S', label: 'Small'),
    SignalFieldOption(value: 'M', label: 'Medium'),
    SignalFieldOption(value: 'L', label: 'Large'),
  ],
);
```

---

## Vanilla Flutter inputs — `SignalFormField<T>`

Use `SignalFormField` to wire any Flutter widget to a `Field` without a dedicated Signal widget:

```dart
SignalFormField<DateTime>(
  field: form.fields.appointment,
  builder: (context, field) {
    return ListTile(
      title: Text(
        field.value != null
            ? DateFormat.yMd().format(field.value!)
            : 'Pick a date',
      ),
      trailing: const Icon(Icons.calendar_today),
      subtitle: field.isTouched && field.error != null
          ? Text(field.error!, style: const TextStyle(color: Colors.red))
          : null,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: field.value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          field.value = picked;
          field.touch();
        }
      },
    );
  },
);
```

The builder is called every time `field` notifies listeners — you get the full `Field<T>` object with access to `value`, `error`, `isLoading`, `isTouched`, etc.

---

## Validation reference

### `Field<String>`

| Method | Description |
|---|---|
| `required()` | Not null and not blank |
| `notEmpty()` | Alias for `required` |
| `minLength(n)` | At least `n` characters |
| `maxLength(n)` | At most `n` characters |
| `length(n)` | Exactly `n` characters |
| `email()` | Valid e-mail format |
| `validUrl()` | Valid URL |
| `httpUrl()` | HTTP/HTTPS URL |
| `hostname()` | Valid hostname |
| `pattern(regex)` | Matches a `RegExp` |
| `alphanumeric()` | Only letters and digits |
| `numeric()` | Only digits |
| `uppercase()` | All uppercase |
| `lowercase()` | All lowercase |
| `contains(s)` | Contains substring |
| `startsWith(s)` | Starts with prefix |
| `endsWith(s)` | Ends with suffix |
| `mustHaveLowercase()` | At least one lowercase letter |
| `mustHaveUppercase()` | At least one uppercase letter |
| `mustHaveNumber()` | At least one digit |
| `mustHaveSpecialChar()` | At least one special character |
| `matches(path)` | Equal to sibling field by path |
| `equals((valueOf) => ...)` | Equal to a field resolved via `valueOf` |
| `oneOf(list)` | Value is one of the allowed values |
| `uuid()` / `uuidv4()` / `uuidv6()` / `uuidv7()` | UUID format |
| `guid()` | Alias for `uuidv4` |
| `cuid()` / `cuid2()` | CUID format |
| `nanoid(size)` | Nano ID format |
| `ulid()` | ULID format |
| `date()` / `isoDate()` | `YYYY-MM-DD` |
| `time()` | `HH:mm:ss` |
| `datetime()` / `isoDatetime()` | ISO 8601 datetime |
| `isoTime()` | ISO time with timezone |
| `isoDuration()` | ISO 8601 duration |
| `ipv4()` / `ipv6()` | IP address |
| `cidrv4()` / `cidrv6()` | CIDR notation |
| `mac()` | MAC address |
| `base64()` / `base64url()` | Base64 |
| `hex()` | Hexadecimal |
| `jwt()` | JWT structure |
| `emoji()` | Contains at least one emoji |
| `hash(algorithm)` | Hash hex string (md5, sha1, sha256, …) |
| `hasNoSequentialRepeatedCharacters()` | No `aaa`, `111`, etc. |
| `hasNoSequentialCharacters()` | No `abc`, `123`, `321`, etc. |
| `when(condition)` | Conditionally required |
| **Brazilian** | |
| `validCPF()` | CPF with check-digit |
| `validCNPJ()` | Numeric CNPJ with check-digit |
| `validCNPJAlfanumerico()` | Alphanumeric CNPJ with check-digit (new 2024 format) |
| `validCPFOrCNPJ()` | CPF or CNPJ |
| `validCEP()` | Brazilian ZIP code |
| `validPhoneBR()` | Brazilian mobile number |
| `validPhoneWithCountryCodeBR()` | Brazilian mobile with +55 |
| `validCreditCard()` | Luhn algorithm |
| `maskCPFOrCNPJ()` | Dynamic CPF/CNPJ mask |

### `Field<num>` / `Field<int>` / `Field<double>`

| Method | Description |
|---|---|
| `required()` | Not null |
| `min(n)` | ≥ n |
| `max(n)` | ≤ n |
| `range(min, max)` | Between min and max |
| `positive()` | > 0 |
| `negative()` | < 0 |
| `nonnegative()` | ≥ 0 |
| `nonZero()` | ≠ 0 |
| `greaterThan(n)` | > n |
| `lessThan(n)` | < n |
| `multipleOf(n)` / `step(n)` | Divisible by n |
| `even()` / `odd()` | Integer only |

### `Field<bool>`

| Method | Description |
|---|---|
| `required()` | Not null |
| `mustBeTrue()` | Must be `true` (e.g. terms acceptance) |
| `mustBeFalse()` | Must be `false` |

### `Field<List<T>>`

| Method | Description |
|---|---|
| `required()` | Not null and not empty |
| `minItems(n)` | At least `n` items |
| `maxItems(n)` | At most `n` items |
| `itemCount(n)` | Exactly `n` items |
| `contains(item)` | List contains item |
| `addItem(item)` | Mutate helper |
| `removeItem(item)` | Mutate helper |
| `removeAt(index)` | Mutate helper |
| `clear()` | Mutate helper |

List-item validators via `applyEach`:

```dart
Field<List<String>>('tags')
  .minItems(1, message: 'At least one tag')
  .applyEach<String>(
    (itemField) => itemField.minLength(2, message: 'Tag too short'),
    formatError: (i, msg) => 'Tag $i: $msg',
  );
```

### `Field<DateTime>`

| Method | Description |
|---|---|
| `required()` | Not null |
| `after((valueOf) => ...)` | After another field's date |
| `afterDate(date)` | After a fixed date |
| `before((valueOf) => ...)` | Before another field's date |
| `beforeDate(date)` | Before a fixed date |
| `inPast()` | Before now |
| `inFuture()` | After now |
| `between(start, end)` | Within a range |
| `inclusiveBetween(start, end)` | Inclusive range |
| `exclusiveBetween(start, end)` | Exclusive range |
| `greaterThan(date)` | Strictly after date |
| `greaterThanOrEqualTo(date)` | On or after date |
| `lessThan(date)` | Strictly before date |
| `lessThanOrEqualTo(date)` | On or before date |

### Generic (`Field<T>`)

| Method | Description |
|---|---|
| `required()` | Value must not be `null` — works on any `Field<T>` (e.g. `Field<int>`, `Field<bool>`, `Field<MyEnum>`) |
| `must((val) => bool)` | Custom sync rule |
| `mustWith((val, valueOf) => bool)` | Custom rule with access to other fields |
| `equalTo(other)` | Value equals a fixed value |
| `isNull()` | Must be null |
| `isNotNull()` | Must not be null |
| `oneOf(allowedValues)` | Value is one of the allowed values; `null`/empty passes (combine with `required`) |

---

## Extending with custom validators

Add your own validators as Dart extensions on `Field<YourType>`.

### Sync extension

```dart
extension PasswordFieldValidators on Field<String> {
  Field<String> strongPassword({String message = 'Password too weak'}) {
    return addValidator(message, (val) {
      if (val == null || val.length < 8) return true;
      if (!RegExp(r'[A-Z]').hasMatch(val)) return true;
      if (!RegExp(r'[0-9]').hasMatch(val)) return true;
      if (!RegExp(r'[!@#$]').hasMatch(val)) return true;
      return false;
    });
  }
}
```

### Async extension

Use `addValidatorAsync` inside the extension to hit an API or database:

```dart
extension UsernameFieldValidators on Field<String> {
  Field<String> uniqueUsername({String message = 'Username already taken'}) {
    return addValidatorAsync(message, (val) async {
      if (val == null || val.isEmpty) return false;
      final taken = await UserRepository.isUsernameTaken(val);
      return taken; // true = has error
    });
  }
}
```

Combine with `.debounce()` to avoid a request per keystroke:

```dart
Field<String>('username')
  .required()
  .minLength(3)
  .debounce(const Duration(milliseconds: 500))
  .uniqueUsername(message: 'This username is already in use');
```

Usage is identical to built-in validators — sync and async extensions chain freely:

```dart
Field<String>('password').required().strongPassword();
Field<String>('username').required().uniqueUsername();
```

---

## AI-Assisted Development

`signal_form` ships with a [`SKILL.md`](SKILL.md) file — a compact, structured reference of the entire API optimized for AI assistants. It covers the full `Field<T>` and `FormController` APIs, all built-in validators, widgets, conditional/cross-field validation patterns, async race-condition handling, and end-to-end examples.

### How to use it

Feed `SKILL.md` to your AI assistant before asking questions about `signal_form`:

**Claude / Claude Code**
```
Read the contents of SKILL.md and use it as context for any signal_form questions.
```

**Cursor**
Add a reference in your `.cursorrules` file or paste the contents into the chat context window.

**GitHub Copilot / other assistants**
Open `SKILL.md` in your editor and mention it in your prompt, or paste the relevant sections directly into the chat.

With the skill loaded, you can ask things like *"Create a registration form with CPF validation and async username check"* and the assistant will generate idiomatic `signal_form` code without guessing the API.
