import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/seasonal_color_type.dart';
import '../../core/utils/logger.dart';

/// Local user style profile (color type quiz, etc.).
class UserProfileRepository {
  UserProfileRepository._();

  static final UserProfileRepository instance = UserProfileRepository._();

  static const _colorTypeKey = 'user_color_type_v1';
  static const _quizCompletedKey = 'user_color_type_quiz_completed_v1';

  Future<SeasonalColorType?> getColorType() async {
    final prefs = await SharedPreferences.getInstance();
    return SeasonalColorType.fromStorageKey(prefs.getString(_colorTypeKey));
  }

  Future<void> saveColorType(SeasonalColorType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorTypeKey, type.storageKey);
    AppLogger.info(
      'UserProfileRepository: saved color type ${type.englishLabel}',
    );
  }

  Future<void> clearColorType() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_colorTypeKey);
  }

  Future<bool> isColorTypeQuizCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_quizCompletedKey) ?? false;
  }

  Future<void> setColorTypeQuizCompleted({required bool completed}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_quizCompletedKey, completed);
  }
}
