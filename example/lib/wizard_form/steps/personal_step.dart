import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signal_form/signal_form.dart';

import '../forms/register_form.dart';

class PersonalStep extends StatelessWidget {
  final FormController<RegisterFormFields> form;

  const PersonalStep({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    final f = form.fields.personal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Dados Pessoais',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Conte-nos mais sobre você'),
        const SizedBox(height: 24),

        // Full name
        SignalTextField(
          field: f.fullName,
          decoration: const InputDecoration(
            labelText: 'Nome Completo',
            prefixIcon: Icon(Icons.person_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Phone with mask
        SignalTextField(
          field: f.phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            LengthLimitingTextInputFormatter(15),
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(
            labelText: 'Telefone',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Birth date
        SignalDateTimePicker(
          field: f.birthDate,
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          decoration: const InputDecoration(
            labelText: 'Data de Nascimento',
            prefixIcon: Icon(Icons.calendar_today_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Has website toggle
        SignalSwitch(
          field: f.hasWebsite,
          title: const Text('Tenho um website'),
          subtitle: const Text('Adicione seu site pessoal ou portfólio'),
        ),

        // Conditional website URL
        ListenableBuilder(
          listenable: f.hasWebsite,
          builder: (context, _) {
            if (!f.hasWebsite.isChecked) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SignalTextField(
                field: f.websiteUrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'URL do Website',
                  prefixIcon: Icon(Icons.language),
                  border: OutlineInputBorder(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
