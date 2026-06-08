import 'package:example/simple_form/extensions.dart';
import 'package:signal_form/signal_form.dart';

typedef RegisterFormFields = ({
  // Step 1: Account
  ({Field<String> email, Field<String> password, Field<String> confirmPassword})
  account,

  // Step 2: Personal
  ({
    Field<String> fullName,
    Field<String> phone,
    Field<bool> hasWebsite,
    Field<String> websiteUrl,
    Field<DateTime> birthDate,
  })
  personal,

  // Step 3: Preferences
  ({
    Field<List<String>> interests,
    Field<String> referralSource,
    Field<bool> acceptTerms,
    Field<bool> acceptNewsletter,
  })
  preferences,

  // Step 4: Payment
  ({
    Field<String> cardNumber,
    Field<String> expiryDate,
    Field<String> cvv,
    Field<String> cardHolderName,
  })
  payment,
});

/// Factory
FormController<RegisterFormFields> createRegisterForm() => formCtrl(
  () => (
    account: formGroup(
      'account',
      () => (
        email: Field<String>('email')
            .required(message: 'E-mail é obrigatório')
            .email(message: 'Formato de e-mail inválido')
            .customUniqueEmail(),
        password: Field<String>('password')
            .required(message: 'Senha é obrigatória')
            .minLength(8, message: 'Mínimo 8 caracteres', exposed: true)
            .mustHaveUppercase(message: 'Uma letra maiúscula', exposed: true)
            .mustHaveLowercase(message: 'Uma letra minúscula', exposed: true)
            .mustHaveNumber(message: 'Um número', exposed: true),
        confirmPassword: Field<String>('confirmPassword')
            .required(message: 'Confirme sua senha')
            .equals((valueOf) => valueOf<String>('account.password')),
      ),
    ),
    personal: formGroup(
      'personal',
      () => (
        fullName: Field<String>('fullName')
            .required(message: 'Nome completo é obrigatório')
            .minLength(3, message: 'Nome muito curto'),
        phone: Field<String>(
          'phone',
        ).required(message: 'Telefone é obrigatório').mask('(##) #####-####'),
        hasWebsite: Field<bool>('hasWebsite', false),
        websiteUrl: Field<String>('websiteUrl').applyWhen(
          (valueOf) => valueOf<bool>('personal.hasWebsite').isChecked,
          (f) => f
              .required(message: 'URL é obrigatória')
              .validUrl(message: 'URL inválida'),
        ),
        birthDate: Field<DateTime>('birthDate')
            .required(message: 'Data de nascimento é obrigatória')
            .between(
              DateTime(1900),
              DateTime.now().subtract(const Duration(days: 18 * 365)),
              message: 'Você deve ter pelo menos 18 anos',
            ),
      ),
    ),
    preferences: formGroup(
      'preferences',
      () => (
        interests: Field<List<String>>(
          'interests',
          [],
        ).minItems(1, message: 'Selecione pelo menos 1 interesse'),
        referralSource: Field<String>('referralSource')
            .required(message: 'Informe como nos conheceu')
            .oneOf([
              'google',
              'social',
              'friend',
              'other',
            ], message: 'Selecione uma opção válida'),
        acceptTerms:
            Field<bool>('acceptTerms', false) //
                .mustBeTrue(message: 'Você deve aceitar os termos de uso'),
        acceptNewsletter: Field<bool>('acceptNewsletter', false),
      ),
    ),
    payment: formGroup(
      'payment',
      () => (
        cardNumber: Field<String>('cardNumber')
            .required(message: 'Número do cartão é obrigatório')
            .validCreditCard()
            .mask('#### #### #### ####'),
        expiryDate: Field<String>('expiryDate')
            .required(message: 'Validade é obrigatória')
            .mask('##/##')
            .customValidExpiryDate(),
        cvv: Field<String>(
          'cvv',
        ).required(message: 'CVV é obrigatório').mask('###'),
        cardHolderName: Field<String>('cardHolderName')
            .required(message: 'Nome impresso no cartão é obrigatório')
            .minLength(3, message: 'Nome muito curto'),
      ),
    ),
  ),
);

extension PaymentValidators on Field<String> {
  Field<String> customValidExpiryDate([
    String message = 'Validade inválida (MM/AA)',
  ]) {
    return addValidator(message, (val) {
      if (val == null || val.length < 5) return true;
      final parts = val.split('/');
      if (parts.length != 2) return true;
      final month = int.tryParse(parts[0]);
      final year = int.tryParse(parts[1]);
      if (month == null || year == null) return true;
      if (month < 1 || month > 12) return true;
      return false;
    });
  }
}
