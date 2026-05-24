/// Shared onboarding funnel step indices (welcome → color → body).
abstract final class OnboardingFunnel {
  static const totalSteps = 3;

  static const stepWelcome = 1;
  static const stepColorQuiz = 2;
  static const stepBodyQuiz = 3;

  static String stepLabel(int step) => 'Шаг $step из $totalSteps';
}
