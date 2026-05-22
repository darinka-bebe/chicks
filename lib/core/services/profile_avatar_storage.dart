import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/logger.dart';

/// App documents storage for profile avatars — only paths under [subdir] are permanent.
class ProfileAvatarStorage {
  static const subdir = 'profile_avatars';

  static Future<Directory> _avatarsDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docsDir.path}/$subdir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Stable on-disk file for a user (overwritten on each save).
  static String fileNameForUser(String uid) {
    final safe = uid.replaceAll(RegExp(r'[^\w.-]'), '_');
    return 'avatar_$safe.jpg';
  }

  static Future<String> canonicalPathForUser(String uid) async {
    final dir = await _avatarsDirectory();
    return File('${dir.path}/${fileNameForUser(uid)}').absolute.path;
  }

  /// Writes bytes to the user's canonical avatar file.
  static Future<String?> persistBytesForUser(
    String uid,
    List<int> bytes, {
    String? sourceHint,
  }) async {
    if (uid.trim().isEmpty || bytes.isEmpty) return null;

    final dir = await _avatarsDirectory();
    final output = File('${dir.path}/${fileNameForUser(uid)}');
    await output.writeAsBytes(bytes, flush: true);

    if (!await _isReadableFile(output)) {
      AppLogger.warning('ProfileAvatarStorage: canonical write failed');
      return null;
    }

    AppLogger.info('ProfileAvatarStorage: saved canonical ${output.path}');
    return output.absolute.path;
  }

  static Future<String?> persistFromXFile(XFile file, {required String uid}) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      return persistBytesForUser(uid, bytes, sourceHint: file.path);
    } catch (e, stack) {
      AppLogger.error(
        'ProfileAvatarStorage.persistFromXFile failed',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Copies any readable local file into the user's canonical avatar path.
  static Future<String?> persistFromPath(
    String sourcePath, {
    required String uid,
    String? fallbackName,
  }) async {
    try {
      final absolute = await _existingAbsolutePath(sourcePath);
      if (absolute == null) {
        AppLogger.warning('ProfileAvatarStorage: source missing at $sourcePath');
        return null;
      }
      final bytes = await File(absolute).readAsBytes();
      return persistBytesForUser(
        uid,
        bytes,
        sourceHint: sourcePath,
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

  static Future<String?> persistFromPlatformFile(
    PlatformFile file, {
    required String uid,
  }) async {
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return persistBytesForUser(uid, file.bytes!);
    }
    if (file.path != null && file.path!.trim().isNotEmpty) {
      return persistFromPath(file.path!, uid: uid, fallbackName: file.name);
    }
    return null;
  }

  /// Legacy helper — prefer [persistBytesForUser] with uid.
  static Future<String?> persistBytes(
    List<int> bytes, {
    String? sourceHint,
    String? fallbackName,
  }) async {
    if (bytes.isEmpty) return null;

    final dir = await _avatarsDirectory();
    final extension = _resolveExtension(sourceHint ?? fallbackName ?? '');
    final output = File(
      '${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}$extension',
    );
    await output.writeAsBytes(bytes, flush: true);
    if (!await _isReadableFile(output)) return null;
    return output.absolute.path;
  }

  /// Ensures [path] is copied into the user's canonical avatar file (overwrites).
  static Future<String> ensurePermanentAvatarPath(
    String path, {
    required String uid,
  }) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty || uid.trim().isEmpty) return '';
    if (_isRemoteUrl(trimmed)) return trimmed;

    final canonical = await canonicalPathForUser(uid);
    final absolute = await _existingAbsolutePath(trimmed);
    if (absolute == null) {
      final canonicalFile = File(canonical);
      return await _isReadableFile(canonicalFile) ? canonical : '';
    }

    final normalizedAbsolute = absolute.replaceAll('\\', '/');
    final normalizedCanonical = canonical.replaceAll('\\', '/');
    if (normalizedAbsolute == normalizedCanonical &&
        await _isReadableFile(File(canonical))) {
      return canonical;
    }

    try {
      final bytes = await File(absolute).readAsBytes();
      if (bytes.isEmpty) return '';
      final saved = await persistBytesForUser(uid, bytes, sourceHint: absolute);
      return saved ?? '';
    } catch (e, stack) {
      AppLogger.error(
        'ProfileAvatarStorage.ensurePermanentAvatarPath failed',
        error: e,
        stackTrace: stack,
      );
      return '';
    }
  }

  /// Returns a readable local path or '' (never returns dead temp paths).
  static Future<String> resolveValidLocalPath(
    String path, {
    String? uid,
  }) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '';
    if (_isRemoteUrl(trimmed)) return trimmed;

    final safeUid = uid?.trim() ?? '';
    if (safeUid.isNotEmpty) {
      final canonical = await canonicalPathForUser(safeUid);
      if (await _isReadableFile(File(canonical))) {
        return canonical;
      }
    }

    final absolute = await _existingAbsolutePath(trimmed);
    if (absolute == null) return '';

    if (isStoredAvatarPath(absolute) && await _isReadableFile(File(absolute))) {
      return absolute;
    }

    if (safeUid.isNotEmpty) {
      return ensurePermanentAvatarPath(absolute, uid: safeUid);
    }

    return await _isReadableFile(File(absolute)) ? absolute : '';
  }

  static bool isStoredAvatarPath(String? path) {
    if (path == null || path.trim().isEmpty) return false;
    final normalized = path.replaceAll('\\', '/');
    return normalized.contains('/$subdir/');
  }

  static bool isEphemeralPath(String? path) {
    if (path == null || path.trim().isEmpty) return false;
    final lower = path.toLowerCase();
    if (_isRemoteUrl(path)) return false;
    if (isStoredAvatarPath(path)) return false;
    return lower.contains('/cache/') ||
        lower.contains('/tmp/') ||
        lower.contains('wardrobe_images') ||
        lower.startsWith('content://') ||
        lower.contains('/picker/');
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

  /// Removes legacy timestamped avatar files (keeps [keepPath]).
  static Future<void> pruneLegacyAvatars({
    required String uid,
    String? keepPath,
  }) async {
    try {
      final dir = await _avatarsDirectory();
      final keep = keepPath?.trim() ?? '';
      final canonical = await canonicalPathForUser(uid);
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final path = entity.absolute.path;
        if (path == keep || path == canonical) continue;
        if (entity.path.contains('avatar_')) {
          await entity.delete();
        }
      }
    } catch (e, stack) {
      AppLogger.error(
        'ProfileAvatarStorage.pruneLegacyAvatars failed',
        error: e,
        stackTrace: stack,
      );
    }
  }

  static Future<String?> _existingAbsolutePath(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;
    if (_isRemoteUrl(trimmed)) return null;

    if (trimmed.startsWith('content://')) {
      AppLogger.warning('ProfileAvatarStorage: content URI not supported $trimmed');
      return null;
    }

    final file = File(trimmed);
    if (await file.exists()) return file.absolute.path;
    return null;
  }

  static Future<bool> _isReadableFile(File file) async {
    try {
      return await file.exists() && await file.length() > 0;
    } catch (_) {
      return false;
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
