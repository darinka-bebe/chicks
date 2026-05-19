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

  /// Updates in-memory cache from a direct Hive read (AI / sync path).
  void publishRepositorySnapshot(List<WardrobeItem> items) {
    _memoryCache = List<WardrobeItem>.from(items);
    _cacheRevision = _revision;
    AppLogger.info(
      'WardrobeAiContext: repository snapshot rev=$_revision count=${items.length}',
    );
    if (items.isEmpty) {
      AppLogger.debug('WardrobeAiContext: repository ids=(empty)');
    } else {
      AppLogger.debug(
        'WardrobeAiContext: repository ids=${items.map((i) => i.id).join(", ")}',
      );
    }
  }

  /// Loads from Hive; coalesces concurrent calls and reuses cache per revision.
  Future<List<WardrobeItem>> loadForPrompt({bool forceReload = false}) async {
    if (!forceReload &&
        _memoryCache != null &&
        _cacheRevision == _revision) {
      AppLogger.debug(
        'WardrobeAiContext: cache hit rev=$_revision count=${_memoryCache!.length}',
      );
      return List<WardrobeItem>.from(_memoryCache!);
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
    final loadRevision = _revision;

    final items = await _repository.loadItems();

    if (loadRevision != _revision) {
      AppLogger.warning(
        'WardrobeAiContext: discarded stale load (started rev=$loadRevision '
        'current rev=$_revision) — reloading',
      );
      return loadForPrompt(forceReload: true);
    }

    _memoryCache = List<WardrobeItem>.from(items);
    _cacheRevision = _revision;

    AppLogger.info(
      'WardrobeAiContext: loadForPrompt rev=$_revision count=${items.length}',
    );

    if (items.isEmpty) {
      AppLogger.debug('WardrobeAiContext: prompt titles=(empty)');
    } else {
      final titles = items.map((item) => item.title).toList();
      AppLogger.debug(
        'WardrobeAiContext: prompt titles=${titles.join(' | ')}',
      );
      AppLogger.debug(
        'WardrobeAiContext: prompt ids=${items.map((i) => i.id).join(", ")}',
      );
    }

    return List<WardrobeItem>.from(items);
  }
}
