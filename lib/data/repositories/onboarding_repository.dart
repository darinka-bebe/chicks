import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/collection_names.dart';
import '../../core/sync/cloud_sync_hooks.dart';
import '../../core/sync/sync_meta_storage.dart';
import '../../core/sync/sync_scope.dart';

/// Persists whether the user has completed first-launch onboarding.
class OnboardingRepository {
  OnboardingRepository._();

  static final OnboardingRepository instance = OnboardingRepository._();

  static const _completedKey = 'onboarding_completed_v1';

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  Future<void> setCompleted({bool completed = true}) async {
    await setCompletedLocally(completed: completed);
    await SyncMetaStorage.touch(
      SyncScope.profile,
      CollectionNames.profileMainDocId,
    );
    CloudSyncHooks.onLocalDataChanged(SyncScope.profile);
  }

  Future<void> setCompletedLocally({bool completed = true}) async {
    final prefs = await SharedPreferences.getInstance();
    if (completed) {
      await prefs.setBool(_completedKey, true);
    } else {
      await prefs.remove(_completedKey);
    }
  }
}
