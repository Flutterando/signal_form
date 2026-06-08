abstract class BlocFormState {
  const BlocFormState();
}

class BlocFormInitial extends BlocFormState {
  const BlocFormInitial();
}

class BlocFormSubmitting extends BlocFormState {
  const BlocFormSubmitting();
}

class BlocFormSuccess extends BlocFormState {
  final Map<String, dynamic> data;
  const BlocFormSuccess(this.data);
}

class BlocFormFailure extends BlocFormState {
  final String errorMessage;
  const BlocFormFailure(this.errorMessage);
}
