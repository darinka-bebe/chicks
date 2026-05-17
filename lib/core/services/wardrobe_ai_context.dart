import 'package:flutter/foundation.dart';

import '../../core/utils/logger.dart';
import '../../data/models/wardrobe_item.dart';
import '../../data/repositories/wardrobe_repository.dart';

/// Live wardrobe snapshot for AI prompts with a short-lived in-memory cache.
class WardrobeAiContext extends ChangeNotifier {
  WardrobeAiContext._({WardrobeRepository? repository})
      : _repository = repository ?? WardrobeRepository.instance;

  static final WardrobeAiContext instance = WardrobeAiContext._();

  final WardrobeRepository _repository;

  int _revision = 0;
  List<WardrobeItem>? _memoryCache;
  int _cacheRevision = -1;
  Future<List<WardrobeItem>>? _inFlightLoad;

  /// Bumps when wardrobe is written (add/delete/edit). Used in AI freshness guard.
  int get revision => _revision;

  /// In-memory snapshot when revision matches (for sync UI resolve).
  List<WardrobeItem>? get cachedItems {
    if (_memoryCache != null && _cacheRevision == _revision) {
      return _memoryCache;
    }
    return null;
  }

  /// Call after any wardrobe persistence change.
  void invalidate({required String reason}) {
    _revision++;
    _memoryCache = null;
    _cacheRevision = -1;
    _inFlightLoad = null;
    AppLogger.info(
      'WardrobeAiContext: cache refresh rev=$_revision reason=$reason',
    );
    notifyListeners();
  }

  /// Loads from Hive; coalesces concurrent calls and reuses cache per revision.
  Future<List<WardrobeItem>> loadForPrompt({bool forceReload = false}) async {
    if (!forceReload &&
        _memoryCache != null &&
        _cacheRevision == _revision) {
      return _memoryCache!;
    }

    final inFlight = _inFlightLoad;
    if (!forceReload && inFlight != null) {
      return inFlight;
    }

    final load = _loadFromStorage();
    _inFlightLoad = load;
    try {
      return await load;
    } finally {
      if (identical(_inFlightLoad, load)) {
        _inFlightLoad = null;
      }
    }
  }

  Future<List<WardrobeItem>> _loadFromStorage() async {
    final items = await _repository.loadItems();
    _memoryCache = items;
    _cacheRevision = _revision;

    AppLogger.info(
      'WardrobeAiContext: loadForPrompt rev=$_revision '
      'count=${items.length}',
    );

    if (items.isEmpty) {
      AppLogger.debug('WardrobeAiContext: prompt titles=(empty)');
    } else {
      final titles = items.map((item) => item.title).toList();
      AppLogger.debug(
        'WardrobeAiContext: prompt titles=${titles.join(' | ')}',
      );
    }

    return items;
  }
}
