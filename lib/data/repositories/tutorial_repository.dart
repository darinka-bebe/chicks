import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/collection_names.dart';
import '../../core/storage/user_scoped_prefs.dart';
import '../../core/sync/cloud_sync_hooks.dart';
import '../../core/sync/sync_meta_storage.dart';
import '../../core/sync/sync_scope.dart';
import 'auth_repository.dart';

/// Persists whether the signed-in user has seen the in-app product tutorial.
class TutorialRepository {
  TutorialRepository._();

  static final TutorialRepository instance = TutorialRepository._();

  static const _baseKey = 'product_tutorial_completed_v2';
  static const _legacyGlobalKey = 'product_tutorial_completed_v1';

  String _keyFor(String uid) => UserScopedPrefs.key(_baseKey, uid);

  String? _resolveUid(String? uid) {
    final resolved = (uid ?? AuthRepository.instance.currentUser.uid).trim();
    return resolved.isEmpty ? null : resolved;
  }

  Future<bool> isCompleted({String? uid}) async {
    final resolved = _resolveUid(uid);
    if (resolved == null) return true;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyFor(resolved)) ?? false) return true;

    return _migrateLegacyGlobal(prefs, resolved);
  }

  Future<bool> _migrateLegacyGlobal(
    SharedPreferences prefs,
    String uid,
  ) async {
    if (!(prefs.getBool(_legacyGlobalKey) ?? false)) return false;

    await prefs.setBool(_keyFor(uid), true);
    await prefs.remove(_legacyGlobalKey);
    return true;
  }

  Future<void> setCompleted({bool completed = true, String? uid}) async {
    await setCompletedLocally(completed: completed, uid: uid);
    await SyncMetaStorage.touch(
      SyncScope.profile,
      CollectionNames.profileMainDocId,
    );
    CloudSyncHooks.onLocalDataChanged(SyncScope.profile);
  }

  Future<void> setCompletedLocally({
    bool completed = true,
    String? uid,
  }) async {
    final resolved = _resolveUid(uid);
    if (resolved == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(resolved);
    if (completed) {
      await prefs.setBool(key, true);
    } else {
      await prefs.remove(key);
    }
  }
}
