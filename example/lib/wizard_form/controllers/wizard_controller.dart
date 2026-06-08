import 'package:flutter/foundation.dart';
import 'package:signal_form/signal_form.dart';

/// Central controller to manage wizard navigation and state
class WizardController extends ChangeNotifier {
  final FormController form;
  final List<String> stepPaths;

  int _currentStep = 0;

  WizardController({required this.form, required this.stepPaths});

  int get currentStep => _currentStep;
  int get totalSteps => stepPaths.length;
  bool get isFirstStep => _currentStep == 0;
  bool get isLastStep => _currentStep == totalSteps - 1;
  double get progress => (currentStep + 1) / totalSteps;

  Future<bool> validateCurrentStep() async {
    final path = stepPaths[_currentStep];
    return await form.trigger(
      path: path,
      shouldFocus: true,
      shouldScroll: true,
    );
  }

  Future<void> nextStep() async {
    if (await validateCurrentStep()) {
      if (!isLastStep) {
        _currentStep++;
        notifyListeners();
      }
    }
  }

  void previousStep() {
    if (!isFirstStep) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < totalSteps) {
      _currentStep = step;
      notifyListeners();
    }
  }
}
