import 'dart:async';
import 'dart:io';

import '../../data/repositories/auth_repository.dart';
import '../sync/cloud_sync_hooks.dart';
import '../sync/sync_meta_storage.dart';
import '../sync/sync_scope.dart';
import '../sync/sync_state.dart';
import '../utils/logger.dart';
import 'cloud_sync_service.dart';
import 'firebase_auth_service.dart';
import 'firebase_bootstrap.dart';
import 'wardrobe_sync_service.dart';

/// Orchestrates background cloud sync: restore on login, debounced upload.
class SyncCoordinator {
  SyncCoordinator._();

  static final SyncCoordinator instance = SyncCoordinator._();

  final CloudSyncService _cloudSync = CloudSyncService.instance;

  final StreamController<SyncState> _stateController =
      StreamController<SyncState>.broadcast();

  final StreamController<SyncScope> _refreshController =
      StreamController<SyncScope>.broadcast();

  SyncState _state = const SyncState();
  Timer? _debounceTimer;
  Timer? _bannerResetTimer;
  bool _suppressUpload = false;
  bool _isSyncing = false;

  Stream<SyncState> get stateStream => _stateController.stream;
  Stream<SyncScope> get refreshStream => _refreshController.stream;
  SyncState get state => _state;

  void initialize() {
    CloudSyncHooks.bind(_onLocalDataChanged);
    AppLogger.info('SyncCoordinator: initialized');
  }

  Future<T> runWithoutUpload<T>(Future<T> Function() action) async {
    _suppressUpload = true;
    try {
      return await action();
    } finally {
      _suppressUpload = false;
    }
  }

  Future<void> restoreAfterLogin({String? uid}) async {
    final effectiveUid = uid ?? AuthRepository.instance.currentUser.uid;
    if (effectiveUid.isEmpty) {
      AppLogger.warning('SyncCoordinator.restoreAfterLogin: skipped (no uid)');
      return;
    }

    await _runFullSync(
      uid: effectiveUid,
      pullFirst: true,
      reason: 'login_restore',
    );
  }

  Future<void> syncOnResume() async {
    final uid = AuthRepository.instance.currentUser.uid;
    if (uid.isEmpty || _isSyncing) return;

    AppLogger.debug('SyncCoordinator.syncOnResume: uid=$uid');
    await _runFullSync(uid: uid, pullFirst: true, reason: 'app_resume');
  }

  Future<void> retry() async {
    final uid = AuthRepository.instance.currentUser.uid;
    if (uid.isEmpty) return;
    await _runFullSync(uid: uid, pullFirst: true, reason: 'manual_retry');
  }

