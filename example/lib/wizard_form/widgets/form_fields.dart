import 'package:flutter/material.dart';
import 'package:signal_form/signal_form.dart';

class PasswordMeter extends StatelessWidget {
  final Field<String> passwordField;

  const PasswordMeter({super.key, required this.passwordField});

  @override
  Widget build(BuildContext context) {
    if (passwordField.exposedRules.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Requisitos da senha:',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final rule in passwordField.exposedRules)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        rule.isValid
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        size: 16,
                        color: rule.isValid ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rule.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: rule.isValid ? Colors.green : Colors.grey,
                          decoration: rule.isValid
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
