import 'package:flutter/material.dart';
import 'package:signal_form/signal_form.dart';

import '../forms/register_form.dart';
import '../widgets/form_fields.dart' show PasswordMeter;

class AccountStep extends StatelessWidget {
  final FormController<RegisterFormFields> form;

  const AccountStep({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    final f = form.fields.account;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Informações da Conta',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Crie suas credenciais de acesso'),
        const SizedBox(height: 24),

        // Email field
        SignalTextField(
          field: f.email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'E-mail',
            prefixIcon: const Icon(Icons.email_outlined),
            suffixIcon: ListenableBuilder(
              listenable: f.email,
              builder: (context, child) {
                if (f.email.isLoading) {
                  return const UnconstrainedBox(
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Password field
        SignalTextField(
          field: f.password,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Senha',
            prefixIcon: Icon(Icons.lock_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        PasswordMeter(passwordField: f.password),
        const SizedBox(height: 16),

        // Confirm password
        SignalTextField(
          field: f.confirmPassword,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Confirmar Senha',
            prefixIcon: Icon(Icons.lock_outlined),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
