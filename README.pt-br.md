# signal_form

> 🇺🇸 [Read in English](README.md)

Gerenciar formulários complexos no Flutter costuma significar equilibrar `TextEditingController`, `GlobalKey<FormState>`, lógica de validação espalhada pelo código e atualizações de estado imperativas. O **signal_form** foi criado para unificar e simplificar tudo isso.

Inspirado no [Angular Signal Forms](https://angular.dev/essentials/signal-forms), ele traz uma abordagem **baseada em schema e fortemente tipada** para formulários Flutter: você declara seus campos e regras de validação uma única vez, em um só lugar, e a biblioteca cuida do resto.

- **Validação declarativa** — as regras ficam junto ao campo ao qual pertencem, não espalhadas pela árvore de widgets
- **API fluente** — encadeie validadores em uma única expressão com baixa verbosidade e alta legibilidade
- **Alto desempenho** — cada campo notifica apenas seus próprios ouvintes; o cache do formulário evita recomputações desnecessárias
- **Formatação e transformação de dados** — máscaras de entrada e transformadores `toJson` mantêm os valores brutos e serializados sincronizados automaticamente
- **Widgets prontos** — componentes Material prontos para uso (`SignalTextField`, `SignalDropdown`, `SignalCheckbox` e outros) com exibição de erros, gerenciamento de foco e scroll automático até o primeiro campo inválido já configurados
- **Extensível** — adicione seus próprios validadores síncronos ou assíncronos como simples extension methods Dart, indistinguíveis dos embutidos

## Funcionalidades

- **Schema-first** — defina a estrutura do formulário em Dart records puro; sem `GlobalKey<FormState>` ou `TextEditingController` para gerenciar
- **API de validação fluente** — encadeie validadores diretamente na declaração de cada `Field`
- **Validadores síncronos e assíncronos** — proteção nativa contra race conditions em validações async
- **Debounce** — throttle de validação em campos com muita digitação
- **Modos de validação** — `onChange`, `onBlur` ou `onSubmit`
- **Validação condicional** — `applyWhen` ativa regras somente quando outro campo satisfaz uma condição
- **Validação entre campos** — compare ou referencie campos irmãos via `valueOf`
- **Máscara de entrada** — `mask()` embutido com remoção automática no JSON
- **Auto-scroll em erros** — `submit()` e `trigger()` focam/rolam para o primeiro campo inválido
- **Widgets prontos** — `SignalTextField`, `SignalDropdown`, `SignalCheckbox`, `SignalSwitch`, `SignalRadioGroup`, `SignalCheckboxGroup`, `SignalSlider`, `SignalRangeSlider`, `SignalDateTimePicker`, `SignalDateRangePicker`, `SignalChoiceChip`, `SignalFilterChip`
- **Alto desempenho** — cada campo notifica apenas seus próprios ouvintes; um cache no nível do formulário evita recomputações desnecessárias a cada rebuild
- **Fortemente tipado** — cada `Field<T>`, validador e valor do `toJson` é completamente tipado de ponta a ponta; sem vazamentos de `dynamic` no nível do formulário
- **Escape hatch** — `SignalFormField<T>` conecta qualquer widget Flutter a um `Field` com reatividade completa

---

## Instalação

```yaml
dependencies:
  signal_form: ^0.0.1
```

```dart
import 'package:signal_form/signal_form.dart';
```

---

## Início rápido

### 1. Defina o schema

```dart
final form = formCtrl(() {
  return (
    nome: Field<String>('nome')
      .required(message: 'Nome é obrigatório')
      .minLength(3, message: 'Mínimo de 3 caracteres'),
    email: Field<String>('email')
      .required(message: 'E-mail é obrigatório')
      .email(message: 'E-mail inválido'),
    idade: Field<int>('idade')
      .required(message: 'Idade é obrigatória')
      .min(18, message: 'Deve ter 18 anos ou mais'),
  );
});
```

`formCtrl` captura todos os `Field` criados dentro do builder e retorna um `FormController` tipado.

### 2. Conecte os widgets

Use o `ListenableBuilder` para fazer a sua UI reagir ao estado global do formulário (como status de validação e estado de carregamento de submissão):

```dart
Column(
  children: [
    SignalTextField(
      field: form.fields.nome,
      decoration: const InputDecoration(labelText: 'Nome'),
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
          // Desabilita o botão se o formulário for inválido ou se estiver submetendo
          onPressed: form.valid && !form.isSubmitting
              ? () => form.submit((f) async {
                  await minhaApi.salvar(f.toJson());
                })
              : null,
          child: form.isSubmitting
              ? const CircularProgressIndicator()
              : const Text('Enviar'),
        );
      },
    ),
  ],
)
```

### 3. Descarte

Sempre chame `form.dispose()` no método `dispose` do seu `StatefulWidget` para liberar os campos capturados e ouvintes internos, evitando vazamentos de memória:

```dart
@override
void dispose() {
  form.dispose();
  super.dispose();
}
```

---

## API principal

### `Field<T>`

O bloco fundamental. Cada campo é tipado, reativo e independente.

```dart
Field<String>('usuario')
  .required(message: 'Obrigatório')
  .minLength(3, message: 'Mínimo 3 caracteres')
  .maxLength(20, message: 'Máximo 20 caracteres');
```

| Propriedade | Tipo | Descrição |
|---|---|---|
| `value` | `T?` | Valor atual (leitura/escrita) |
| `error` | `String?` | Erro de validação atual |
| `isDirty` | `bool` | Valor difere do valor inicial |
| `isTouched` | `bool` | Campo já foi interagido |
| `isLoading` | `bool` | Validação assíncrona em andamento |
| `initialValue` | `T?` | Valor com que o campo foi inicializado |
| `exposedRules` | `List<({String message, bool isValid})>` | Regras marcadas com `exposed: true` |

| Método | Descrição |
|---|---|
| `touch()` | Marca o campo como tocado |
| `reset()` | Restaura o valor inicial e limpa erros |
| `invalidate(message)` | Define um erro manualmente |
| `validate()` | Executa validadores síncronos, retorna `bool` |
| `validateAsync()` | Executa todos os validadores, retorna `Future<bool>` |
| `debounce(duration)` | Throttle da validação |
| `validationMode(mode)` | Define `onChange`, `onBlur` ou `onSubmit` |

### `FormController<T>`

Retornado por `formCtrl`. Agrega todos os campos e coordena a validação.

```dart
form.submit((f) async { ... });    // valida tudo, chama ao ter sucesso
form.trigger();                     // valida tudo sem submeter
form.trigger(path: 'email');        // valida apenas um campo/grupo específico
form.reset();                       // reseta todos os campos
form.resetField('email');           // reseta um campo
form.patchValue({'nome': 'João'});  // define múltiplos valores
form.setValue('email', 'a@b.com');
form.toJson();                      // { nome: 'João', email: 'a@b.com', ... }
form.errors;                        // Map<String, String> de erros atuais
form.valid;                         // true se errors estiver vazio
form.isDirty;                       // true se algum campo for dirty
form.isTouched;                     // true se algum campo for touched
form.isSubmitting;                  // true durante o callback de submit
form.isValidating;                  // true enquanto validação async roda
form.getField<String>('email');     // busca O(1) por nome
```

`submit()` chama `touchAll()` e `trigger()` automaticamente antes do callback. Por padrão, ele também foca e rola automaticamente o primeiro campo inválido para a tela.

#### Foco & Scroll em Erros
Os widgets prontos (como `SignalTextField`) registram automaticamente seu `FocusNode` na propriedade `focusNode` do respectivo `Field` ao serem montados. Quando a validação falha no `submit` (ou através de `trigger(shouldFocus: true, shouldScroll: true)`):
1. O controller do formulário localiza o primeiro campo inválido.
2. Solicita foco no nó registrado via `node.requestFocus()`.
3. Obtém o contexto do widget e o rola para exibição na tela usando `Scrollable.ensureVisible(context)`.

*Nota: Para widgets Flutter vanilla ou customizados, atribua manualmente o focus node ao campo (`field.focusNode = meuFocusNode`) para aproveitar esse comportamento.*

#### Edição de Formulário (CRUD) & Reset
- **Patch Value**: Para preencher dados em um formulário para edição (ex: dados vindos de uma API), use `form.patchValue(Map<String, dynamic> values)`. Ele aceita caminhos em dot-notation (ex: `'personal.idade'`) e atualiza os valores dos campos em uma única operação em lote (notificando os ouvintes da interface apenas uma vez).
- **Reset**: Chame `form.reset()` para restaurar todos os campos ao seu `initialValue` e limpar todos os erros de validação ativos. Você pode definir o callback `form.onReset` para reagir a este evento. Use `form.resetField('caminho')` para resetar apenas um campo.

### Grupos aninhados — `formGroup`

```dart
final form = formCtrl(() {
  return (
    conta: formGroup('conta', () => (
      email: Field<String>('email').required(),
      senha: Field<String>('senha').required().minLength(8),
    )),
    perfil: formGroup('perfil', () => (
      nome: Field<String>('nome').required(),
      idade: Field<int>('idade').min(0),
    )),
  );
});

// Acesso:
form.fields.conta.email.value;

// toJson gera objetos aninhados:
// { conta: { email: '...', senha: '...' }, perfil: { nome: '...', idade: 0 } }
```

---

## Modos de validação

```dart
// Valida a cada tecla pressionada (padrão)
Field<String>('busca').validationMode(ValidationMode.onChange);

// Valida somente ao perder o foco
Field<String>('email').validationMode(ValidationMode.onBlur);

// Valida apenas quando trigger() ou submit() é chamado
Field<String>('codigo').validationMode(ValidationMode.onSubmit);
```

---

## Validadores customizados

### Síncrono — `must`

```dart
Field<String>('usuario')
  .must((val) => val != null && !val.contains(' '), message: 'Sem espaços');
```

### Entre campos — `mustWith`

```dart
Field<DateTime>('dataFim')
  .required()
  .mustWith(
    (val, valueOf) => val == null || valueOf<DateTime>('dataInicio').value == null || val.isAfter(valueOf<DateTime>('dataInicio').value!),
    message: 'A data final deve ser posterior à data inicial',
  );
```

> [!TIP]
> Para comparações simples de igualdade (como confirmação de senha), **prefira o validador embutido `.equals()`** em vez de escrever um `.mustWith()` customizado:
> ```dart
> Field<String>('confirmarSenha')
>   .required()
>   .equals(
>     (valueOf) => valueOf<String>('senha'),
>     message: 'As senhas não coincidem',
>   );
> ```

### Nível baixo — `addValidator`

```dart
Field<String>('slug')
  .addValidator(
    'Apenas letras minúsculas e hífens',
    (val) => val != null && !RegExp(r'^[a-z-]+$').hasMatch(val),
  );
```

---

## Validadores assíncronos

```dart
Field<String>('usuario')
  .required()
  .addValidatorAsync(
    'Nome de usuário já está em uso',
    (val) async {
      if (val == null || val.isEmpty) return false;
      final ocupado = await minhaApi.verificarUsuario(val);
      return ocupado; // retornar true = tem erro
    },
  );
```

> [!NOTE]
> A biblioteca gerencia automaticamente condições de corrida (race conditions) assíncronas, descartando resultados desatualizados caso o valor do campo mude enquanto a requisição de validação ainda estiver em andamento.

Use `.debounce()` para evitar uma requisição por tecla digitada:

```dart
Field<String>('usuario')
  .required()
  .debounce(const Duration(milliseconds: 500))
  .addValidatorAsync('Usuário já existe', (val) async {
    return await minhaApi.verificarUsuario(val ?? '');
  });
```

---

## Validação condicional — `applyWhen`

Ativa um conjunto de validadores somente quando outro campo satisfaz uma condição:

```dart
final form = formCtrl(() => (
  temEmpresa: Field<bool>('temEmpresa'),
  cnpj: Field<String>('cnpj')
    .applyWhen(
      (valueOf) => valueOf<bool>('temEmpresa').value == true,
      (f) => f
        .required(message: 'CNPJ é obrigatório')
        .validCNPJ(message: 'CNPJ inválido'),
    ),
));
```

O atalho `.when()` em `Field<String>` aplica `.required()` condicionalmente:

```dart
Field<String>('cupom').when(
  (valueOf) => valueOf<String>('plano').value == 'premium',
  message: 'Cupom é obrigatório para o plano premium',
);
```

---

## Regras expostas (indicador de força de senha)

Marque regras individuais com `exposed: true` para exibi-las na UI:

```dart
Field<String>('senha')
  .required()
  .minLength(8, message: 'Mínimo 8 caracteres', exposed: true)
  .mustHaveUppercase(message: 'Uma letra maiúscula', exposed: true)
  .mustHaveNumber(message: 'Um número', exposed: true)
  .mustHaveSpecialChar(message: 'Um caractere especial', exposed: true);
```

```dart
// No seu widget:
for (final rule in form.fields.senha.exposedRules)
  Row(children: [
    Icon(rule.isValid ? Icons.check : Icons.close),
    Text(rule.message),
  ]),
```

---

## Máscara de entrada

```dart
// Máscara fixa — '#' é um placeholder para qualquer caractere
Field<String>('telefone').mask('(##) #####-####');

// Máscara dinâmica CPF / CNPJ (alterna com 11 dígitos)
Field<String>('documento').maskCPFOrCNPJ();

// Manter o valor formatado no JSON
Field<String>('cartao').mask('#### #### #### ####', removeMaskOnJson: false);
```

O valor no JSON remove os caracteres de máscara por padrão (`removeMaskOnJson: true`).

---

## Transformador `toJson`

```dart
Field<String>('nascimento')
  .mask('##/##/####')
  .transformToJson((val) {
    if (val == null) return null;
    final partes = val.split('/');
    return '${partes[2]}-${partes[1]}-${partes[0]}';
  });
```

---

## Callbacks de ciclo de vida

```dart
final field = Field<String>('email')
  ..onValueChanged = (antigo, novo) => print('mudou: $antigo → $novo')
  ..onValidationStart = () => print('validando…')
  ..onValidationEnd = (valido, erro) => print('valido=$valido erro=$erro');

form
  ..onSubmitStart = () => mostrarLoader()
  ..onSubmitEnd = (sucesso) => esconderLoader()
  ..onReset = () => print('formulário resetado');
```

---

## Widgets

Todos os widgets registram um `FocusNode` automaticamente, chamam `touch()` ao perder o foco e exibem `field.error` somente após o campo ser tocado.

### `SignalTextField`

```dart
SignalTextField(
  field: form.fields.nome,
  decoration: const InputDecoration(labelText: 'Nome'),
  keyboardType: TextInputType.name,
  obscureText: false,
  maxLines: 1,
);
```

### `SignalDropdown<T>`

```dart
SignalDropdown<String>(
  field: form.fields.estado,
  decoration: const InputDecoration(labelText: 'Estado'),
  hint: const Text('Selecione…'),
  items: const [
    DropdownMenuItem(value: 'SP', child: Text('São Paulo')),
    DropdownMenuItem(value: 'RJ', child: Text('Rio de Janeiro')),
  ],
);
```

### `SignalCheckbox`

```dart
SignalCheckbox(
  field: form.fields.aceitaTermos,
  title: const Text('Aceito os termos de uso'),
);
```

### `SignalSwitch`

```dart
SignalSwitch(
  field: form.fields.notificacoes,
  title: const Text('Ativar notificações'),
);
```

### `SignalRadioGroup<T>`

```dart
SignalRadioGroup<String>(
  field: form.fields.genero,
  decoration: const InputDecoration(labelText: 'Gênero'),
  options: const [
    SignalFieldOption(value: 'M', label: 'Masculino'),
    SignalFieldOption(value: 'F', label: 'Feminino'),
    SignalFieldOption(value: 'O', label: 'Outro'),
  ],
);
```

### `SignalCheckboxGroup<T>`

```dart
SignalCheckboxGroup<String>(
  field: form.fields.hobbies,
  decoration: const InputDecoration(labelText: 'Hobbies'),
  options: const [
    SignalFieldOption(value: 'musica', label: 'Música'),
    SignalFieldOption(value: 'esportes', label: 'Esportes'),
    SignalFieldOption(value: 'tech', label: 'Tecnologia'),
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
  field: form.fields.faixaPreco,
  min: 0,
  max: 1000,
  decoration: const InputDecoration(labelText: 'Faixa de preço'),
);
```

### `SignalDateTimePicker`

```dart
SignalDateTimePicker(
  field: form.fields.nascimento,
  decoration: const InputDecoration(labelText: 'Data de nascimento'),
  firstDate: DateTime(1900),
  lastDate: DateTime.now(),
);
```

### `SignalDateRangePicker`

```dart
SignalDateRangePicker(
  field: form.fields.periodo,
  decoration: const InputDecoration(labelText: 'Período'),
  firstDate: DateTime.now(),
  lastDate: DateTime.now().add(const Duration(days: 365)),
);
```

### `SignalChoiceChip<T>` e `SignalFilterChip<T>`

```dart
SignalChoiceChip<String>(
  field: form.fields.tamanho,
  options: const [
    SignalFieldOption(value: 'P', label: 'Pequeno'),
    SignalFieldOption(value: 'M', label: 'Médio'),
    SignalFieldOption(value: 'G', label: 'Grande'),
  ],
);
```

---

## Inputs Flutter vanilla — `SignalFormField<T>`

Use `SignalFormField` para conectar qualquer widget Flutter a um `Field` sem um widget Signal dedicado:

```dart
SignalFormField<DateTime>(
  field: form.fields.agendamento,
  builder: (context, field) {
    return ListTile(
      title: Text(
        field.value != null
            ? DateFormat.yMd('pt_BR').format(field.value!)
            : 'Escolha uma data',
      ),
      trailing: const Icon(Icons.calendar_today),
      subtitle: field.isTouched && field.error != null
          ? Text(field.error!, style: const TextStyle(color: Colors.red))
          : null,
      onTap: () async {
        final escolhida = await showDatePicker(
          context: context,
          initialDate: field.value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (escolhida != null) {
          field.value = escolhida;
          field.touch();
        }
      },
    );
  },
);
```

O builder é chamado sempre que `field` notifica seus ouvintes — você tem acesso ao `Field<T>` completo com `value`, `error`, `isLoading`, `isTouched`, etc.

---

## Referência de validações

### `Field<String>`

| Método | Descrição |
|---|---|
| `required()` | Não nulo e não vazio |
| `notEmpty()` | Alias de `required` |
| `minLength(n)` | Mínimo de `n` caracteres |
| `maxLength(n)` | Máximo de `n` caracteres |
| `length(n)` | Exatamente `n` caracteres |
| `email()` | Formato de e-mail válido |
| `validUrl()` | URL válida |
| `httpUrl()` | URL HTTP/HTTPS |
| `hostname()` | Hostname válido |
| `pattern(regex)` | Corresponde a um `RegExp` |
| `alphanumeric()` | Apenas letras e dígitos |
| `numeric()` | Apenas dígitos |
| `uppercase()` | Tudo maiúsculo |
| `lowercase()` | Tudo minúsculo |
| `contains(s)` | Contém a substring |
| `startsWith(s)` | Começa com o prefixo |
| `endsWith(s)` | Termina com o sufixo |
| `mustHaveLowercase()` | Ao menos uma letra minúscula |
| `mustHaveUppercase()` | Ao menos uma letra maiúscula |
| `mustHaveNumber()` | Ao menos um dígito |
| `mustHaveSpecialChar()` | Ao menos um caractere especial |
| `matches(path)` | Igual ao campo irmão pelo caminho |
| `equals((valueOf) => ...)` | Igual a um campo resolvido via `valueOf` |
| `oneOf(list)` | Valor pertence à lista de permitidos |
| `uuid()` / `uuidv4()` / `uuidv6()` / `uuidv7()` | Formato UUID |
| `guid()` | Alias de `uuidv4` |
| `cuid()` / `cuid2()` | Formato CUID |
| `nanoid(size)` | Formato Nano ID |
| `ulid()` | Formato ULID |
| `date()` / `isoDate()` | `YYYY-MM-DD` |
| `time()` | `HH:mm:ss` |
| `datetime()` / `isoDatetime()` | ISO 8601 datetime |
| `isoTime()` | ISO time com fuso horário |
| `isoDuration()` | Duração ISO 8601 |
| `ipv4()` / `ipv6()` | Endereço IP |
| `cidrv4()` / `cidrv6()` | Notação CIDR |
| `mac()` | Endereço MAC |
| `base64()` / `base64url()` | Base64 |
| `hex()` | Hexadecimal |
| `jwt()` | Estrutura JWT |
| `emoji()` | Contém ao menos um emoji |
| `hash(algorithm)` | String hex de hash (md5, sha1, sha256, …) |
| `hasNoSequentialRepeatedCharacters()` | Sem `aaa`, `111`, etc. |
| `hasNoSequentialCharacters()` | Sem `abc`, `123`, `321`, etc. |
| `when(condition)` | Obrigatório condicionalmente |
| **Brasileiros** | |
| `validCPF()` | CPF com dígito verificador |
| `validCNPJ()` | CNPJ com dígito verificador |
| `validCPFOrCNPJ()` | CPF ou CNPJ |
| `validCEP()` | CEP brasileiro |
| `validPhoneBR()` | Celular brasileiro |
| `validPhoneWithCountryCodeBR()` | Celular brasileiro com +55 |
| `validCreditCard()` | Algoritmo de Luhn |
| `maskCPFOrCNPJ()` | Máscara dinâmica CPF/CNPJ |

### `Field<num>` / `Field<int>` / `Field<double>`

| Método | Descrição |
|---|---|
| `required()` | Não nulo |
| `min(n)` | ≥ n |
| `max(n)` | ≤ n |
| `range(min, max)` | Entre min e max |
| `positive()` | > 0 |
| `negative()` | < 0 |
| `nonnegative()` | ≥ 0 |
| `nonZero()` | ≠ 0 |
| `greaterThan(n)` | > n |
| `lessThan(n)` | < n |
| `multipleOf(n)` / `step(n)` | Divisível por n |
| `even()` / `odd()` | Apenas inteiros |

### `Field<bool>`

| Método | Descrição |
|---|---|
| `required()` | Não nulo |
| `mustBeTrue()` | Deve ser `true` (ex: aceite de termos) |
| `mustBeFalse()` | Deve ser `false` |

### `Field<List<T>>`

| Método | Descrição |
|---|---|
| `required()` | Não nulo e não vazio |
| `minItems(n)` | Mínimo de `n` itens |
| `maxItems(n)` | Máximo de `n` itens |
| `itemCount(n)` | Exatamente `n` itens |
| `contains(item)` | Lista contém o item |
| `addItem(item)` | Helper de mutação |
| `removeItem(item)` | Helper de mutação |
| `removeAt(index)` | Helper de mutação |
| `clear()` | Helper de mutação |

Validadores por item da lista via `applyEach`:

```dart
Field<List<String>>('tags')
  .minItems(1, message: 'Ao menos uma tag')
  .applyEach<String>(
    (itemField) => itemField.minLength(2, message: 'Tag muito curta'),
    formatError: (i, msg) => 'Tag $i: $msg',
  );
```

### `Field<DateTime>`

| Método | Descrição |
|---|---|
| `required()` | Não nulo |
| `after((valueOf) => ...)` | Após a data de outro campo |
| `afterDate(date)` | Após uma data fixa |
| `before((valueOf) => ...)` | Antes da data de outro campo |
| `beforeDate(date)` | Antes de uma data fixa |
| `inPast()` | Antes de agora |
| `inFuture()` | Após agora |
| `between(start, end)` | Dentro de um intervalo |
| `inclusiveBetween(start, end)` | Intervalo inclusivo |
| `exclusiveBetween(start, end)` | Intervalo exclusivo |
| `greaterThan(date)` | Estritamente após a data |
| `greaterThanOrEqualTo(date)` | Na data ou após |
| `lessThan(date)` | Estritamente antes da data |
| `lessThanOrEqualTo(date)` | Na data ou antes |

### Genérico (`Field<T>`)

| Método | Descrição |
|---|---|
| `must((val) => bool)` | Regra síncrona customizada |
| `mustWith((val, valueOf) => bool)` | Regra customizada com acesso a outros campos |
| `equalTo(other)` | Valor igual a um valor fixo |
| `isNull()` | Deve ser nulo |
| `isNotNull()` | Não deve ser nulo |

---

## Criando validadores customizados

Adicione seus próprios validadores como extensões Dart em `Field<SeuTipo>`.

### Extensão síncrona

```dart
extension SenhaFieldValidators on Field<String> {
  Field<String> senhaForte({String message = 'Senha muito fraca'}) {
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

### Extensão assíncrona

Use `addValidatorAsync` dentro da extensão para consultar uma API ou banco de dados:

```dart
extension UsuarioFieldValidators on Field<String> {
  Field<String> usuarioDisponivel({String message = 'Nome de usuário já está em uso'}) {
    return addValidatorAsync(message, (val) async {
      if (val == null || val.isEmpty) return false;
      final ocupado = await UsuarioRepository.verificarDisponibilidade(val);
      return ocupado; // true = tem erro
    });
  }
}
```

Combine com `.debounce()` para evitar uma requisição por tecla digitada:

```dart
Field<String>('usuario')
  .required()
  .minLength(3)
  .debounce(const Duration(milliseconds: 500))
  .usuarioDisponivel(message: 'Este nome de usuário já está em uso');
```

O uso é idêntico ao dos validadores embutidos — extensões síncronas e assíncronas podem ser encadeadas livremente:

```dart
Field<String>('senha').required().senhaForte();
Field<String>('usuario').required().usuarioDisponivel();
```
