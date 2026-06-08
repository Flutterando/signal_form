import 'package:flutter/material.dart';

import '../controllers/wizard_controller.dart';

class StepIndicatorHeader extends StatelessWidget {
  final WizardController wizard;

  const StepIndicatorHeader({super.key, required this.wizard});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StepDot(wizard: wizard, step: 0, label: 'Conta'),
              _StepConnector(wizard: wizard, afterStep: 0),
              _StepDot(wizard: wizard, step: 1, label: 'Pessoal'),
              _StepConnector(wizard: wizard, afterStep: 1),
              _StepDot(wizard: wizard, step: 2, label: 'Preferências'),
              _StepConnector(wizard: wizard, afterStep: 2),
              _StepDot(wizard: wizard, step: 3, label: 'Pagamento'),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: wizard.progress,
            backgroundColor:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final WizardController wizard;
  final int step;
  final String label;

  const _StepDot({
    required this.wizard,
    required this.step,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = wizard.currentStep == step;
    final isCompleted = wizard.currentStep > step;
    final color = isActive
        ? Theme.of(context).colorScheme.primary
        : isCompleted
            ? Colors.green
            : Theme.of(context).colorScheme.outline;

    return GestureDetector(
      onTap: () => wizard.goToStep(step),
      child: Column(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color,
            child: isCompleted
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Theme.of(context).colorScheme.primary : null,
              fontWeight: isActive ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  final WizardController wizard;
  final int afterStep;

  const _StepConnector({required this.wizard, required this.afterStep});

  @override
  Widget build(BuildContext context) {
    final isCompleted = wizard.currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: isCompleted
            ? Colors.green
            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
      ),
    );
  }
}