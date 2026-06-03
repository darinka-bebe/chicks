import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../../data/models/wardrobe_item.dart';
import '../utils/logger.dart';
import 'wardrobe_image_storage.dart';

/// Firebase Storage is the source of truth for wardrobe photos.
///
/// Object path: `users/{uid}/wardrobe/{itemId}.jpg`
abstract final class WardrobeCloudImageStorage {
  static const _collectionFolder = 'wardrobe';

  static Reference _objectRef(String uid, String itemId) {
    return FirebaseStorage.instance
        .ref('users/$uid/$_collectionFolder/$itemId.jpg');
  }

  /// Uploads a pending local file and returns item with [WardrobeItem.imageUrl].
  static Future<WardrobeItem> syncItemImage({
    required WardrobeItem item,
    required String uid,
  }) async {
    if (uid.trim().isEmpty) return item;

    final normalized = WardrobeItem.normalizeImageFields(item);

    if (WardrobeItem.hasCloudImageUrl(normalized) &&
        !WardrobeItem.hasPendingLocalUpload(normalized)) {
      return normalized;
    }

    final localPath = WardrobeItem.pendingLocalPath(normalized);
    if (localPath == null) return normalized;

    try {
      final url = await _uploadFile(
        uid: uid,
        itemId: normalized.id,
        localPath: localPath,
      );
      if (url == null || url.isEmpty) return normalized;

      AppLogger.info(
        'WardrobeCloudImageStorage: uploaded item=${normalized.id}',
      );
      await WardrobeImageStorage.deleteIfStored(localPath);
      return normalized.copyWith(imageUrl: url, clearImagePath: true);
    } catch (e, stack) {
      AppLogger.error(
        'WardrobeCloudImageStorage: upload failed item=${normalized.id}',
        error: e,
        stackTrace: stack,
      );
      return normalized;
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

    for (final ref in _deleteRefs(uid, itemId)) {
      try {
        await ref.delete();
        AppLogger.info(
          'WardrobeCloudImageStorage: deleted ${ref.fullPath}',
        );
      } on FirebaseException catch (e) {
        if (e.code == 'object-not-found') continue;
        AppLogger.warning(
          'WardrobeCloudImageStorage: delete failed '
          'path=${ref.fullPath} code=${e.code}',
        );
      } catch (e, stack) {
        AppLogger.error(
          'WardrobeCloudImageStorage: delete failed path=${ref.fullPath}',
          error: e,
          stackTrace: stack,
        );
      }
    }
  }

  /// Legacy path `wardrobe_images/` + current `wardrobe/`.
  static List<Reference> _deleteRefs(String uid, String itemId) {
    return [
      _objectRef(uid, itemId),
      FirebaseStorage.instance
          .ref('users/$uid/wardrobe_images/$itemId.jpg'),
    ];
  }

  static Future<String?> _uploadFile({
    required String uid,
    required String itemId,
    required String localPath,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      AppLogger.warning(
        'WardrobeCloudImageStorage: local file missing $localPath',
      );
      return null;
    }

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
