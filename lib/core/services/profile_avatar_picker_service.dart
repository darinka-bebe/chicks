import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/logger.dart';

enum ProfileAvatarPickStatus {
  success,
  cancelled,
  permissionDenied,
  failed,
}

class ProfileAvatarPickResult {
  const ProfileAvatarPickResult({
    required this.status,
    this.localPath,
    this.message,
  });

  final ProfileAvatarPickStatus status;
  final String? localPath;
  final String? message;

  bool get isSuccess => status == ProfileAvatarPickStatus.success;
}

/// Gallery picker for profile avatar (crop + persist happen elsewhere).
abstract final class ProfileAvatarPickerService {
  /// Picks one image from gallery; returns a temp/cache file path.
  static Future<ProfileAvatarPickResult> pickGalleryFile() async {
    if (!await _ensureGalleryPermission()) {
      return const ProfileAvatarPickResult(
        status: ProfileAvatarPickStatus.permissionDenied,
        message:
            'Нет доступа к фото. Разрешите доступ или выберите снимок снова.',
      );
    }

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
        maxWidth: 4096,
        maxHeight: 4096,
        requestFullMetadata: false,
      );

      if (picked == null) {
        return const ProfileAvatarPickResult(
          status: ProfileAvatarPickStatus.cancelled,
        );
      }

      final path = picked.path.trim();
      if (path.isEmpty) {
        return const ProfileAvatarPickResult(
          status: ProfileAvatarPickStatus.failed,
          message: 'Не удалось получить путь к фото',
        );
      }

      final file = File(path);
      if (!await file.exists() || await file.length() == 0) {
        return const ProfileAvatarPickResult(
          status: ProfileAvatarPickStatus.failed,
          message: 'Выбранный файл недоступен',
        );
      }

      AppLogger.debug(
        'ProfileAvatarPicker: XFile path=$path name=${picked.name}',
      );

      return ProfileAvatarPickResult(
        status: ProfileAvatarPickStatus.success,
        localPath: path,
      );
    } on MissingPluginException catch (e, stack) {
      AppLogger.error(
        'ProfileAvatarPicker: native plugin missing',
        error: e,
        stackTrace: stack,
      );
      return const ProfileAvatarPickResult(
        status: ProfileAvatarPickStatus.failed,
        message: 'Ошибка доступа к галерее на устройстве',
      );
    } on PlatformException catch (e, stack) {
      AppLogger.error(
        'ProfileAvatarPicker: PlatformException',
        error: e,
        stackTrace: stack,
      );
      return ProfileAvatarPickResult(
        status: ProfileAvatarPickStatus.failed,
        message: e.message ?? 'Ошибка при выборе фото',
      );
    } catch (e, stack) {
      AppLogger.error(
        'ProfileAvatarPicker: unexpected',
        error: e,
        stackTrace: stack,
      );
      return const ProfileAvatarPickResult(
        status: ProfileAvatarPickStatus.failed,
        message: 'Ошибка при выборе фото',
      );
    }
  }

  static Future<bool> _ensureGalleryPermission() async {
    if (Platform.isAndroid) {
      return _ensureAndroidGalleryPermission();
    }
    if (!Platform.isIOS) return true;
    return _ensureIosPhotosPermission();
  }

  static Future<bool> _ensureAndroidGalleryPermission() async {
    try {
      var photos = await Permission.photos.status;
      if (photos.isGranted || photos.isLimited) return true;

      photos = await Permission.photos.request();
      if (photos.isGranted || photos.isLimited) return true;
      if (photos.isPermanentlyDenied) return false;

      return true;
    } on MissingPluginException {
      return true;
    } catch (e, stack) {
      AppLogger.error(
        'ProfileAvatarPicker: permission check failed',
        error: e,
        stackTrace: stack,
      );
      return true;
    }
  }

  static Future<bool> _ensureIosPhotosPermission() async {
    try {
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    } on MissingPluginException {
      return true;
    }
  }
}
