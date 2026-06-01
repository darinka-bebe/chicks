import 'dart:io';

import '../../data/models/wardrobe_item.dart';
import '../utils/logger.dart';

/// Diagnostics for wardrobe photo paths and cloud URLs.
abstract final class WardrobeImageDiagnostics {
  static bool isResolvableItem(WardrobeItem item) {
    final url = item.imageUrl?.trim() ?? '';
    if (url.startsWith('http://') || url.startsWith('https://')) return true;
    return isResolvablePath(item.imagePath);
  }

  static bool isResolvablePath(String? path) {
    final trimmed = path?.trim() ?? '';
    if (trimmed.isEmpty) return false;
    if (trimmed.startsWith('assets/')) return true;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return true;
    }
    return File(trimmed).existsSync();
  }

  static String classifyItem(WardrobeItem item) {
    final url = item.imageUrl?.trim() ?? '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return 'cloud_url';
    }
    return classifyPath(item.imagePath);
  }

  static String classifyPath(String? path) {
    final trimmed = path?.trim() ?? '';
    if (trimmed.isEmpty) return 'empty';
    if (trimmed.startsWith('assets/')) return 'asset';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return 'remote_url';
    }
    if (File(trimmed).existsSync()) return 'local_file_ok';
    return 'local_file_missing';
  }

  static void logItems(String context, List<WardrobeItem> items) {
    if (items.isEmpty) {
      AppLogger.info('WardrobeImageDiagnostics.$context: no items');
      return;
    }

    var empty = 0;
    var asset = 0;
    var cloudUrl = 0;
    var localOk = 0;
    var localMissing = 0;

    for (final item in items) {
      switch (classifyItem(item)) {
        case 'empty':
          empty++;
        case 'asset':
          asset++;
        case 'cloud_url':
          cloudUrl++;
        case 'local_file_ok':
          localOk++;
        case 'local_file_missing':
          localMissing++;
          AppLogger.warning(
            'WardrobeImageDiagnostics.$context: missing image '
            'id=${item.id} title="${item.title}" path=${item.imagePath} '
            'url=${item.imageUrl ?? "(none)"}',
          );
      }
    }

    AppLogger.info(
      'WardrobeImageDiagnostics.$context: total=${items.length} '
      'empty=$empty asset=$asset cloudUrl=$cloudUrl '
      'localOk=$localOk localMissing=$localMissing',
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
      AppLogger.info(
        'WardrobeImageDiagnostics.$context: firestore doc '
        'id=${doc['id']} imagePath=${path.isEmpty ? "(none)" : path} '
        'imageUrl=${url.isEmpty ? "(none)" : url}',
      );
    }

    AppLogger.info(
      'WardrobeImageDiagnostics.$context: firestore docs=${docs.length} '
      'withImagePath=$withImagePath withImageUrl=$withImageUrl',
    );
  }

  /// Keeps local photo or cloud URL when merge overwrote with a stale path.
  static List<WardrobeItem> preserveLocalPhotos({
    required List<WardrobeItem> merged,
    required List<WardrobeItem> localBeforeMerge,
  }) {
    if (localBeforeMerge.isEmpty) return merged;

    final localById = {for (final item in localBeforeMerge) item.id: item};
    var repaired = 0;

    final result = merged.map((item) {
      if (isResolvableItem(item)) return item;

      final local = localById[item.id];
      final localUrl = local?.imageUrl?.trim() ?? '';
      if (localUrl.startsWith('http://') || localUrl.startsWith('https://')) {
        repaired++;
        return item.copyWith(imageUrl: localUrl);
      }

      final localPath = local?.imagePath?.trim() ?? '';
      if (localPath.isEmpty || !isResolvablePath(localPath)) return item;

      repaired++;
      AppLogger.warning(
        'WardrobeImageDiagnostics: restored local photo after sync '
        'id=${item.id} remotePath=${item.imagePath ?? "(empty)"} '
        'localPath=$localPath',
      );
      return item.copyWith(imagePath: localPath);
    }).toList();

    if (repaired > 0) {
      AppLogger.info(
        'WardrobeImageDiagnostics: preserved $repaired image(s) after merge',
      );
    }
    return result;
  }
}
