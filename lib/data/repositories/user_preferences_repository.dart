import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/body_profile.dart';
import '../../core/models/outfit_preference_profile.dart';
import '../../core/models/seasonal_color_type.dart';
import '../../core/models/stylist_defaults.dart';
import '../../core/models/stylist_request_context.dart';
import '../../core/models/user_preferences_bundle.dart';
import '../../core/services/collection_names.dart';
import '../../core/sync/cloud_sync_hooks.dart';
import '../../core/sync/sync_meta_storage.dart';
import '../../core/sync/sync_scope.dart';
import '../../core/utils/logger.dart';
import 'auth_repository.dart';
import 'favorites_repository.dart';
import 'onboarding_repository.dart';
import 'outfit_dislike_repository.dart';
import 'profile_preferences_repository.dart';
import 'user_profile_repository.dart';

/// Single entry point for all persisted user taste & profile preferences.
class UserPreferencesRepository {
  UserPreferencesRepository._();

  static final UserPreferencesRepository instance = UserPreferencesRepository._();

  static String _stylistDefaultsKey(String uid) => 'stylist_defaults_v1_$uid';

  Future<UserPreferencesBundle> loadBundle({String? uid}) async {
    final effectiveUid = uid ?? AuthRepository.instance.currentUser.uid;
    final styleRepo = UserProfileRepository.instance;
    final results = await Future.wait([
      styleRepo.getColorType(),
      styleRepo.getBodyProfile(),
      OnboardingRepository.instance.isCompleted(),
      styleRepo.isColorTypeQuizCompleted(),
      styleRepo.isBodyTypeQuizCompleted(),
      FavoritesRepository.instance.countOutfits(),
      OutfitDislikeRepository.instance.loadProfile(),
      _loadStylistDefaults(effectiveUid),
      effectiveUid.isEmpty
          ? Future<String>.value('')
          : ProfilePreferencesRepository.instance.getUsername(effectiveUid),
    ]);

    final dislikeProfile = results[6] as OutfitPreferenceProfile;
    return UserPreferencesBundle(
      colorType: results[0] as SeasonalColorType?,
      bodyProfile: results[1] as BodyProfile?,
      onboardingCompleted: results[2] as bool,
      colorQuizCompleted: results[3] as bool,
      bodyQuizCompleted: results[4] as bool,
      favoritesCount: results[5] as int,
      dislikeProfile: dislikeProfile,
      dislikesCount: dislikeProfile.totalDislikes,
      stylistDefaults: results[7] as StylistDefaults,
      username: results[8] as String,
    );
  }

  Future<StylistDefaults> getStylistDefaults({String? uid}) async {
    final effectiveUid = uid ?? AuthRepository.instance.currentUser.uid;
    return _loadStylistDefaults(effectiveUid);
  }

  /// Merges parsed chat context into per-user stylist defaults.
  Future<void> recordStylistInteraction(
    StylistRequestContext context, {
    String? uid,
  }) async {
    if (context.isEmpty) return;

    final effectiveUid = uid ?? AuthRepository.instance.currentUser.uid;
    if (effectiveUid.isEmpty) return;

    final current = await _loadStylistDefaults(effectiveUid);
    final merged = current.mergeInteraction(context).sanitized();
    await saveStylistDefaultsLocally(effectiveUid, merged);
    await _touchProfile();
    CloudSyncHooks.onLocalDataChanged(SyncScope.profile);
    AppLogger.info(
      'UserPreferencesRepository: stylist interaction saved '
      '(moods=${merged.recentMoods.length})',
    );
  }

  Future<void> saveStyleNotes(String notes, {String? uid}) async {
    final effectiveUid = uid ?? AuthRepository.instance.currentUser.uid;
    if (effectiveUid.isEmpty) return;

    final current = await _loadStylistDefaults(effectiveUid);
    await saveStylistDefaultsLocally(
      effectiveUid,
      current.copyWith(
        styleNotes: notes.trim(),
        updatedAt: DateTime.now(),
      ),
    );
    await _touchProfile();
    CloudSyncHooks.onLocalDataChanged(SyncScope.profile);
  }

  Future<void> restoreAllCaches() async {
    await Future.wait([
      UserProfileRepository.instance.getColorType(),
      UserProfileRepository.instance.getBodyProfile(),
      OutfitDislikeRepository.instance.loadProfile(),
      FavoritesRepository.instance.loadOutfits(),
      getStylistDefaults(),
    ]);
    AppLogger.info('UserPreferencesRepository: all preference caches restored');
  }

  Future<StylistDefaults> _loadStylistDefaults(String uid) async {
    if (uid.isEmpty) return StylistDefaults.empty;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stylistDefaultsKey(uid));
    if (raw == null || raw.trim().isEmpty) return StylistDefaults.empty;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final parsed = StylistDefaults.fromJson(map);
      final cleaned = parsed.sanitized();
      if (parsed.hasDeprecatedContextTags) {
        await _saveStylistDefaults(uid, cleaned);
        await _touchProfile();
        CloudSyncHooks.onLocalDataChanged(SyncScope.profile);
        AppLogger.info(
          'UserPreferencesRepository: removed deprecated stylist tags',
        );
      }
      return cleaned;
    } catch (e) {
      AppLogger.warning(
        'UserPreferencesRepository: corrupt stylist defaults ($e)',
      );
      return StylistDefaults.empty;
    }
  }

  Future<void> saveStylistDefaultsLocally(
    String uid,
    StylistDefaults defaults,
  ) async {
    await _saveStylistDefaults(uid, defaults);
  }

  Future<void> _touchProfile() async {
    await SyncMetaStorage.touch(
      SyncScope.profile,
      CollectionNames.profileMainDocId,
    );
  }

  Future<void> _saveStylistDefaults(String uid, StylistDefaults defaults) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _stylistDefaultsKey(uid),
      jsonEncode(defaults.toJson()),
    );
  }
}
