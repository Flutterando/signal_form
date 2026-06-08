import 'package:example/simple_form/extensions.dart';
import 'package:flutter/material.dart';
import 'package:signal_form/signal_form.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  // Signup Form Controllers
  late final _signupForm = formCtrl(
    () => (
      name: Field<String>('name')
          .notEmpty(message: 'O nome é obrigatório')
          .minLength(3, message: 'Nome muito curto'),
      email: Field<String>('email')
          .required(message: 'O e-mail é obrigatório')
          .email(message: 'E-mail inválido')
          .customUniqueEmail(),
      password: Field<String>('password').customPassword(),
      confirmPassword:
          Field<String>('confirmPassword') //
              .customPassword()
              .equals(
                (valueOf) => valueOf<String>('password'),
                message: 'As senhas não coincidem',
              ),
      agreeToTerms:
          Field<bool>('agreeToTerms', false) //
              .mustBeTrue(
                message: 'Você precisa aceitar os termos e condições',
              ),
    ),
  );

  bool _obscureSignupPassword = true;
  bool _obscureSignupConfirmPassword = true;

  @override
  void dispose() {
    _signupForm.dispose();
    super.dispose();
  }

  void _handleSignupSubmit() {
    _signupForm.submit((data) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conta criada com sucesso! JSON:\n${data.toJson()}'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  'Criar Nova Conta',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SignalTextField(
                  field: _signupForm.fields.name,
                  decoration: const InputDecoration(
                    labelText: 'Nome Completo',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SignalTextField(
                  field: _signupForm.fields.email,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                SignalTextField(
                  field: _signupForm.fields.password,
                  obscureText: _obscureSignupPassword,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureSignupPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(
                          () =>
                              _obscureSignupPassword = !_obscureSignupPassword,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Live Password Checklist using exposedRules from Field
                ListenableBuilder(
                  listenable: _signupForm.fields.password,
                  builder: (context, _) {
                    final rules = _signupForm.fields.password.exposedRules;
                    if (rules.isEmpty) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'A senha deve conter:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            children: rules.map((rule) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    rule.isValid
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: rule.isValid
                                        ? Colors.green
                                        : Colors.red[300],
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rule.message,
                                    style: TextStyle(
                                      color: rule.isValid
                                          ? Colors.green[800]
                                          : Colors.grey[600],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                SignalTextField(
                  field: _signupForm.fields.confirmPassword,
                  obscureText: _obscureSignupConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Senha',
                    prefixIcon: const Icon(Icons.lock_clock_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureSignupConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(
                          () => _obscureSignupConfirmPassword =
                              !_obscureSignupConfirmPassword,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SignalCheckbox(
                  field: _signupForm.fields.agreeToTerms,
                  title: const Text(
                    'Aceito os termos e condições',
                    style: TextStyle(fontSize: 14),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 24),
                ListenableBuilder(
                  listenable: _signupForm,
                  builder: (context, _) {
                    return FilledButton(
                      onPressed: _signupForm.isSubmitting
                          ? null
                          : _handleSignupSubmit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _signupForm.isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Cadastrar',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
