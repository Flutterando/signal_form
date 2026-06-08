import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:signal_form/signal_form.dart';

import '../cubit/bloc_form_cubit.dart';
import '../cubit/bloc_form_state.dart';

class BlocFormPage extends StatefulWidget {
  const BlocFormPage({super.key});

  @override
  State<BlocFormPage> createState() => _BlocFormPageState();
}

class _BlocFormPageState extends State<BlocFormPage> {
  late final _form = formCtrl(
    () => (
      name: Field<String>('name')
          .required(message: 'Nome é obrigatório')
          .minLength(3, message: 'Nome muito curto'),
      email: Field<String>('email')
          .required(message: 'E-mail é obrigatório')
          .email(message: 'E-mail inválido'),
      message: Field<String>('message')
          .required(message: 'Mensagem é obrigatória')
          .minLength(
            10,
            message: 'Mensagem muito curta (mínimo 10 caracteres)',
          ),
    ),
  );

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _handleSubmit(BuildContext context) {
    _form.submit((data) {
      context.read<BlocFormCubit>().submitFeedback(data.toJson());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BlocFormCubit(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Integração BLoC'),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: BlocConsumer<BlocFormCubit, BlocFormState>(
          listener: (context, state) {
            if (state is BlocFormSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Feedback enviado com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sucesso (Cubit State)'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dados enviados:'),
                        const SizedBox(height: 8),
                        Text(
                          const JsonEncoder.withIndent(
                            '  ',
                          ).convert(state.data),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _form.reset();
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            } else if (state is BlocFormFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
          builder: (context, state) {
            final isSubmitting = state is BlocFormSubmitting;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Enviar Feedback',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Envie sua mensagem. O BLoC cuidará do fluxo assíncrono e tratamento de erros.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SignalTextField(
                          field: _form.fields.name,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Nome Completo',
                            prefixIcon: Icon(Icons.person_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SignalTextField(
                          field: _form.fields.email,
                          enabled: !isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                            helperText:
                                'Dica: use "error@error.com" para simular falha',
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        SignalTextField(
                          field: _form.fields.message,
                          enabled: !isSubmitting,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Mensagem',
                            prefixIcon: Icon(Icons.message_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: isSubmitting
                              ? null
                              : () => _handleSubmit(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Enviar Feedback',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