  void schedulePush({SyncScope? scope}) {
    final uid = AuthRepository.instance.currentUser.uid;
    if (uid.isEmpty || _suppressUpload) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 900), () {
      unawaited(_pushOnly(uid: uid, scope: scope));
    });
  }

  Future<void> _onLocalDataChanged(
    SyncScope scope, {
    String? deletedId,
  }) async {
    final uid = AuthRepository.instance.currentUser.uid;
    if (uid.isEmpty || _suppressUpload) return;

    if (deletedId != null && deletedId.trim().isNotEmpty) {
      final docId = deletedId.trim();
      await SyncMetaStorage.addPendingDelete(scope, docId);
      await SyncMetaStorage.removeTimestamp(scope, docId);
      AppLogger.info(
        'SyncCoordinator: immediate delete push '
        'scope=${scope.name} localId=$docId firestoreDocId=$docId '
        'path=users/$uid/${scope.firestoreCollectionName}/$docId',
      );
      await _pushOnly(uid: uid, scope: scope);
      return;
    }

    schedulePush(scope: scope);
  }

  Future<void> _runFullSync({
    required String uid,
    required bool pullFirst,
    required String reason,
  }) async {
    if (_isSyncing) {
      AppLogger.debug('SyncCoordinator: skip $reason (sync in progress)');
      return;
    }

    if (!await _isCloudReachable()) {
      AppLogger.warning(
        'SyncCoordinator: skip $reason — firestore.googleapis.com unreachable',
      );
      return;
    }

    if (!await _ensureAuthReady()) {
      AppLogger.warning('SyncCoordinator: skip $reason — auth token not ready');
      return;
    }

    _isSyncing = true;
    _emit(
      _state.copyWith(
        phase: SyncPhase.syncing,
        uid: uid,
        clearError: true,
        clearMessage: true,
        message: 'Синхронизация…',
      ),
    );

    AppLogger.info('SyncCoordinator: start $reason uid=$uid');

    try {
      CloudSyncPullResult? pullResult;
      CloudSyncPushResult? pushResult;

      if (pullFirst) {
        pullResult = await runWithoutUpload(
          () => _cloudSync.pullAndMergeAll(
            uid: uid,
            persistLocally: () async {},
          ),
        );
        _emitRefreshForAll();
      }

      pushResult = await _cloudSync.pushAll(uid: uid);
      await WardrobeSyncService.loadFreshWardrobeForAi();

      _emit(
        _state.copyWith(
          phase: SyncPhase.success,
          uid: uid,
          lastSuccessAt: DateTime.now(),
          restoredCounts: pullResult?.restoredCounts ?? _state.restoredCounts,
          uploadedCounts: pushResult.uploadedCounts,
          conflictCount: pullResult?.conflictCount ?? _state.conflictCount,
          message: 'Данные синхронизированы',
          clearError: true,
        ),
      );

      AppLogger.info('SyncCoordinator: success $reason uid=$uid');
    } catch (e, stack) {
      final offline = _looksOffline(e);
      final channel = FirestoreBootstrap.isChannelError(e);
      final permissionDenied = FirestoreBootstrap.isPermissionDenied(e);
      _emit(
        _state.copyWith(
          phase: offline ? SyncPhase.offline : SyncPhase.error,
          uid: uid,
          lastError: '$e',
          message: channel
              ? 'Firestore не подключён — сделайте полную пересборку приложения'
              : permissionDenied
                  ? 'Нет доступа к Firestore — настройте правила в Firebase Console'
                  : offline
                      ? 'Облако недоступно — используются локальные данные'
                      : 'Ошибка синхронизации',
        ),
      );
      AppLogger.error(
        'SyncCoordinator: failed $reason uid=$uid',
        error: e,
        stackTrace: stack,
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushOnly({required String uid, SyncScope? scope}) async {
    if (_suppressUpload) return;
    if (_isSyncing && scope == null) return;

    if (!await _isCloudReachable()) {
      AppLogger.warning(
        'SyncCoordinator: skip push — firestore.googleapis.com unreachable',
      );
      return;
    }

    if (!await _ensureAuthReady()) {
      AppLogger.warning('SyncCoordinator: skip push — auth token not ready');
      return;
    }

    final scopedDuringSync = _isSyncing && scope != null;
    if (!scopedDuringSync) {
      _isSyncing = true;
    }
    _emit(
      _state.copyWith(
        phase: SyncPhase.syncing,
        uid: uid,
        message: scope == null ? 'Отправка в облако…' : 'Отправка ${scope.name}…',
        clearError: true,
      ),
    );

    AppLogger.info(
      'SyncCoordinator: push start uid=$uid scope=${scope?.name ?? 'all'}',
    );

    try {
      final result = scope != null
          ? await _cloudSync.pushScope(uid: uid, scope: scope)
          : await _cloudSync.pushAll(uid: uid);
      _emit(
        _state.copyWith(
          phase: SyncPhase.success,
          uid: uid,
          lastSuccessAt: DateTime.now(),
          uploadedCounts: result.uploadedCounts,
          message: 'Изменения сохранены в облаке',
          clearError: true,
        ),
      );
      AppLogger.info('SyncCoordinator: push success uid=$uid');
    } catch (e, stack) {
      final offline = _looksOffline(e);
      _emit(
        _state.copyWith(
          phase: offline ? SyncPhase.offline : SyncPhase.error,
          uid: uid,
          lastError: '$e',
          message: offline
              ? 'Облако недоступно — изменения сохранены локально'
              : 'Не удалось отправить в облако',
        ),
      );
      AppLogger.error(
        'SyncCoordinator: push failed uid=$uid',
        error: e,
        stackTrace: stack,
      );
    } finally {
      if (!scopedDuringSync) {
        _isSyncing = false;
      }
    }
  }

  void _emitRefreshForAll() {
    for (final scope in SyncScope.values) {
      _refreshController.add(scope);
    }
  }

  void _emit(SyncState next) {
    _state = next;
    if (!_stateController.isClosed) {
      _stateController.add(next);
    }

    _bannerResetTimer?.cancel();
    if (next.phase == SyncPhase.offline ||
        next.phase == SyncPhase.error ||
        next.phase == SyncPhase.success) {
      _bannerResetTimer = Timer(const Duration(seconds: 5), () {
        if (_state.phase != SyncPhase.syncing) {
          _emit(_state.copyWith(phase: SyncPhase.idle, clearMessage: true));
        }
      });
    }
  }

  bool _looksOffline(Object error) {
    if (FirestoreBootstrap.isChannelError(error)) return false;
    final text = error.toString().toLowerCase();
    return text.contains('network') ||
        text.contains('offline') ||
        text.contains('unavailable') ||
        text.contains('connection');
  }

  Future<bool> _isCloudReachable() async {
    try {
      final addresses = await InternetAddress.lookup('firestore.googleapis.com')
          .timeout(const Duration(seconds: 2));
      return addresses.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _ensureAuthReady() async {
    try {
      await FirebaseAuthService.instance.ensureIdTokenReady();
      return FirebaseAuthService.instance.currentFirebaseUser != null;
    } catch (e) {
      AppLogger.warning('SyncCoordinator: ensureAuthReady failed ($e)');
      return false;
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
    _bannerResetTimer?.cancel();
    _stateController.close();
    _refreshController.close();
  }
}
