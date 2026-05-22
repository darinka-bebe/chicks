import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/logger.dart';

/// Local profile fields (display name override stored via [AuthRepository]).
class ProfilePreferencesRepository {
  ProfilePreferencesRepository._();

  static final ProfilePreferencesRepository instance =
      ProfilePreferencesRepository._();

  static String _usernameKey(String uid) => 'profile_username_$uid';

  Future<String> getUsername(String uid) async {
    if (uid.isEmpty) return '';
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey(uid))?.trim() ?? '';
  }

  Future<void> saveUsername({
    required String uid,
    required String username,
  }) async {
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_usernameKey(uid));
    } else {
      await prefs.setString(_usernameKey(uid), trimmed);
    }
    AppLogger.info('ProfilePreferencesRepository: username saved');
  }
}
