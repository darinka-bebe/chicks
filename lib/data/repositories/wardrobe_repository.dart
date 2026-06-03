import '../../core/services/wardrobe_image_migration_service.dart';
import '../../core/services/wardrobe_sync_service.dart';
import '../../core/services/wardrobe_image_storage.dart';
import '../../core/services/wardrobe_cloud_image_storage.dart';
import '../../core/storage/hive_json_list_codec.dart';
import '../../core/storage/local_hive_storage.dart';
import '../../core/sync/cloud_sync_hooks.dart';
import '../../core/sync/sync_meta_storage.dart';
import '../../core/sync/sync_scope.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/wardrobe_image_diagnostics.dart';
import '../../features/wardrobe/data/mock_wardrobe_data.dart';
import '../models/wardrobe_item.dart';
import 'auth_repository.dart';

/// Local wardrobe persistence (Hive).
class WardrobeRepository {
  WardrobeRepository._();

  static final WardrobeRepository instance = WardrobeRepository._();

  static const _itemsKey = LocalHiveStorage.wardrobeItemsKey;

  static String generateItemId() =>
      'wardrobe_${DateTime.now().microsecondsSinceEpoch}';

  static bool _isMockSeedItem(WardrobeItem item) =>
      MockWardrobeData.isDemoItem(item);

  /// Removes bundled demo wardrobe rows (ids 1–8) from local + cloud.
  Future<List<WardrobeItem>> _removeMockSeedItems(List<WardrobeItem> items) async {
    final mockItems = items.where(_isMockSeedItem).toList();
    if (mockItems.isEmpty) return items;

    final uid = AuthRepository.instance.currentUser.uid;
    for (final item in mockItems) {
      await SyncMetaStorage.addPendingDelete(SyncScope.wardrobe, item.id);
      if (uid.isNotEmpty) {
        await WardrobeCloudImageStorage.deleteIfStored(
          uid: uid,
          itemId: item.id,
        );
      }
    }

    final filtered = items.where((item) => !_isMockSeedItem(item)).toList();
    await saveItemsLocally(filtered);
    CloudSyncHooks.onLocalDataChanged(SyncScope.wardrobe);
    AppLogger.info(
      'WardrobeRepository: removed ${mockItems.length} demo item(s)',
    );
    return filtered;
  }

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
      AppLogger.info('WardrobeRepository.loadItems: empty wardrobe');
      return const [];
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
        await saveItemsLocally(normalized);
      }

      final withoutDemo = await _removeMockSeedItems(normalized);
      final migrated = await WardrobeImageMigrationService.migrateAll(withoutDemo);
      if (_imageFieldsChanged(withoutDemo, migrated)) {
        await saveItemsLocally(migrated);
      }
      WardrobeImageDiagnostics.logItems('loadItems', migrated);
      _logItemIds('loadItems', migrated);
      return migrated;
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

  Future<void> saveItems(
    List<WardrobeItem> items, {
    String? deletedItemId,
  }) async {
    await saveItemsLocally(items, deletedItemId: deletedItemId);
    await SyncMetaStorage.touchAll(
      SyncScope.wardrobe,
      items.map((item) => item.id),
    );
    CloudSyncHooks.onLocalDataChanged(
      SyncScope.wardrobe,
      deletedId: deletedItemId,
    );
  }

  /// Persists wardrobe without triggering cloud upload (used during restore).
  Future<void> saveItemsLocally(
    List<WardrobeItem> items, {
    String? deletedItemId,
  }) async {
    final normalized = _ensureUniqueIds(items);
    await HiveJsonListCodec.write(
      LocalHiveStorage.wardrobeBox,
      _itemsKey,
      normalized.map((item) => item.toJson()).toList(),
    );
    AppLogger.debug(
      'WardrobeRepository.saveItems: wrote ${normalized.length} item(s)',
    );
    await WardrobeSyncService.afterWardrobeMutation(
      reason: deletedItemId != null ? 'deleteItem' : 'saveItems',
      deletedItemId: deletedItemId,
    );
  }

  Future<WardrobeItem> addItem(WardrobeItem item) async {
    final resolvedId = item.id.trim().isEmpty ? generateItemId() : item.id.trim();
    var toSave = resolvedId == item.id
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
            imageUrl: item.imageUrl,
          );

    toSave = await _uploadImageIfNeeded(toSave);

    AppLogger.info(
      'WardrobeRepository.addItem: id=${toSave.id} title="${toSave.title}" '
      'imageUrl=${toSave.imageUrl != null}',
    );

    final items = await loadItems();
    final updated = [...items, toSave];
    await saveItems(updated);
    AppLogger.info(
      'WardrobeRepository.addItem: persisted ${updated.length} item(s)',
    );
    return toSave;
  }

  Future<WardrobeItem> updateItem(WardrobeItem item) async {
    final needle = item.id.trim();
    if (needle.isEmpty) {
      throw ArgumentError('WardrobeItem.id is required for update');
    }

    final items = await loadItems();
    final index = items.indexWhere((row) => _idEquals(row.id, needle));
    if (index < 0) {
      throw StateError('WardrobeRepository.updateItem: id not found ($needle)');
    }

    final toSave = await _uploadImageIfNeeded(item);

    final updated = [...items];
    updated[index] = toSave;
    await saveItems(updated);
    AppLogger.info(
      'WardrobeRepository.updateItem: id=$needle title="${item.title}" '
      'imageUrl=${toSave.imageUrl != null}',
    );
    return toSave;
  }

  Future<WardrobeItem> _uploadImageIfNeeded(WardrobeItem item) async {
    return WardrobeImageMigrationService.migrateItem(item);
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
      'WardrobeRepository.deleteItem: matched '
      'localId=${target.id} firestoreDocId=${target.firestoreDocId} '
      'title="${target.title}"',
    );

    await WardrobeImageStorage.deleteIfStored(target.imagePath);
    final uid = AuthRepository.instance.currentUser.uid;
    if (uid.isNotEmpty) {
      await WardrobeCloudImageStorage.deleteIfStored(
        uid: uid,
        itemId: target.id,
      );
    }

    final updated =
        items.where((item) => !_idEquals(item.id, target!.id)).toList();
    await saveItems(updated, deletedItemId: target.firestoreDocId);
    AppLogger.info(
      'WardrobeRepository.deleteItem: removed "${target.title}" '
      '(${updated.length} left) firestorePath=${target.firestorePath('{uid}')}',
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
            imageUrl: item.imageUrl,
          ),
        );
      }
    }

    return result;
  }

  static bool _imageFieldsChanged(
    List<WardrobeItem> before,
    List<WardrobeItem> after,
  ) {
    if (before.length != after.length) return true;
    final afterById = {for (final item in after) item.id: item};
    for (final item in before) {
      final next = afterById[item.id];
      if (next == null) return true;
      if (item.imageUrl != next.imageUrl || item.imagePath != next.imagePath) {
        return true;
      }
    }
    return false;
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
