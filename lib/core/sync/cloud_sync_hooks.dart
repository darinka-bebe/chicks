import '../sync/sync_scope.dart';

/// Lightweight hook from local repositories into the sync coordinator.
abstract final class CloudSyncHooks {
  static void Function(SyncScope scope, {String? deletedId})? _onChanged;

  static void bind(void Function(SyncScope scope, {String? deletedId}) handler) {
    _onChanged = handler;
  }

  static void onLocalDataChanged(
    SyncScope scope, {
    String? deletedId,
  }) {
    _onChanged?.call(scope, deletedId: deletedId);
  }
}
