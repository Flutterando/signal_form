import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc_form_state.dart';

class BlocFormCubit extends Cubit<BlocFormState> {
  BlocFormCubit() : super(const BlocFormInitial());

  Future<void> submitFeedback(Map<String, dynamic> data) async {
    emit(const BlocFormSubmitting());
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    final email = data['email'] as String?;
    if (email == 'error@error.com') {
      emit(const BlocFormFailure('Erro de Servidor: O e-mail informado foi recusado pelo gateway de envios.'));
    } else {
      emit(BlocFormSuccess(data));
    }
  }
}
