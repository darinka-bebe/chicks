import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/services/sync_coordinator.dart';
import '../../core/sync/sync_scope.dart';
import '../../core/sync/sync_state.dart';

/// Exposes cloud sync status to UI layers without Firestore dependencies.
class SyncStateController extends ChangeNotifier {
  SyncStateController({SyncCoordinator? coordinator})
      : _coordinator = coordinator ?? SyncCoordinator.instance {
    _subscription = _coordinator.stateStream.listen(_onStateChanged);
    _refreshSubscription = _coordinator.refreshStream.listen(_onRefreshScope);
  }

  final SyncCoordinator _coordinator;
  late final StreamSubscription<SyncState> _subscription;
  late final StreamSubscription<SyncScope> _refreshSubscription;

  SyncState _state = SyncCoordinator.instance.state;
  final Map<SyncScope, VoidCallback> _refreshHandlers = {};

  SyncState get state => _state;
  bool get isSyncing => _state.isSyncing;
  bool get canRetry => _state.canRetry;

  void registerRefreshHandler(SyncScope scope, VoidCallback handler) {
    _refreshHandlers[scope] = handler;
  }

  void unregisterRefreshHandler(SyncScope scope) {
    _refreshHandlers.remove(scope);
  }

  Future<void> retry() => _coordinator.retry();

  void _onStateChanged(SyncState next) {
    _state = next;
    notifyListeners();
  }

  void _onRefreshScope(SyncScope scope) {
    _refreshHandlers[scope]?.call();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _refreshSubscription.cancel();
    super.dispose();
  }
}
