import 'package:flutter/material.dart';
import 'package:signal_form/signal_form.dart';

import '../forms/register_form.dart';

class PreferencesStep extends StatelessWidget {
  final FormController<RegisterFormFields> form;

  const PreferencesStep({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    final f = form.fields.preferences;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Preferências',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Personalize sua experiência'),
        const SizedBox(height: 24),

        // Interests
        SignalFilterChip<String>(
          field: f.interests,
          decoration: const InputDecoration(
            labelText: 'Áreas de interesse',
            border: InputBorder.none,
          ),
          options: const [
            SignalFieldOption(value: 'tech', label: 'Tecnologia'),
            SignalFieldOption(value: 'design', label: 'Design'),
            SignalFieldOption(value: 'business', label: 'Negócios'),
            SignalFieldOption(value: 'marketing', label: 'Marketing'),
            SignalFieldOption(value: 'finance', label: 'Finanças'),
            SignalFieldOption(value: 'health', label: 'Saúde'),
          ],
        ),
        const SizedBox(height: 24),

        // Referral source
        SignalRadioGroup<String>(
          field: f.referralSource,
          decoration: const InputDecoration(
            labelText: 'Como nos conheceu?',
          ),
          options: const [
            SignalFieldOption(value: 'google', label: 'Pesquisa no Google'),
            SignalFieldOption(value: 'social', label: 'Redes Sociais'),
            SignalFieldOption(value: 'friend', label: 'Indicação de amigo'),
            SignalFieldOption(value: 'other', label: 'Outro'),
          ],
        ),
        const SizedBox(height: 16),

        // Terms and newsletter
        const Divider(),
        SignalCheckbox(
          field: f.acceptTerms,
          title: const Text('Aceito os Termos de Uso'),
          subtitle: const Text('Li e concordo com os termos e condições'),
        ),
        SignalCheckbox(
          field: f.acceptNewsletter,
          title: const Text('Receber newsletter'),
          subtitle: const Text('Novidades e atualizações por e-mail'),
        ),
      ],
    );
  }
}