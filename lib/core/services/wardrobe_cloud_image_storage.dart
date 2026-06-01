import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../../data/models/wardrobe_item.dart';
import '../utils/logger.dart';
import '../widgets/wardrobe_item_image.dart';

/// Uploads wardrobe photos to Firebase Storage and returns download URLs.
abstract final class WardrobeCloudImageStorage {
  static const _folder = 'wardrobe_images';

  static Reference _objectRef(String uid, String itemId) {
    return FirebaseStorage.instance.ref('users/$uid/$_folder/$itemId.jpg');
  }

  /// Uploads a local file when needed; returns item with [WardrobeItem.imageUrl].
  static Future<WardrobeItem> syncItemImage({
    required WardrobeItem item,
    required String uid,
  }) async {
    if (uid.trim().isEmpty) return item;

    final localPath = item.imagePath?.trim() ?? '';
    if (!_shouldUpload(localPath)) return item;

    try {
      final url = await _uploadFile(
        uid: uid,
        itemId: item.id,
        localPath: localPath,
      );
      if (url == null || url.isEmpty) return item;

      AppLogger.info(
        'WardrobeCloudImageStorage: uploaded item=${item.id} url=$url',
      );
      return item.copyWith(imageUrl: url);
    } catch (e, stack) {
      AppLogger.error(
        'WardrobeCloudImageStorage: upload failed item=${item.id}',
        error: e,
        stackTrace: stack,
      );
      return item;
    }
  }

  static Future<List<WardrobeItem>> syncAllItems({
    required List<WardrobeItem> items,
    required String uid,
  }) async {
    if (uid.trim().isEmpty) return items;

    final result = <WardrobeItem>[];
    for (final item in items) {
      result.add(await syncItemImage(item: item, uid: uid));
    }
    return result;
  }

  static Future<void> deleteIfStored({
    required String uid,
    required String itemId,
  }) async {
    if (uid.trim().isEmpty || itemId.trim().isEmpty) return;

    try {
      await _objectRef(uid, itemId).delete();
      AppLogger.info(
        'WardrobeCloudImageStorage: deleted storage object item=$itemId',
      );
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return;
      AppLogger.warning(
        'WardrobeCloudImageStorage: delete failed item=$itemId code=${e.code}',
      );
    } catch (e, stack) {
      AppLogger.error(
        'WardrobeCloudImageStorage: delete failed item=$itemId',
        error: e,
        stackTrace: stack,
      );
    }
  }

  static bool _shouldUpload(String localPath) {
    if (localPath.isEmpty) return false;
    if (WardrobeItemImage.isAssetPath(localPath)) return false;
    if (WardrobeItemImage.looksLikeRemoteUrl(localPath)) return false;
    return File(localPath).existsSync();
  }

  static Future<String?> _uploadFile({
    required String uid,
    required String itemId,
    required String localPath,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) return null;

    final ref = _objectRef(uid, itemId);
    await ref.putFile(
      file,
      SettableMetadata(contentType: _mimeType(localPath)),
    );
    return ref.getDownloadURL();
  }

  static String _mimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
