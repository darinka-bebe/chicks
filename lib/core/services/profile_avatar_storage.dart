import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/logger.dart';

/// App-private storage for profile avatar images (local paths only).
class ProfileAvatarStorage {
  static const _subdir = 'profile_avatars';

  static Future<String?> persistFromXFile(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      return persistBytes(bytes, sourceHint: file.path);
    } catch (e, stack) {
      AppLogger.error(
        'ProfileAvatarStorage.persistFromXFile failed',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  static Future<String?> persistFromPath(
    String sourcePath, {
    String? fallbackName,
  }) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) {
        AppLogger.warning('ProfileAvatarStorage: source missing at $sourcePath');
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
        'ProfileAvatarStorage.persistFromPath failed',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  static Future<String?> persistFromPlatformFile(PlatformFile file) async {
    if (file.path != null && file.path!.trim().isNotEmpty) {
      return persistFromPath(file.path!, fallbackName: file.name);
    }
    final bytes = file.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      return persistBytes(bytes, fallbackName: file.name);
    }
    return null;
  }

  static Future<String?> persistBytes(
    List<int> bytes, {
    String? sourceHint,
    String? fallbackName,
  }) async {
    if (bytes.isEmpty) return null;

    final docsDir = await getApplicationDocumentsDirectory();
    final avatarsDir = Directory('${docsDir.path}/$_subdir');
    if (!await avatarsDir.exists()) {
      await avatarsDir.create(recursive: true);
    }

    final extension = _resolveExtension(sourceHint ?? fallbackName ?? '');
    final output = File(
      '${avatarsDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}$extension',
    );
    await output.writeAsBytes(bytes, flush: true);

    if (!await output.exists()) return null;

    AppLogger.info('ProfileAvatarStorage: saved ${output.path}');
    return output.path;
  }

  /// Returns [path] if it is a readable local file; otherwise ''.
  static Future<String> resolveValidLocalPath(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '';
    if (_isRemoteUrl(trimmed)) return trimmed;

    final file = File(trimmed);
    if (await file.exists() && await file.length() > 0) {
      return file.absolute.path;
    }

    AppLogger.warning('ProfileAvatarStorage: missing avatar at $trimmed');
    return '';
  }

  static bool isStoredAvatarPath(String? path) {
    if (path == null || path.trim().isEmpty) return false;
    return path.contains('/$_subdir/') || path.contains('\\$_subdir\\');
  }

  static Future<void> deleteIfStored(String? imagePath) async {
    if (imagePath == null || imagePath.trim().isEmpty) return;
    if (!isStoredAvatarPath(imagePath)) return;

    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        AppLogger.info('ProfileAvatarStorage: deleted $imagePath');
      }
    } catch (e, stack) {
      AppLogger.error(
        'ProfileAvatarStorage.deleteIfStored failed',
        error: e,
        stackTrace: stack,
      );
    }
  }

  static bool _isRemoteUrl(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
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
