import '../../data/models/wardrobe_item.dart';
import '../../data/repositories/auth_repository.dart';
import '../utils/logger.dart';
import 'wardrobe_cloud_image_storage.dart';
import 'wardrobe_image_storage.dart';

/// Uploads pending local photos to Firebase Storage and normalizes items to [imageUrl].
abstract final class WardrobeImageMigrationService {
  /// Ensures every item uses a cloud [imageUrl]; clears device-local [imagePath].
  static Future<List<WardrobeItem>> migrateAll(List<WardrobeItem> items) async {
    final uid = AuthRepository.instance.currentUser.uid;
    if (uid.isEmpty || items.isEmpty) return items;

    var changed = false;
    final result = <WardrobeItem>[];

    for (final item in items) {
      final migrated = await migrateItem(item, uid: uid);
      if (migrated != item) changed = true;
      result.add(migrated);
    }

    if (changed) {
      AppLogger.info(
        'WardrobeImageMigrationService: migrated/normalized ${result.length} item(s)',
      );
    }
    return result;
  }

  static Future<WardrobeItem> migrateItem(
    WardrobeItem item, {
    String? uid,
  }) async {
    final resolvedUid = uid ?? AuthRepository.instance.currentUser.uid;
    if (resolvedUid.isEmpty) return WardrobeItem.normalizeImageFields(item);

    var normalized = WardrobeItem.normalizeImageFields(item);

    if (WardrobeItem.hasCloudImageUrl(normalized)) {
      if (normalized.imagePath != null) {
        await WardrobeImageStorage.deleteIfStored(normalized.imagePath);
        normalized = normalized.copyWith(clearImagePath: true);
      }
      return normalized;
    }

    final uploaded = await WardrobeCloudImageStorage.syncItemImage(
      item: normalized,
      uid: resolvedUid,
    );

    if (WardrobeItem.hasCloudImageUrl(uploaded)) {
      await WardrobeImageStorage.deleteIfStored(uploaded.imagePath);
      return uploaded.copyWith(clearImagePath: true);
    }

    return uploaded;
  }
}
