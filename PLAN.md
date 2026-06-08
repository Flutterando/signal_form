# Plano: 3 novos recursos para signal_form

## Context

Baseado em sugestão do Gemini para evoluir a lib com features que resolvem dores reais em formulários Flutter complexos. Todos os 3 recursos são implementados em `lib/src/core.dart`.

---

## Feature 1: `applyWhen` no nível do `formGroup`

### Objetivo
Permitir que uma condição seja aplicada a todos os campos de um grupo de uma vez, eliminando repetição de `applyWhen` por campo.

### API proposta
```dart
formGroup('billing', () => (
  street: Field<String>('street')..required(),
  zip: Field<String>('zip')..cep(),
), applyWhen: (valueOf) => valueOf<bool>('hasBilling').value == true);
```

### Implementação em `lib/src/core.dart`

**1. Adicionar `getFieldsFrom(int start)` no `FormTracker`** (após linha 54):
```dart
static List<Field> getFieldsFrom(int startIndex) {
  final fields = _currentContext?.fields;
  if (fields == null || startIndex >= fields.length) return const [];
  return fields.sublist(startIndex);
}
```

**2. Adicionar `_applyGroupCondition` na classe `Field<T>`** (após `applyWhen`, ~linha 649):
Itera `_syncValidators` e `_asyncValidators` e substitui cada record por um novo record cujo `hasError` verifica a condição de grupo antes de executar o predicado original.
```dart
void _applyGroupCondition(bool Function(ValueOf valueOf) groupCondition) {
  for (var i = 0; i < _syncValidators.length; i++) {
    final existing = _syncValidators[i];
    _syncValidators[i] = (
      message: existing.message,
      dynamicMessage: existing.dynamicMessage,
      exposedMessage: existing.exposedMessage,
      hasError: (val) {
        if (form == null) return false;
        Field<O> valueOf<O>(String path) => form!.getField<O>(path);
        if (!groupCondition(valueOf)) return false;
        return existing.hasError(val);
      },
    );
  }
  // mesma lógica para _asyncValidators
}
```

**3. Modificar `formGroup`** para aceitar `applyWhen` opcional e, após o builder, capturar os fields adicionados e chamar `_applyGroupCondition` em cada um:
```dart
T formGroup<T>(String name, T Function() builder, {
  bool Function(ValueOf valueOf)? applyWhen,
}) {
  FormTracker.pushPath(name);
  final countBefore = FormTracker.currentFieldCount;  // nova property
  try {
    final result = builder();
    if (applyWhen != null) {
      for (final field in FormTracker.getFieldsFrom(countBefore)) {
        field._applyGroupCondition(applyWhen);
      }
    }
    return result;
  } finally {
    FormTracker.popPath();
  }
}
```

### Composição de condições
Condição de grupo wrapa os `hasError` já existentes (que podem ter condição de campo dentro). Resultado: AND lógico — ambas devem ser true para o validador rodar. Correto.

---

## Feature 2: `toJson(omitNulls: true)`

### API proposta
```dart
form.toJson(omitNulls: true) // exclui chaves cujo valor é null
```

### Implementação em `lib/src/core.dart`

**1. Adicionar segundo slot de cache em `FormController`** (perto da linha 1084):
```dart
Map<String, dynamic>? _jsonCache;
Map<String, dynamic>? _jsonCacheOmitNulls;  // novo
```

**2. Atualizar `_invalidateCache`**: zerar ambos os caches.

**3. Atualizar `toJson`** (linha 1570):
```dart
Map<String, dynamic> toJson({bool omitNulls = false}) {
  if (!omitNulls && _jsonCache != null) return _jsonCache!;
  if (omitNulls && _jsonCacheOmitNulls != null) return _jsonCacheOmitNulls!;

  final map = <String, dynamic>{};
  for (var field in _capturedFields) {
    final v = field.jsonValue;
    if (omitNulls && v == null) continue;
    _putNestedValue(map, field.pathSegments, v);
  }

  if (omitNulls) _jsonCacheOmitNulls = map; else _jsonCache = map;
  return map;
}
```

**Nota:** `omitNulls` omite apenas folhas nulas. Não poda mapas aninhados que ficarem vazios (comportamento simples e correto para o caso de uso).

---

## Feature 3: `switchWith()` — validação dinâmica no mesmo campo

