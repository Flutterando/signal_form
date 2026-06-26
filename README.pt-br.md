# signal_form

> 🇺🇸 [Read in English](README.md)

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Índice</summary>
  <ol>
    <li><a href="#instalação">Instalação</a></li>
    <li>
      <a href="#início-rápido">Início rápido</a>
      <ol>
        <li><a href="#1-defina-o-schema">1. Defina o schema</a></li>
        <li><a href="#2-conecte-os-widgets">2. Conecte os widgets</a></li>
        <li><a href="#3-descarte">3. Descarte</a></li>
        <li><a href="#organização-de-projeto-recomendada">Organização de Projeto Recomendada</a></li>
      </ol>
    </li>
    <li>
      <a href="#motivação">Motivação</a>
      <ol>
        <li><a href="#lista-detalhada-de-funcionalidades">Lista detalhada de funcionalidades</a></li>
      </ol>
    </li>
    <li>
      <a href="#api-principal">API principal</a>
      <ol>
        <li><a href="#fieldt">Field&lt;T&gt;</a></li>
        <li><a href="#formcontrollert">FormController&lt;T&gt;</a></li>
        <li><a href="#grupos-aninhados--formgroup">Grupos aninhados — formGroup</a></li>
      </ol>
    </li>
    <li><a href="#modos-de-validação">Modos de validação</a></li>
    <li>
      <a href="#validadores-customizados">Validadores customizados</a>
      <ol>
        <li><a href="#síncrono--must">Síncrono — must</a></li>
        <li><a href="#entre-campos--mustwith">Entre campos — mustWith</a></li>
        <li><a href="#nível-baixo--addvalidator">Nível baixo — addValidator</a></li>
      </ol>
    </li>
    <li><a href="#validadores-assíncronos">Validadores assíncronos</a></li>
    <li><a href="#validação-condicional--applywhen">Validação condicional — applyWhen</a></li>
    <li>
      <a href="#roteamento-condicional--switchwith">Roteamento condicional — switchWith</a>
      <ol>
        <li><a href="#chaves-tipadas-com-sealed-classes">Chaves tipadas com sealed classes</a></li>
      </ol>
    </li>
    <li><a href="#regras-expostas-indicador-de-força-de-senha">Regras expostas (indicador de força de senha)</a></li>
    <li>
      <a href="#máscara-de-entrada">Máscara de entrada</a>
      <ol>
        <li><a href="#referência-de-máscaras">Referência de máscaras</a></li>
      </ol>
    </li>
    <li><a href="#transformador-tojson">Transformador toJson</a></li>
    <li><a href="#callbacks-de-ciclo-de-vida">Callbacks de ciclo de vida</a></li>
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
        <li><a href="#signalchoicechipt-and-signalfilterchipt">SignalChoiceChip&lt;T&gt; e SignalFilterChip&lt;T&gt;</a></li>
      </ol>
    </li>
    <li><a href="#inputs-flutter-vanilla--signalformfieldt">Inputs Flutter vanilla — SignalFormField&lt;T&gt;</a></li>
    <li><a href="#referência-de-validação">Referência de validação</a></li>
    <li><a href="#estendendo-com-validadores-customizados">Estendendo com validadores customizados</a></li>
    <li><a href="#desenvolvimento-assistido-por-ia">Desenvolvimento assistido por IA</a></li>
  </ol>
</details>

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

### Organização de Projeto Recomendada

Para projetos maiores ou mais fáceis de manter, é uma boa prática separar a definição do schema do seu formulário do arquivo de visualização (UI) em arquivos distintos. Isso mantém a lógica de validação e transformação de dados completamente independente dos widgets Flutter.

Aqui está um padrão recomendado:

#### 1. O Arquivo do Schema (`login_schema.dart`)

Este arquivo contém a definição do record do schema, a função geradora e quaisquer extensões de mapeamento de dados:

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

#### 2. O Arquivo da Tela (`login_screen.dart`)

Este arquivo instancia o controller do formulário e monta a interface do usuário:

