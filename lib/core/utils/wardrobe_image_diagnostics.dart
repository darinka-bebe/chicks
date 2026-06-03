import '../../data/models/wardrobe_item.dart';
import '../utils/logger.dart';

/// Diagnostics for wardrobe cloud URLs and pending uploads.
abstract final class WardrobeImageDiagnostics {
  static bool isResolvableItem(WardrobeItem item) => item.hasDisplayImage;

  static String classifyItem(WardrobeItem item) {
    if (WardrobeItem.hasCloudImageUrl(item)) return 'cloud_url';
    if (WardrobeItem.isAssetPath(item.imagePath)) return 'asset';
    if (WardrobeItem.hasPendingLocalUpload(item)) return 'pending_upload';
    final path = item.imagePath?.trim() ?? '';
    if (path.isNotEmpty) return 'local_file_missing';
    return 'empty';
  }

  static void logItems(String context, List<WardrobeItem> items) {
    if (items.isEmpty) {
      AppLogger.info('WardrobeImageDiagnostics.$context: no items');
      return;
    }

    var empty = 0;
    var asset = 0;
    var cloudUrl = 0;
    var pending = 0;
    var missing = 0;

    for (final item in items) {
      switch (classifyItem(item)) {
        case 'empty':
          empty++;
        case 'asset':
          asset++;
        case 'cloud_url':
          cloudUrl++;
        case 'pending_upload':
          pending++;
        case 'local_file_missing':
          missing++;
          AppLogger.warning(
            'WardrobeImageDiagnostics.$context: stale local path '
            'id=${item.id} title="${item.title}" path=${item.imagePath}',
          );
      }
    }

    AppLogger.info(
      'WardrobeImageDiagnostics.$context: total=${items.length} '
      'empty=$empty asset=$asset cloudUrl=$cloudUrl '
      'pendingUpload=$pending staleLocal=$missing',
    );
  }

  static void logFirestorePayload(String context, List<Map<String, dynamic>> docs) {
    if (docs.isEmpty) {
      AppLogger.info('WardrobeImageDiagnostics.$context: firestore empty');
      return;
    }

    var withImagePath = 0;
    var withImageUrl = 0;
    for (final doc in docs) {
      final path = doc['imagePath']?.toString().trim() ?? '';
      final url = doc['imageUrl']?.toString().trim() ?? '';
      if (path.isNotEmpty) withImagePath++;
      if (url.isNotEmpty) withImageUrl++;
    }

    AppLogger.info(
      'WardrobeImageDiagnostics.$context: firestore docs=${docs.length} '
      'withImagePath=$withImagePath withImageUrl=$withImageUrl',
    );
  }
}
