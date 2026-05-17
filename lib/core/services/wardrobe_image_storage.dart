import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/logger.dart';

/// Copies gallery/file picks into app-private storage so [File] paths stay valid.
class WardrobeImageStorage {
  static const _subdir = 'wardrobe_images';

  /// Reads [file] bytes and writes them under the app documents directory.
  static Future<String?> persistFromXFile(XFile file) async {
    try {
      AppLogger.debug(
        'WardrobeImageStorage: reading bytes from ${file.name} (${file.path})',
      );
      final bytes = await file.readAsBytes();
      return persistBytes(bytes, sourceHint: file.path);
    } catch (e, stack) {
      AppLogger.error(
        'WardrobeImageStorage.persistFromXFile failed',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Copies an on-disk file (Downloads, Documents provider path, etc.).
  static Future<String?> persistFromPath(
    String sourcePath, {
    String? fallbackName,
  }) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) {
        AppLogger.error('WardrobeImageStorage: source missing at $sourcePath');
        return null;
      }
      final bytes = await source.readAsBytes();
      return persistBytes(
        bytes,
        sourceHint: sourcePath,
        fallbackName: fallbackName,
      );
    } catch (e, stack) {
      AppLogger.error(
        'WardrobeImageStorage.persistFromPath failed',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// SAF / file_picker may return in-memory bytes without a stable path.
  static Future<String?> persistFromPlatformFile(PlatformFile file) async {
    AppLogger.debug(
      'WardrobeImageStorage: PlatformFile name=${file.name} '
      'path=${file.path} size=${file.size}',
    );

    if (file.path != null && file.path!.trim().isNotEmpty) {
      return persistFromPath(file.path!, fallbackName: file.name);
    }

    final bytes = file.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      return persistBytes(bytes, fallbackName: file.name);
    }

    AppLogger.error('WardrobeImageStorage: PlatformFile has no path or bytes');
    return null;
  }

  static Future<String?> persistBytes(
    List<int> bytes, {
    String? sourceHint,
    String? fallbackName,
  }) async {
    if (bytes.isEmpty) {
      AppLogger.error('WardrobeImageStorage: persistBytes empty');
      return null;
    }

    AppLogger.debug('WardrobeImageStorage: persist ${bytes.length} bytes');

    final docsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${docsDir.path}/$_subdir');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final extension = _resolveExtension(sourceHint ?? fallbackName ?? '');
    final output = File(
      '${imagesDir.path}/wardrobe_${DateTime.now().millisecondsSinceEpoch}$extension',
    );
    await output.writeAsBytes(bytes, flush: true);

    if (!await output.exists()) {
      AppLogger.error('WardrobeImageStorage: output file missing after write');
      return null;
    }

    AppLogger.info('WardrobeImageStorage: persisted to ${output.path}');
    return output.path;
  }

  /// Deletes a file only if it lives under app wardrobe image storage.
  static Future<void> deleteIfStored(String? imagePath) async {
    if (imagePath == null || imagePath.trim().isEmpty) return;

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final wardrobeDir = '${docsDir.path}/$_subdir';
      final normalized = File(imagePath).absolute.path;

      if (!normalized.contains(wardrobeDir)) {
        AppLogger.debug(
          'WardrobeImageStorage: skip delete — path outside wardrobe dir',
        );
        return;
      }

      final file = File(normalized);
      if (await file.exists()) {
        await file.delete();
        AppLogger.info('WardrobeImageStorage: deleted image $normalized');
      }
    } catch (e, stack) {
      AppLogger.error(
        'WardrobeImageStorage.deleteIfStored failed',
        error: e,
        stackTrace: stack,
      );
    }
  }

  static String _resolveExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return '.jpg';
    final ext = path.substring(dot).toLowerCase();
    if (ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.webp') {
      return ext;
    }
    return '.jpg';
  }
}