```dart
// login_screen.dart

late final form = formCtrl(loginFormSchema);

void submit() => form.submit((data) async => api.login(data.toDto()));

// No seu método build:
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
          // Desabilita o botão se o formulário for inválido ou se estiver submetendo
          onPressed: form.valid && !form.isSubmitting
              ? submit
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

## Motivação

Gerenciar formulários complexos no Flutter costuma significar equilibrar `TextEditingController`, `GlobalKey<FormState>`, lógica de validação espalhada pelo código e atualizações de estado imperativas. O **signal_form** foi criado para unificar e simplificar tudo isso.

Inspirado no [Angular Signal Forms](https://angular.dev/essentials/signal-forms), ele traz uma abordagem **baseada em schema e fortemente tipada** para formulários Flutter: você declara seus campos e regras de validação uma única vez, em um só lugar, e a biblioteca cuida do resto.

- **Validação declarativa** — as regras ficam junto ao campo ao qual pertencem, não espalhadas pela árvore de widgets
- **API fluente** — encadeie validadores em uma única expressão com baixa verbosidade e alta legibilidade
- **Alto desempenho** — cada campo notifica apenas seus próprios ouvintes; o cache do formulário evita recomputações desnecessárias
- **Formatação e transformação de dados** — máscaras de entrada e transformadores `toJson` mantêm os valores brutos e serializados sincronizados automaticamente
- **Widgets prontos** — componentes Material prontos para uso (`SignalTextField`, `SignalDropdown`, `SignalCheckbox` e outros) com exibição de erros, gerenciamento de foco e scroll automático até o primeiro campo inválido já configurados
- **Extensível** — adicione seus próprios validadores síncronos ou assíncronos como simples extension methods Dart, indistinguíveis dos embutidos

### Lista detalhada de funcionalidades

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
| `isDisabled` | `bool` | Campo desabilitado (validadores ignorados) |
| `initialValue` | `T?` | Valor com que o campo foi inicializado |
| `exposedRules` | `List<({String message, bool isValid})>` | Regras marcadas com `exposed: true` |

| Método | Descrição |
|---|---|
| `touch()` | Marca o campo como tocado |
| `reset()` | Restaura o valor inicial e limpa erros |
| `reset({to})` | Restaura o valor inicial, ou define um valor arbitrário via o parâmetro nomeado `to` |
| `parse(fn)` | Converte a entrada de string bruta para o tipo do campo (ex: `String → int`) |
| `transform(fn)` | Normaliza o valor antes de armazenar (trim, lowercase, etc.) |
| `invalidate(message)` | Define um erro manualmente |
| `clearError()` | Limpa o erro atual sem reexecutar validadores |
| `disable()` | Desabilita o campo — todos os validadores são ignorados |
| `enable()` | Reabilita o campo — restaura a validação normal |
| `validate()` | Executa validadores síncronos, retorna `bool` |
| `validateAsync()` | Executa todos os validadores, retorna `Future<bool>` |
| `debounce(duration)` | Throttle da validação |
| `validationMode(mode)` | Define `onChange`, `onBlur` ou `onSubmit` |

#### `parse(fn)` — conversão de tipo a partir de texto

`parse` registra uma função que converte uma `String` bruta no tipo do campo. É a ponte entre um `TextField` (que sempre emite `String`) e um campo fortemente tipado como `Field<int>` ou `Field<DateTime>`.

```dart
final idade    = Field<int>('idade').parse(int.tryParse);
final nascimento = Field<DateTime>('nascimento')
    .mask('##/##/####')
    .parse((s) {
      final p = s.split('/');
      return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
    });

idade.value      = '25';        // armazenado como int 25
nascimento.value = '25121990';  // máscara → '25/12/1990' → parse → DateTime(1990,12,25)
print(nascimento.text);         // value with mask → '25/12/1990'
print(nascimento.value);        // value → DateTime(1990,12,25)
```

**Como o setter funciona.** `Field.value` aceita `dynamic`. Quando o valor recebido é uma `String`, o pipeline é:

```
String entrada  →  mask (se configurada)  →  parse (se configurado)  →  transform (se configurado)  →  armazenado como T
```

Quando o valor não é uma `String` (ex: atribuição programática de um valor já tipado), ele é convertido diretamente para `T?` — os passos de parse e mask são ignorados.

**Atenção com listas vazias.** Como o setter aceita `dynamic`, Dart não consegue inferir o tipo de elemento de um literal vazio — `[]` se torna `List<dynamic>` e a conversão em tempo de execução para `List<String>` falha. Sempre forneça o tipo explícito ao atribuir um literal vazio para um campo de lista tipada:

```dart
// ✗ erro em runtime — List<dynamic> não é List<String>
tags.value = [];

