import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:signal_form/signal_form.dart';

import '../controllers/wizard_controller.dart';
import '../forms/register_form.dart';
import '../steps/account_step.dart';
import '../steps/personal_step.dart';
import '../steps/preferences_step.dart';
import '../steps/payment_step.dart';
import '../widgets/step_indicator.dart';

class WizardPage extends StatefulWidget {
  const WizardPage({super.key});

  @override
  State<WizardPage> createState() => _WizardPageState();
}

class _WizardPageState extends State<WizardPage> {
  late final form = createRegisterForm();
  late final wizard = WizardController(
    form: form,
    stepPaths: ['account', 'personal', 'preferences', 'payment'],
  );

  @override
  void dispose() {
    form.dispose();
    wizard.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    form.submit((data) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cadastro Realizado!'),
          content: SingleChildScrollView(
            child: Text(
              const JsonEncoder.withIndent('  ').convert(data.toJson()),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([form, wizard]),
        builder: (context, _) {
          return Column(
            children: [
              StepIndicatorHeader(wizard: wizard),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildCurrentStep(),
                ),
              ),
              _NavigationButtons(
                wizard: wizard,
                form: form,
                onSubmit: _handleSubmit,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentStep() {
    return switch (wizard.currentStep) {
      0 => AccountStep(form: form),
      1 => PersonalStep(form: form),
      2 => PreferencesStep(form: form),
      3 => PaymentStep(form: form),
      _ => const SizedBox.shrink(),
    };
  }
}

class _NavigationButtons extends StatelessWidget {
  final WizardController wizard;
  final FormController<RegisterFormFields> form;
  final VoidCallback onSubmit;

  const _NavigationButtons({
    required this.wizard,
    required this.form,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!wizard.isFirstStep)
            OutlinedButton.icon(
              onPressed: wizard.previousStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Voltar'),
            ),
          const Spacer(),
          switch (wizard.isLastStep) {
            true => FilledButton.icon(
                onPressed: form.isValidating || form.isSubmitting ? null : onSubmit,
                icon: form.isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: const Text('Finalizar'),
              ),
            false => FilledButton.icon(
                onPressed: form.isValidating ? null : () => wizard.nextStep(),
                icon: form.isValidating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_forward),
                label: const Text('Próximo'),
              ),
          },
        ],
      ),
    );
  }
}
