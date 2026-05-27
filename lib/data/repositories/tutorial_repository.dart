import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user has seen the in-app product tutorial.
class TutorialRepository {
  TutorialRepository._();

  static final TutorialRepository instance = TutorialRepository._();

  static const _completedKey = 'product_tutorial_completed_v1';

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  Future<void> setCompleted({bool completed = true}) async {
    final prefs = await SharedPreferences.getInstance();
    if (completed) {
      await prefs.setBool(_completedKey, true);
    } else {
      await prefs.remove(_completedKey);
    }
  }
}