// ✓ tipo de elemento explícito
tags.value = <String>[];
```

Literais não-vazios (`['a', 'b']`) e variáveis (`final list = <String>[]; tags.value = list;`) funcionam sem anotação, pois Dart infere o tipo a partir dos elementos ou da declaração.

#### Factory `Field.detached<T>`

Cria um `Field` que **não é registrado** no `formCtrl` envolvente. Ideal para uso em testes ou funções auxiliares:

```dart
final standalone = Field.detached<String>('rotulo');
// ou com valor inicial:
final standalone = Field.detached<int>('contador', 0);
```

#### Factory `Field.computed<T>`

Cria um campo **derivado e somente leitura** cujo valor é recomputado automaticamente sempre que qualquer campo do formulário muda. O campo computado aparece no `toJson`, é excluído do `completionPercent` e seu `isDirty` é sempre `false`.

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

Retornado por `formCtrl`. Agrega todos os campos e coordena a validação.

```dart
form.submit((f) async { ... });           // valida tudo, chama ao ter sucesso
form.trigger();                            // valida tudo sem submeter
form.trigger(path: 'email');               // valida apenas um campo/grupo específico
form.reset();                              // reseta todos os campos
form.resetField('email');                  // reseta um campo
form.patchValue({'nome': 'João'});         // define múltiplos valores
form.setValue('email', 'a@b.com');
form.fromJson(map);                        // preenche campos a partir de um mapa JSON (objetos aninhados são expandidos)
form.fromJson(map, setAsInitial: true);    // igual, mas também atualiza o initialValue (padrão para edit-form)
form.toJson();                             // { nome: 'João', email: 'a@b.com', ... }
form.toJson(omitNulls: true);              // remove campos null e grupos aninhados vazios
form.toJson(omitDisabled: true);           // exclui campos desabilitados do resultado
form.dirtyValues();                        // mapa apenas com os campos que foram alterados
form.clearErrors();                        // limpa todos os erros de validação
form.clearErrors(path: 'endereco');        // limpa erros de um campo/grupo específico
form.setErrors({'email': 'Já cadastrado', 'cpf': 'Inválido'}); // aplica erros do servidor em lote
form.toQueryString();                      // converte o formulário para parâmetros de URL
form.completionPercent;                    // fração (0.0–1.0) dos campos não desabilitados e não computados que possuem valor
form.errors;                               // Map<String, String> de erros atuais
form.valid;                                // true se errors estiver vazio
form.isDirty;                              // true se algum campo for dirty
form.isTouched;                            // true se algum campo for touched
form.isSubmitting;                         // true durante o callback de submit
form.isValidating;                         // true enquanto validação async roda
form.getField<String>('email');            // busca O(1) por nome
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
- **Carregar de JSON**: `form.fromJson(map)` aceita qualquer mapa JSON — incluindo objetos aninhados — e preenche os campos correspondentes. Passe `setAsInitial: true` para também atualizar o `initialValue` de cada campo, de forma que um `reset()` posterior retorne aos dados carregados em vez dos valores originais.
- **Reset**: Chame `form.reset()` para restaurar todos os campos ao seu `initialValue` e limpar todos os erros de validação ativos. Você pode definir o callback `form.onReset` para reagir a este evento. Use `form.resetField('caminho')` para resetar apenas um campo.

#### Padrão de edição (edit-form)

```dart
// Após buscar dados de uma API:
final usuario = await api.getUsuario(id);
form.fromJson(usuario, setAsInitial: true);
// Agora isDirty é false, e reset() volta para os valores carregados.

// Ao salvar — envia apenas o que o usuário alterou:
await api.patchUsuario(id, form.dirtyValues());
```

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

#### Grupo condicional — `applyWhen`

Passe `applyWhen:` para aplicar uma condição compartilhada a **todos os campos** dentro do grupo. Os campos só validam quando a condição é satisfeita.

