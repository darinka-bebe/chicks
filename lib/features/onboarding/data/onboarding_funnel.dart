import '../../../core/localization/app_locale.dart';

/// Shared onboarding funnel step indices (welcome → color → body).
abstract final class OnboardingFunnel {
  static const totalSteps = 3;

  static const stepWelcome = 1;
  static const stepColorQuiz = 2;
  static const stepBodyQuiz = 3;

  static String stepLabel(int step) => AppLocale.pick(
        ru: 'Шаг $step из $totalSteps',
        en: 'Step $step of $totalSteps',
      );

  static String welcomeTitle() => AppLocale.pick(
        ru: 'Знакомство с Chicks',
        en: 'Getting to know Chicks',
      );

  static String slideLabel(int current, int total) => AppLocale.pick(
        ru: 'Слайд $current из $total',
        en: 'Slide $current of $total',
      );
}
