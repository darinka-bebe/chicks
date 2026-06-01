import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/collection_names.dart';
import '../../core/sync/cloud_sync_hooks.dart';
import '../../core/sync/sync_meta_storage.dart';
import '../../core/sync/sync_scope.dart';
import '../../core/utils/logger.dart';

/// Local profile fields (display name override stored via [AuthRepository]).
class ProfilePreferencesRepository {
  ProfilePreferencesRepository._();

  static final ProfilePreferencesRepository instance =
      ProfilePreferencesRepository._();

  static String _usernameKey(String uid) => 'profile_username_$uid';
  static String _cityKey(String uid) => 'profile_city_$uid';
  static String _namePromptDismissedKey(String uid) =>
      'profile_name_prompt_dismissed_$uid';

  Future<bool> wasNamePromptDismissed(String uid) async {
    if (uid.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_namePromptDismissedKey(uid)) ?? false;
  }

  Future<void> setNamePromptDismissed({required String uid}) async {
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_namePromptDismissedKey(uid), true);
  }

  Future<void> clearNamePromptDismissed({required String uid}) async {
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_namePromptDismissedKey(uid));
  }

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
    await SyncMetaStorage.touch(
      SyncScope.profile,
      CollectionNames.profileMainDocId,
    );
    CloudSyncHooks.onLocalDataChanged(SyncScope.profile);
    AppLogger.info('ProfilePreferencesRepository: username saved');
  }

  Future<String> getCity(String uid) async {
    if (uid.isEmpty) return '';
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cityKey(uid))?.trim() ?? '';
  }

  Future<void> saveCity({
    required String uid,
    required String city,
  }) async {
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final trimmed = city.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_cityKey(uid));
    } else {
      await prefs.setString(_cityKey(uid), trimmed);
    }
    await SyncMetaStorage.touch(
      SyncScope.profile,
      CollectionNames.profileMainDocId,
    );
    CloudSyncHooks.onLocalDataChanged(SyncScope.profile);
    AppLogger.info('ProfilePreferencesRepository: city saved "$trimmed"');
  }
}