```dart
final form = formCtrl(() => (
  temCobranca: Field<bool>('temCobranca', false),
  cobranca: formGroup('cobranca', () => (
    endereco: Field<String>('endereco').required(),
    cidade: Field<String>('cidade').required(),
  ), applyWhen: (valueOf) => valueOf<bool>('temCobranca').value == true),
));
// endereco e cidade só validam quando temCobranca for true
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

## Roteamento condicional — `switchWith`

Roteia um conjunto completo de validadores com base em uma chave derivada de outro campo. Apenas o caso correspondente é executado; os demais são ignorados.

```dart
final form = formCtrl(() => (
  pais: Field<String>('pais', 'BR')
    .oneOf(['BR', 'US', 'EU'], message: 'País inválido'),
  doc: Field<String>('doc')
    .switchWith<String>(
      (valueOf) => valueOf<String>('pais').value,
      {
        'BR': (f) => f.validCPF(message: 'CPF inválido'),
        'US': (f) => f.addValidator('SSN inválido', (v) => v == null || v.length != 9),
        'EU': (f) => f.addValidator('VAT inválido', (v) => v == null || v.length < 5),
      },
      orElse: (f) => f.required(message: 'Documento obrigatório'),
      dependsOn: ['pais'],
    ),
));
```

| Parâmetro | Descrição |
|---|---|
| `keySelector` | Função que retorna a chave do caso ativo a partir de outros campos |
| `cases` | Mapa de chave → builder de validadores — apenas a entrada correspondente executa |
| `orElse` | Builder de fallback que executa quando nenhum caso corresponde à chave atual |
| `dependsOn` | Caminhos de campos que, ao mudar, limpam o erro atual e reagendam a validação |

### Chaves tipadas com sealed classes

O tipo `K` pode ser qualquer tipo Dart. Usar uma sealed class (ou enum) oferece exaustividade em tempo de compilação: o IDE alerta se um novo subtipo for adicionado sem um caso correspondente.

```dart
sealed class Pais { const Pais(); }
final class BR extends Pais { const BR(); }
final class US extends Pais { const US(); }
final class EU extends Pais { const EU(); }

Field<String>('doc').switchWith<Pais>(
  (valueOf) => switch (valueOf<String>('pais').value) {
    'BR' => const BR(),
    'US' => const US(),
    'EU' => const EU(),
    _    => null,
  },
  {
    const BR(): (f) => f.validCPF(message: 'CPF inválido'),
    const US(): (f) => f.addValidator('SSN inválido', (v) => v == null || v.length != 9),
    const EU(): (f) => f.addValidator('VAT inválido', (v) => v == null || v.length < 5),
  },
  dependsOn: ['pais'],
)
```

Objetos `const` do mesmo tipo são canonicalizados pelo Dart — `const BR() == const BR()` é `true` sem precisar sobrescrever `operator==`.

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
// Máscara fixa — '#' é um placeholder para qualquer caractere alfanumérico
Field<String>('telefone').mask('(##) #####-####');

// Máscara dinâmica CPF / CNPJ (alterna com 11 dígitos)
Field<String>('documento').maskCPFOrCNPJ();

// Manter o valor formatado no JSON
Field<String>('cartao').mask('#### #### #### ####', removeMaskOnJson: false);

// Máscaras brasileiras prontas
Field<String>('cpf').maskCPF();
Field<String>('cnpj').maskCNPJ();
Field<String>('celular').maskCelular();
Field<String>('cep').maskCEP();                        // XX.XXX-XXX
Field<String>('cep').maskCEP(ponto: false);            // XXXXX-XXX
Field<String>('data').maskData();                      // DD/MM/YYYY
Field<String>('hora').maskHora();                      // HH:mm
Field<String>('valor').maskDecimal(casasDecimais: 2);  // 9.999.999.999,00
```

O valor no JSON remove os caracteres de máscara por padrão (`removeMaskOnJson: true`).

### Referência de máscaras

Todas as máscaras aceitam o parâmetro `removeMaskOnJson` (padrão `true`), que controla se a formatação é removida ao acessar `field.jsonValue`. Máscaras de valores decimais convertem a vírgula em ponto no JSON (ex: `1,82` → `1.82`).

#### Máscara genérica

| Método | Formato | Descrição |
|---|---|---|
| `mask(pattern)` | personalizável | `#` representa qualquer caractere alfanumérico |

#### Máscaras de formatação brasileira

Formatadores prontos para os padrões de documentos, moeda e entrada de dados utilizados no Brasil.

