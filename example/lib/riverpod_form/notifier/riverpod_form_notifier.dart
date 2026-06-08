import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [AsyncNotifier] responsible for managing the contact form submission.
///
/// The logic is identical to [BlocFormCubit], but expressed with Riverpod's API:
/// - `state = const AsyncLoading()` → equivalent to `emit(BlocFormSubmitting())`
/// - `state = AsyncData(data)`      → equivalent to `emit(BlocFormSuccess(data))`
/// - `state = AsyncError(...)`      → equivalent to `emit(BlocFormFailure(...))`
class RiverpodFormNotifier extends AsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async => null; // initial state

  Future<void> submitFeedback(Map<String, dynamic> data) async {
    state = const AsyncLoading();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    final email = data['email'] as String?;
    if (email == 'error@error.com') {
      state = AsyncError(
        'Erro de Servidor: O e-mail informado foi recusado pelo gateway de envios.',
        StackTrace.current,
      );
    } else {
      state = AsyncData(data);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

/// Global provider for the [RiverpodFormNotifier].
final riverpodFormProvider =
    AsyncNotifierProvider<RiverpodFormNotifier, Map<String, dynamic>?>(
      RiverpodFormNotifier.new,
    );
