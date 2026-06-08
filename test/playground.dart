import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_form/signal_form.dart';

sealed class Jurisdicao {
  const Jurisdicao();
}

final class Brasil extends Jurisdicao {
  const Brasil();
}

final class EUA extends Jurisdicao {
  const EUA();
}

final class UE extends Jurisdicao {
  const UE();
}

final class Argentina extends Jurisdicao {
  const Argentina();
}

typedef _Fields = ({Field<Jurisdicao> type, Field<String> document});

class _TestForm extends StatefulWidget {
  final void Function(_Fields fields) onInit;

  const _TestForm({required this.onInit});

  @override
  State<_TestForm> createState() => _TestFormState();
}

class _TestFormState extends State<_TestForm> {
  late final _form = formCtrl(
    () => (
      type: Field<Jurisdicao>(
        'type',
      ).oneOf([const Brasil(), const EUA(), const UE()]),
      document: Field<String>('document').switchWith<Jurisdicao>(
        (valueOf) => valueOf<Jurisdicao>('type').value,
        {
          const Brasil(): (f) => f.required(message: 'CPF obrigatório'),
          const EUA(): (f) => f.required(message: 'SSN obrigatório'),
          const UE(): (f) => f.required(message: 'NIF obrigatório'),
        },
        orElse: (f) => f.required(message: 'Outro obrigatório'),
        dependsOn: ['type'],
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    widget.onInit(_form.fields);
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = _form.fields;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SignalDropdown<Jurisdicao>(
            field: f.type,
            decoration: const InputDecoration(labelText: 'Jurisdição'),
            hint: const Text('Selecione...'),
            items: const [
              DropdownMenuItem(value: Brasil(), child: Text('Brasil')),
              DropdownMenuItem(value: EUA(), child: Text('EUA')),
              DropdownMenuItem(value: UE(), child: Text('União Europeia')),
            ],
          ),
          SignalFormField<Jurisdicao>(
            field: f.type,
            builder: (context, typeField) {
              final label = switch (typeField.value) {
                Brasil() => 'CPF',
                EUA() => 'SSN',
                UE() => 'NIF',
                _ => 'Documento',
              };
              return SignalTextField(
                field: f.document,
                decoration: InputDecoration(labelText: label),
              );
            },
          ),
        ],
      ),
    );
  }
}

void main() {
  // ---------------------------------------------------------------------------
  // Widget test: interações via dropdown + texto
  // ---------------------------------------------------------------------------
  testWidgets('playground – widgets', (tester) async {
    late final _Fields f;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: _TestForm(onInit: (fields) => f = fields)),
      ),
    );

    // Seleciona Brasil via dropdown → label do documento vira 'CPF'
    await tester.tap(find.byType(DropdownButtonFormField<Jurisdicao>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Brasil').last);
    await tester.pumpAndSettle();
    expect(find.text('CPF'), findsOneWidget);

    // Toca o documento sem preencher → exibe erro de Brasil
    f.document.touch();
    await tester.pump();
    expect(find.text('CPF obrigatório'), findsOneWidget);

    // Troca para EUA via dropdown → label vira 'SSN', erro atualiza
    await tester.tap(find.byType(DropdownButtonFormField<Jurisdicao>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EUA').last);
    await tester.pumpAndSettle();
    expect(find.text('SSN'), findsOneWidget);
    expect(find.text('SSN obrigatório'), findsOneWidget);

    // Preenche o documento → erro some
    await tester.enterText(find.byType(TextField), '12345');
    await tester.pump();
    expect(find.text('SSN obrigatório'), findsNothing);

    // Troca para UE → label vira 'NIF', documento ainda preenchido
    await tester.tap(find.byType(DropdownButtonFormField<Jurisdicao>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('União Europeia').last);
    await tester.pumpAndSettle();
    expect(find.text('NIF'), findsOneWidget);
    expect(find.text('NIF obrigatório'), findsNothing);

    // Limpa o documento → erro de UE aparece (campo já estava tocado)
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('NIF obrigatório'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Test puro: Argentina não está no dropdown → orElse entra em ação
  // ---------------------------------------------------------------------------
  test('playground – orElse: jurisdição não mapeada', () {
    final form = formCtrl(
      () => (
        type: Field<Jurisdicao>('type'),
        document: Field<String>('document').switchWith<Jurisdicao>(
          (valueOf) => valueOf<Jurisdicao>('type').value,
          {
            const Brasil(): (f) => f.required(message: 'CPF obrigatório'),
            const EUA(): (f) => f.required(message: 'SSN obrigatório'),
            const UE(): (f) => f.required(message: 'NIF obrigatório'),
          },
          orElse: (f) => f.required(message: 'Outro obrigatório'),
          dependsOn: ['type'],
        ),
      ),
    );

    addTearDown(form.dispose);

    final f = form.fields;

    f.type.value = const Argentina();
    f.document.touch();

    expect(f.document.error, equals('Outro obrigatório'));
  });
}
