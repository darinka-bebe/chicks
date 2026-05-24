import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/body_profile.dart';
import '../../core/models/seasonal_color_type.dart';
import '../../core/sync/cloud_sync_hooks.dart';
import '../../core/sync/sync_meta_storage.dart';
import '../../core/sync/sync_scope.dart';
import '../../core/utils/logger.dart';
import '../../core/services/collection_names.dart';

/// Local user style profile (color type, body shape, fit prefs).
class UserProfileRepository {
  UserProfileRepository._();

  static final UserProfileRepository instance = UserProfileRepository._();

  static const _colorTypeKey = 'user_color_type_v1';
  static const _colorQuizCompletedKey = 'user_color_type_quiz_completed_v1';
  static const _bodyProfileKey = 'user_body_profile_v1';
  static const _bodyQuizCompletedKey = 'user_body_quiz_completed_v1';

  Future<SeasonalColorType?> getColorType() async {
    final prefs = await SharedPreferences.getInstance();
    return SeasonalColorType.fromStorageKey(prefs.getString(_colorTypeKey));
  }

  Future<void> saveColorType(SeasonalColorType type) async {
    await saveColorTypeLocally(type);
    await _touchProfile();
    CloudSyncHooks.onLocalDataChanged(SyncScope.profile);
  }

  Future<void> saveColorTypeLocally(SeasonalColorType type) async {
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
    return prefs.getBool(_colorQuizCompletedKey) ?? false;
  }

  Future<void> setColorTypeQuizCompleted({required bool completed}) async {
    await setColorTypeQuizCompletedLocally(completed: completed);
    await _touchProfile();
    CloudSyncHooks.onLocalDataChanged(SyncScope.profile);
  }

  Future<void> setColorTypeQuizCompletedLocally({required bool completed}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_colorQuizCompletedKey, completed);
  }

  Future<BodyProfile?> getBodyProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_bodyProfileKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return BodyProfile.fromJson(map);
    } catch (e) {
      AppLogger.warning('UserProfileRepository: corrupt body profile ($e)');
      return null;
    }
  }

  Future<void> saveBodyProfile(BodyProfile profile) async {
    await saveBodyProfileLocally(profile);
    await _touchProfile();
    CloudSyncHooks.onLocalDataChanged(SyncScope.profile);
  }

  Future<void> saveBodyProfileLocally(BodyProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bodyProfileKey, jsonEncode(profile.toJson()));
    AppLogger.info(
      'UserProfileRepository: saved body shape ${profile.shape.englishLabel}',
    );
  }

  Future<void> clearBodyProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bodyProfileKey);
  }

  Future<bool> isBodyTypeQuizCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_bodyQuizCompletedKey) ?? false;
  }

  Future<void> setBodyTypeQuizCompleted({required bool completed}) async {
    await setBodyTypeQuizCompletedLocally(completed: completed);
    await _touchProfile();
    CloudSyncHooks.onLocalDataChanged(SyncScope.profile);
  }

  Future<void> setBodyTypeQuizCompletedLocally({required bool completed}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bodyQuizCompletedKey, completed);
  }

  Future<void> _touchProfile() async {
    await SyncMetaStorage.touch(
      SyncScope.profile,
      CollectionNames.profileMainDocId,
    );
  }
}