### API proposta
```dart
final form = formCtrl(() => (
  paisResidencia: Field<String>('paisResidencia', 'BR')
    .required(message: 'A jurisdição é obrigatória')
    .oneOf(['BR', 'US'], message: 'Jurisdição inválida'),
  documentoFiscal: Field<String>('documentoFiscal')
    .switchWith<String>(
      (valueOf) => valueOf<String>('paisResidencia').value,
      {
        'BR': (f) => f.required().validCPFOrCNPJ(),
        'US': (f) => f.required().numeric().length(9),
      },
      dependsOn: 'paisResidencia',  // opcional: limpa erro e re-valida quando mudar
    ),
));
```

- `K` é o tipo da chave do seletor (pode ser `String`, `enum`, `int`, etc.)
- O primeiro argumento retorna o valor atual do "modo" — pode ser `null` se nenhum case deve rodar
- O segundo argumento é um `Map<K, void Function(Field<T>)>` de N casos (não apenas binário)
- `dependsOn` (opcional): path do campo a observar para GC de erros

### Implementação em `lib/src/core.dart`

**1. Adicionar `_deferredSetup` em `Field<T>`** (perto da linha 186):
```dart
final List<void Function()> _deferredSetup = [];
```

**2. Converter `form` de campo público para getter/setter** (linha 165).  
O setter executa os deferred setups quando o form é atribuído:
```dart
FormController<dynamic>? _form;
FormController<dynamic>? get form => _form;
set form(FormController<dynamic>? fc) {
  _form = fc;
  if (fc != null) {
    for (final setup in _deferredSetup) setup();
    _deferredSetup.clear();
  }
}
```
> Todos os acessos existentes a `.form` (getter/assignment) continuam funcionando sem alteração de sintaxe.

**3. Adicionar método `switchWith<K>` em `Field<T>`** (após `applyWhen`):
```dart
/// Registra múltiplos conjuntos de validadores baseados no valor retornado
/// por [keySelector]. Apenas o conjunto cujo key == valor atual do seletor
/// é executado durante a validação.
///
/// [K] é o tipo da chave (String, enum, int, etc.).
/// [keySelector] recebe [ValueOf] e retorna o valor atual do "modo".
/// [cases] é um mapa de valor → builder de validadores.
/// [dependsOn] (opcional): path do campo a observar — quando muda, limpa o erro
/// e agenda re-validação (em [ValidationMode.onChange]).
Field<T> switchWith<K>(
  K? Function(ValueOf valueOf) keySelector,
  Map<K, void Function(Field<T> self)> cases, {
  String? dependsOn,
}) {
  for (final entry in cases.entries) {
    applyWhen(
      (valueOf) => keySelector(valueOf) == entry.key,
      entry.value,
    );
  }

  if (dependsOn != null) {
    _deferredSetup.add(() {
      final watched = form?.tryGetField<dynamic>(dependsOn);
      if (watched == null) return;
      watched.addListener(() {
        if (_isDisposed) return;
        if (_error != null) {
          _error = null;
          _notifyIfMounted();
          form?._invalidateCache();
        }
        if (_validationMode == ValidationMode.onChange) {
          _scheduleValidation();
        }
      });
    });
  }
  return this;
}
```

### GC de erros
- Com `dependsOn`: quando o campo observado muda, o erro do campo é limpo imediatamente e (em `onChange`) re-validação é agendada com o novo conjunto de validators.
- Sem `dependsOn`: erro persiste até a próxima validação explícita (`form.trigger()` ou mudança no próprio campo).
- Se `keySelector` retorna `null` ou um valor sem case correspondente: todos os validators são pulados (campo fica válido).

---

## Novos testes

Criar `test/new_features_test.dart` com grupos:
- `'formGroup – applyWhen'`: condição false pula todos do grupo, true roda, composição com field-level applyWhen (AND), assíncrono.
- `'FormController – toJson(omitNulls)'`: inclui null por padrão, exclui com flag, cache independente, invalidação de cache, campo aninhado.
- `'Field – switchWith'`: case correto roda, outros pulados, N cases (não só 2), key null/sem match → campo válido, `dependsOn` limpa erro, re-valida em onChange, não re-valida em onSubmit, sem `dependsOn` erro persiste.

---

## Ordem de implementação (menor risco primeiro)

1. **Feature 2** (`toJson omitNulls`) — mudança mínima, sem acoplamento
2. **Feature 1** (`formGroup applyWhen`) — adiciona método privado e parâmetro opcional
3. **Feature 3** (`switchWith`) — mais invasivo: converte `form` em getter/setter. Fazer `grep -n "\.form"` em `core.dart` antes para mapear todos os sites de atribuição/leitura.

---

## Verificação

```bash
flutter test test/new_features_test.dart  # novos testes
flutter test                              # suite completa (sem regressões)
```
