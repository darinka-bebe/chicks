import '../../core/services/wardrobe_ai_context.dart';
import '../../core/services/wardrobe_image_storage.dart';
import '../../core/storage/hive_json_list_codec.dart';
import '../../core/storage/local_hive_storage.dart';
import '../../core/utils/logger.dart';
import '../../features/wardrobe/data/mock_wardrobe_data.dart';
import '../models/wardrobe_item.dart';

/// Local wardrobe persistence (Hive).
class WardrobeRepository {
  WardrobeRepository._();

  static final WardrobeRepository instance = WardrobeRepository._();

  static const _itemsKey = LocalHiveStorage.wardrobeItemsKey;

  static String generateItemId() =>
      'wardrobe_${DateTime.now().microsecondsSinceEpoch}';

  /// Lightweight count for profile stats.
  Future<int> countItems() async {
    return HiveJsonListCodec.countEntries(
      LocalHiveStorage.wardrobeBox,
      _itemsKey,
    );
  }

  Future<List<WardrobeItem>> loadItems() async {
    final maps = HiveJsonListCodec.decode(
      LocalHiveStorage.wardrobeBox.get(_itemsKey),
    );

    if (maps.isEmpty) {
      final seeded = List<WardrobeItem>.from(MockWardrobeData.items);
      await saveItems(seeded);
      AppLogger.info(
        'WardrobeRepository.loadItems: seeded ${seeded.length} mock item(s)',
      );
      _logItemIds('loadItems(seed)', seeded);
      return seeded;
    }

    try {
      final items = maps
          .map(WardrobeItem.fromJson)
          .where((item) => item.title.isNotEmpty)
          .toList();

      final normalized = _ensureUniqueIds(items);
      if (_idsChanged(items, normalized)) {
        AppLogger.warning(
          'WardrobeRepository.loadItems: repaired missing/duplicate ids — persisting',
        );
        await saveItems(normalized);
      }

      _logItemIds('loadItems', normalized);
      return normalized;
    } catch (e, stack) {
      AppLogger.error(
        'WardrobeRepository.loadItems: corrupt data',
        error: e,
        stackTrace: stack,
      );
      await LocalHiveStorage.wardrobeBox.delete(_itemsKey);
      return loadItems();
    }
  }

  Future<void> saveItems(List<WardrobeItem> items) async {
    final normalized = _ensureUniqueIds(items);
    await HiveJsonListCodec.write(
      LocalHiveStorage.wardrobeBox,
      _itemsKey,
      normalized.map((item) => item.toJson()).toList(),
    );
    AppLogger.debug(
      'WardrobeRepository.saveItems: wrote ${normalized.length} item(s)',
    );
    WardrobeAiContext.instance.invalidate(
      reason: 'saveItems(${normalized.length})',
    );
  }

  Future<WardrobeItem> addItem(WardrobeItem item) async {
    final resolvedId = item.id.trim().isEmpty ? generateItemId() : item.id.trim();
    final toSave = resolvedId == item.id
        ? item
        : WardrobeItem(
            id: resolvedId,
            title: item.title,
            category: item.category,
            color: item.color,
            season: item.season,
            fit: item.fit,
            styles: item.styles,
            occasions: item.occasions,
            vibes: item.vibes,
            imagePath: item.imagePath,
          );

    AppLogger.info(
      'WardrobeRepository.addItem: id=${toSave.id} title="${toSave.title}"',
    );

    final items = await loadItems();
    final updated = [...items, toSave];
    await saveItems(updated);
    AppLogger.info(
      'WardrobeRepository.addItem: persisted ${updated.length} item(s)',
    );
    return toSave;
  }

  /// Finds an item by persisted id (string-normalized for Hive int ids).
  Future<WardrobeItem?> findItemById(String id) async {
    final needle = id.trim();
    if (needle.isEmpty) return null;

    final items = await loadItems();
    for (final item in items) {
      if (_idEquals(item.id, needle)) return item;
    }
    return null;
  }

  /// Removes item from Hive and deletes its local image file if stored in-app.
  Future<bool> deleteItem(String id) async {
    final needle = id.trim();
    AppLogger.info('WardrobeRepository.deleteItem: requested id=$needle');

    final items = await loadItems();
    _logItemIds('deleteItem(before)', items);

    WardrobeItem? target;
    for (final item in items) {
      if (_idEquals(item.id, needle)) {
        target = item;
        break;
      }
    }

    if (target == null) {
      AppLogger.warning(
        'WardrobeRepository.deleteItem: id not found ($needle). '
        'Known ids: ${items.map((i) => i.id).join(', ')}',
      );
      return false;
    }

    AppLogger.info(
      'WardrobeRepository.deleteItem: matched id=${target.id} title="${target.title}"',
    );

    await WardrobeImageStorage.deleteIfStored(target.imagePath);

    final updated =
        items.where((item) => !_idEquals(item.id, target!.id)).toList();
    await saveItems(updated);
    AppLogger.info(
      'WardrobeRepository.deleteItem: removed "${target.title}" (${updated.length} left)',
    );
    return true;
  }

  static bool idEquals(String a, String b) => _idEquals(a, b);

  static bool _idEquals(String a, String b) {
    final left = a.trim();
    final right = b.trim();
    if (left.isEmpty || right.isEmpty) return false;
    return left == right;
  }

  static List<WardrobeItem> _ensureUniqueIds(List<WardrobeItem> items) {
    final seen = <String>{};
    final result = <WardrobeItem>[];

    for (final item in items) {
      var id = item.id.trim();
      if (id.isEmpty || seen.contains(id)) {
        final old = id.isEmpty ? '(empty)' : id;
        id = generateItemId();
        AppLogger.warning(
          'WardrobeRepository: reassigned id $old → $id for "${item.title}"',
        );
      }
      seen.add(id);

      if (id == item.id) {
        result.add(item);
      } else {
        result.add(
          WardrobeItem(
            id: id,
            title: item.title,
            category: item.category,
            color: item.color,
            season: item.season,
            fit: item.fit,
            styles: item.styles,
            occasions: item.occasions,
            vibes: item.vibes,
            imagePath: item.imagePath,
          ),
        );
      }
    }

    return result;
  }

  static bool _idsChanged(List<WardrobeItem> before, List<WardrobeItem> after) {
    if (before.length != after.length) return true;
    for (var i = 0; i < before.length; i++) {
      if (before[i].id != after[i].id) return true;
    }
    return false;
  }

  static void _logItemIds(String context, List<WardrobeItem> items) {
    if (items.isEmpty) {
      AppLogger.debug('WardrobeRepository.$context: (empty)');
      return;
    }
    final summary = items
        .map((item) => '${item.id}:${item.title}')
        .take(12)
        .join(' | ');
    AppLogger.debug(
      'WardrobeRepository.$context: count=${items.length} [$summary]',
    );
  }
}
