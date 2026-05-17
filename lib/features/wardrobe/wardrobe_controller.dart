import 'package:flutter/foundation.dart';

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

  List<WardrobeItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;

  Future<void> ensureLoaded() async {
    if (_isLoaded) return;
    await refresh();
  }

  /// Full reload from Hive (shows loading only on first load).
  Future<void> refresh() async {
    final showLoading = !_isLoaded;
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    _items = await _repository.loadItems();
    _isLoaded = true;
    _isLoading = false;

    AppLogger.debug(
      'WardrobeController.refresh: ${_items.length} item(s)',
    );
    notifyListeners();
  }

  /// Reload without clearing the grid (after returning from a sub-route).
  Future<void> reloadFromStorage() async {
    _items = await _repository.loadItems();
    _isLoaded = true;
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

  /// Call after item was removed from Hive (e.g. details screen).
  void onItemDeleted(String id) {
    AppLogger.info('WardrobeController.onItemDeleted: id=$id');
    _items =
        _items.where((i) => !WardrobeRepository.idEquals(i.id, id)).toList();
    notifyListeners();
  }
}