| Método | Formato | Descrição |
|---|---|---|
| `maskAltura()` | `1,82` | Altura em metros,centímetros (máx. 3 dígitos) |
| `maskCartaoCredito()` | `0000 1111 2222 3333` | Cartão de crédito (16 dígitos, grupos de 4) |
| `maskCartaoTelefone()` | `000 1111 2222 3333` | Cartão telefônico (15 dígitos: 3 + 4 + 4 + 4) |
| `maskCEP({ponto})` | `XX.XXX-XXX` / `XXXXX-XXX` | CEP — `ponto: false` remove o ponto inicial |
| `maskCertidaoNascimento()` | `XXXXXX XX XX XXXX X XXXXX XXX XXXXXXX XX` | Certidão de nascimento (32 dígitos) |
| `maskCEST()` | `XX.XXX.XX` | Código CEST (7 dígitos) |
| `maskCNPJ()` | `99.999.999/9999-99` | CNPJ numérico |
| `maskCNPJAlfanumerico()` | `XX.XXX.XXX/XXXX-XX` | CNPJ alfanumérico — novo formato 2024 (14 chars, maiúsculas) |
| `maskCPF()` | `XXX.XXX.XXX-XX` | CPF (11 dígitos) |
| `maskCPFOrCNPJ()` | dinâmico | CPF (≤ 11 dígitos) ou CNPJ (12–14 dígitos) |
| `maskData()` | `DD/MM/YYYY` | Data |
| `maskDecimal({casasDecimais})` | `9.999.999.999,00` | Decimal com separadores BR; `casasDecimais` controla as casas (padrão: 2) |
| `maskHora()` | `HH:mm` | Hora — rejeita hora > 23 e minuto > 59 |
| `maskIOF()` | `1,234567` | Taxa IOF (1 dígito inteiro + 6 decimais) |
| `maskKm()` | `000.000` | Quilometragem (6 dígitos) |
| `maskNCM()` | `XXXX.XX.XX` | Código NCM (8 dígitos) |
| `maskNUP()` | `XXXXXXX-XX.XXXX.X.XX.XXXX` | NUP — Numeração Única de Processos (20 dígitos) |
| `maskPeso()` | `103,8` | Peso kg,g — último dígito é decimal, sem separador de milhar |
| `maskPlacaVeiculo()` | `XXX-XXXX` | Placa de veículo (padrão antigo e Mercosul, maiúsculas) |
| `maskReal()` | `999.999.999.999` | Valor inteiro em reais com separador de milhar |
| `maskCelular()` | `(99) 99999-9999` | Celular brasileiro (11 dígitos) |
| `maskTemperatura()` | `10,8` | Temperatura em °C — último dígito é decimal, sem separador de milhar |
| `maskValidade({maxLength})` | `MM/AA` / `MM/AAAA` | Validade de cartão — `maxLength: 4` (padrão) ou `6` |

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
| `validCNPJ()` | CNPJ numérico com dígito verificador |
| `validCNPJAlfanumerico()` | CNPJ alfanumérico com dígito verificador (novo formato 2024) |
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
| `required()` | Valor não pode ser `null` — funciona em qualquer `Field<T>` (ex: `Field<int>`, `Field<bool>`, `Field<MeuEnum>`) |
| `must((val) => bool)` | Regra síncrona customizada |
| `mustWith((val, valueOf) => bool)` | Regra customizada com acesso a outros campos |
| `equalTo(other)` | Valor igual a um valor fixo |
| `isNull()` | Deve ser nulo |
| `isNotNull()` | Não deve ser nulo |
| `oneOf(allowedValues)` | Valor é um dos valores permitidos; `null`/vazio passa (combine com `required`) |

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

---

## Desenvolvimento Assistido por IA

O `signal_form` inclui um arquivo [`SKILL.md`](SKILL.md) — uma referência compacta e estruturada de toda a API, otimizada para assistentes de IA. Ele cobre a API completa de `Field<T>` e `FormController`, todos os validadores embutidos, widgets, padrões de validação condicional e entre campos, tratamento de race conditions assíncronas e exemplos end-to-end.

### Como usar

Forneça o `SKILL.md` ao seu assistente de IA antes de fazer perguntas sobre o `signal_form`:

**Claude / Claude Code**
```
Leia o conteúdo de SKILL.md e use-o como contexto para perguntas sobre signal_form.
```

**Cursor**
Adicione uma referência no seu arquivo `.cursorrules` ou cole o conteúdo na janela de contexto do chat.

**GitHub Copilot / outros assistentes**
Abra o `SKILL.md` no editor e mencione-o no prompt, ou cole as seções relevantes diretamente no chat.

Com a skill carregada, você pode pedir coisas como *"Crie um formulário de cadastro com validação de CPF e verificação assíncrona de nome de usuário"* e o assistente vai gerar código idiomático de `signal_form` sem precisar adivinhar a API.
