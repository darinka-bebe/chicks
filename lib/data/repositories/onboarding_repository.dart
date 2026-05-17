import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user has completed first-launch onboarding.
class OnboardingRepository {
  OnboardingRepository._();

  static final OnboardingRepository instance = OnboardingRepository._();

  static const _completedKey = 'onboarding_completed_v1';

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  Future<void> setCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }
}
