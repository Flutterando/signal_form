# signal_form

> 🇧🇷 [Leia em Português](README.pt-br.md)

Managing complex forms in Flutter often means juggling `TextEditingController`, `GlobalKey<FormState>`, scattered validation logic, and imperative state updates. **signal_form** was built to unify and simplify all of that.

Inspired by [Angular Signal Forms](https://angular.dev/essentials/signal-forms), it brings a **schema-based, strongly typed** approach to Flutter forms: you declare your fields and validation rules once, in a single place, and the library takes care of the rest.

- **Declarative validation** — rules live next to the field they belong to, not scattered across the widget tree
- **Fluent API** — chain validators in a single expression with low verbosity and high readability
- **High performance** — fields notify only their own listeners; the form-level cache avoids redundant recomputation
- **Data formatting and transformation** — built-in input masking and `toJson` transformers keep raw and serialized values in sync automatically
- **Ready-made widgets** — drop-in Material components (`SignalTextField`, `SignalDropdown`, `SignalCheckbox`, and more) with error display, focus handling, and automatic scroll to the first invalid field wired up out of the box
- **Extensible** — add your own sync or async validators as plain Dart extension methods, indistinguishable from the built-ins

## Features

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
| `initialValue` | `T?` | Value the field was initialized with |
| `exposedRules` | `List<({String message, bool isValid})>` | Rules marked with `exposed: true` |

| Method | Description |
|---|---|
| `touch()` | Mark field as touched |
| `reset()` | Restore to initial value, clear errors |
| `invalidate(message)` | Set a manual error |
| `validate()` | Run sync validators, returns `bool` |
| `validateAsync()` | Run all validators, returns `Future<bool>` |
| `debounce(duration)` | Throttle validation |
| `validationMode(mode)` | Set `onChange`, `onBlur`, or `onSubmit` |

### `FormController<T>`

Returned by `formCtrl`. Holds all fields and coordinates validation.

```dart
form.submit((f) async { ... });   // validate all, call on success
form.trigger();                    // validate all without submitting
form.trigger(path: 'email');       // validate only a specific field/group
form.reset();                      // reset all fields
form.resetField('email');          // reset one field
form.patchValue({'name': 'John'}); // set multiple values
form.setValue('email', 'a@b.com');
form.toJson();                     // { name: 'John', email: 'a@b.com', ... }
form.toJson(omitNulls: true);      // same, but null fields and empty nested groups are pruned
form.errors;                       // Map<String, String> of current errors
form.valid;                        // true if errors is empty
form.isDirty;                      // true if any field is dirty
form.isTouched;                    // true if any field is touched
form.isSubmitting;                 // true during submit callback
form.isValidating;                 // true while async validation runs
form.getField<String>('email');    // O(1) lookup
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
- **Reset**: Call `form.reset()` to restore all fields to their `initialValue` and clear all active errors. You can set the `form.onReset` callback to react to this lifecycle event. Use `form.resetField('path')` to reset a single field.

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
// Fixed mask — '#' is a placeholder for any character
Field<String>('phone').mask('(##) #####-####');

// Dynamic CPF / CNPJ mask (switches at 11 digits)
Field<String>('document').maskCPFOrCNPJ();

// Keep the formatted value in JSON
Field<String>('card').mask('#### #### #### ####', removeMaskOnJson: false);
```

The JSON value strips mask characters by default (`removeMaskOnJson: true`).

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
| `validCNPJ()` | CNPJ with check-digit |
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
| `must((val) => bool)` | Custom sync rule |
| `mustWith((val, valueOf) => bool)` | Custom rule with access to other fields |
| `equalTo(other)` | Value equals a fixed value |
| `isNull()` | Must be null |
| `isNotNull()` | Must not be null |

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
