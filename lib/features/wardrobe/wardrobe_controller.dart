import 'package:flutter/foundation.dart';

import '../../core/services/wardrobe_sync_service.dart';
import '../../core/services/wardrobe_ai_context.dart';
import '../../core/utils/logger.dart';
import '../../data/models/wardrobe_item.dart';
import '../../data/repositories/wardrobe_repository.dart';

/// Shared wardrobe list state — keeps grid in sync after add/delete.
class WardrobeController extends ChangeNotifier {
  WardrobeController({WardrobeRepository? repository})
      : _repository = repository ?? WardrobeRepository.instance;

  final WardrobeRepository _repository;

  List<WardrobeItem> _items = [];
  bool _isLoading = false;
  bool _isLoaded = false;
  String? _loadError;
  int _lastSyncedRevision = -1;

  List<WardrobeItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  String? get loadError => _loadError;

  Future<void> ensureLoaded() async {
    if (_isLoaded) return;
    await refresh();
  }

  /// Full reload from Hive (shows loading only on first load).
  Future<void> refresh() async {
    final showLoading = !_isLoaded;
    if (showLoading) {
      _isLoading = true;
      _loadError = null;
      notifyListeners();
    }

    try {
      _items = await _repository.loadItems();
      _isLoaded = true;
      _loadError = null;
      _lastSyncedRevision = WardrobeAiContext.instance.revision;
    } catch (e, stack) {
      AppLogger.error(
        'WardrobeController.refresh failed',
        error: e,
        stackTrace: stack,
      );
      _loadError = 'Не удалось загрузить гардероб';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    AppLogger.debug(
      'WardrobeController.refresh: ${_items.length} item(s)',
    );
  }

  /// Reload from Hive only when AI wardrobe revision changed (avoids redundant reads).
  Future<void> reloadIfRevisionChanged() async {
    final revision = WardrobeAiContext.instance.revision;
    if (_isLoaded && _lastSyncedRevision == revision) {
      AppLogger.debug(
        'WardrobeController: skip reload (revision=$revision unchanged)',
      );
      return;
    }

    await reloadFromStorage();
  }

  /// Reload without clearing the grid (after returning from a sub-route).
  Future<void> reloadFromStorage() async {
    try {
      _items = await _repository.loadItems();
      _isLoaded = true;
      _loadError = null;
      _lastSyncedRevision = WardrobeAiContext.instance.revision;
    } catch (e, stack) {
      AppLogger.error(
        'WardrobeController.reloadFromStorage failed',
        error: e,
        stackTrace: stack,
      );
      _loadError = 'Не удалось загрузить гардероб';
    }
    _isLoading = false;
    AppLogger.debug(
      'WardrobeController.reloadFromStorage: ${_items.length} item(s)',
    );
    notifyListeners();
  }

  /// Call after add screen persisted a new item.
  Future<void> onItemAdded(WardrobeItem item) async {
    AppLogger.info('WardrobeController.onItemAdded: id=${item.id}');

    _items = [
      item,
      ..._items.where((i) => !WardrobeRepository.idEquals(i.id, item.id)),
    ];
    _isLoaded = true;
    _isLoading = false;
    notifyListeners();

    _items = await _repository.loadItems();
    notifyListeners();
  }

  /// Call after edit screen persisted changes.
  Future<void> onItemUpdated(WardrobeItem item) async {
    AppLogger.info('WardrobeController.onItemUpdated: id=${item.id}');

    _items = [
      item,
      ..._items.where((i) => !WardrobeRepository.idEquals(i.id, item.id)),
    ];
    _isLoaded = true;
    _isLoading = false;
    notifyListeners();

    _items = await _repository.loadItems();
    notifyListeners();

    await WardrobeSyncService.afterWardrobeMutation(reason: 'itemUpdated');
  }

  /// Call after item was removed from Hive (e.g. details screen).
  Future<void> onItemDeleted(String id) async {
    AppLogger.info('WardrobeController.onItemDeleted: id=$id');
    _items =
        _items.where((i) => !WardrobeRepository.idEquals(i.id, id)).toList();
    _isLoaded = true;
    notifyListeners();

    // Repository.deleteItem already syncs AI cache; reload UI + verify Hive.
    await reloadFromStorage();
    try {
      final fresh = await WardrobeSyncService.loadFreshWardrobeForAi();
      AppLogger.info(
        'WardrobeController.onItemDeleted: verified wardrobeCount=${fresh.length}',
      );
    } catch (e, stack) {
      AppLogger.error(
        'WardrobeController.onItemDeleted: wardrobe sync verify failed',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
