import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signal_form/signal_form.dart';

import '../forms/register_form.dart';

class PaymentStep extends StatelessWidget {
  final FormController<RegisterFormFields> form;

  const PaymentStep({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    final p = form.fields.payment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Informações de Pagamento',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Insira os dados do cartão de crédito para a cobrança'),
        const SizedBox(height: 24),

        // Cardholder Name
        SignalTextField(
          field: p.cardHolderName,
          inputFormatters: [
            TextInputFormatter.withFunction((oldValue, newValue) {
              return newValue.copyWith(text: newValue.text.toUpperCase());
            }),
          ],
          decoration: const InputDecoration(
            labelText: 'Nome Impresso no Cartão',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Card Number
        SignalTextField(
          field: p.cardNumber,
          keyboardType: TextInputType.number,
          inputFormatters: [
            LengthLimitingTextInputFormatter(19),
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(
            labelText: 'Número do Cartão',
            prefixIcon: Icon(Icons.credit_card_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Expiry & CVV Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SignalTextField(
                field: p.expiryDate,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(5),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Validade (MM/AA)',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SignalTextField(
                field: p.cvv,
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(4),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'CVV',
                  prefixIcon: Icon(Icons.security_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
