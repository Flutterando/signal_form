import 'package:signal_form/signal_form.dart';

extension MyCustomValidations on Field<String> {
  Field<String> customUniqueEmail([String message = 'Email inválido']) {
    debounce(const Duration(milliseconds: 800));
    return addValidatorAsync(message, (val) async {
      await Future.delayed(const Duration(milliseconds: 1200));
      return val == 'admin@admin.com';
    });
  }

  Field<String> customPassword() {
    return required(message: 'A senha é obrigatória')
        .minLength(
          6,
          message: 'A senha deve ter pelo menos 6 caracteres',
          exposed: true,
        )
        .mustHaveLowercase(
          message: 'Deve ter pelo menos uma letra minúscula',
          exposed: true,
        )
        .mustHaveUppercase(
          message: 'Deve ter pelo menos uma letra maiúscula',
          exposed: true,
        )
        .mustHaveNumber(message: 'Deve ter pelo menos um número', exposed: true)
        .mustHaveSpecialChar(
          message: 'Deve ter pelo menos um caractere especial',
          exposed: true,
        );
  }
}
