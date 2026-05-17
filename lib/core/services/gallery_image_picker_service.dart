import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/logger.dart';
import 'image_import_diagnostics.dart';
import 'wardrobe_image_storage.dart';

enum GalleryPickStatus {
  success,
  cancelled,
  permissionDenied,
  failed,
}

/// How the image was imported (gallery vs direct file access).
enum ImageImportMethod {
  gallery,
  files,
}

class GalleryPickResult {
  const GalleryPickResult._({
    required this.status,
    this.localPath,
    this.message,
    this.method,
  });

  final GalleryPickStatus status;
  final String? localPath;
  final String? message;
  final ImageImportMethod? method;

  bool get isSuccess => status == GalleryPickStatus.success;

  factory GalleryPickResult.success(
    String path, {
    ImageImportMethod? method,
  }) =>
      GalleryPickResult._(
        status: GalleryPickStatus.success,
        localPath: path,
        message: 'Фото добавлено',
        method: method,
      );

  factory GalleryPickResult.cancelled() => const GalleryPickResult._(
        status: GalleryPickStatus.cancelled,
        message:
            'Фото не выбрано. На эмуляторе попробуйте «Файл» → Downloads.',
      );

  factory GalleryPickResult.permissionDenied() => const GalleryPickResult._(
        status: GalleryPickStatus.permissionDenied,
        message:
            'Нет доступа к галерее. Разрешите доступ или выберите файл напрямую.',
      );

  factory GalleryPickResult.failed(String message) => GalleryPickResult._(
        status: GalleryPickStatus.failed,
        message: message,
      );
}

/// Gallery + file import for wardrobe photos (emulator-safe).
abstract final class GalleryImagePickerService {
  /// System gallery / photo picker ([image_picker]).
  static Future<GalleryPickResult> pickFromGallery({
    ImagePicker? picker,
  }) async {
    final imagePicker = picker ?? ImagePicker();

    final permissionOk = await _ensureGalleryPermission();
    if (!permissionOk) {
      AppLogger.warning('ImageImport: gallery permission denied');
      return GalleryPickResult.permissionDenied();
    }

    try {
      AppLogger.debug('ImageImport: pickImage(gallery) started');
      final XFile? picked = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
        requestFullMetadata: false,
      );

      if (picked == null) {
        AppLogger.debug('ImageImport: gallery returned null (cancelled)');
        return GalleryPickResult.cancelled();
      }

      AppLogger.debug(
        'ImageImport: gallery XFile name=${picked.name} path=${picked.path} '
        'mime=${picked.mimeType}',
      );

      return _finalizePersist(
        await WardrobeImageStorage.persistFromXFile(picked),
        method: ImageImportMethod.gallery,
        sourceLabel: 'gallery',
      );
    } on MissingPluginException catch (e, stack) {
      AppLogger.error(
        'ImageImport: image_picker not registered',
        error: e,
        stackTrace: stack,
      );
      return GalleryPickResult.failed(
        'Плагин галереи не подключён. Выполните flutter run заново.',
      );
    } on PlatformException catch (e, stack) {
      AppLogger.error('ImageImport: gallery PlatformException', error: e, stackTrace: stack);
      return GalleryPickResult.failed(e.message ?? 'Ошибка при выборе из галереи');
    } catch (e, stack) {
      AppLogger.error('ImageImport: gallery unexpected', error: e, stackTrace: stack);
      return GalleryPickResult.failed('Ошибка доступа к галерее');
    }
  }

  /// Direct file pick via SAF — Downloads, Files, Documents (no media scanner).
  static Future<GalleryPickResult> pickFromFiles() async {
    try {
      AppLogger.debug('ImageImport: FilePicker started (image)');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: Platform.isAndroid,
        lockParentWindow: true,
      );

      if (result == null || result.files.isEmpty) {
        AppLogger.debug('ImageImport: FilePicker cancelled or empty');
        return GalleryPickResult.cancelled();
      }

      final file = result.files.single;
      AppLogger.debug(
        'ImageImport: FilePicker name=${file.name} path=${file.path} '
        'size=${file.size} bytes=${file.bytes?.length}',
      );

      final savedPath = await WardrobeImageStorage.persistFromPlatformFile(file);
      return _finalizePersist(
        savedPath,
        method: ImageImportMethod.files,
        sourceLabel: 'files',
      );
    } on MissingPluginException catch (e, stack) {
      AppLogger.error(
        'ImageImport: file_picker not registered',
        error: e,
        stackTrace: stack,
      );
      return GalleryPickResult.failed(
        'Плагин выбора файла не подключён. Выполните flutter run заново.',
      );
    } on PlatformException catch (e, stack) {
      AppLogger.error('ImageImport: FilePicker PlatformException', error: e, stackTrace: stack);
      return GalleryPickResult.failed(e.message ?? 'Ошибка при выборе файла');
    } catch (e, stack) {
      AppLogger.error('ImageImport: FilePicker unexpected', error: e, stackTrace: stack);
      return GalleryPickResult.failed('Не удалось открыть файловый выбор');
    }
  }

  /// Default entry: gallery ([ImageSource.gallery]).
  static Future<GalleryPickResult> pickAndPersist({
    ImagePicker? picker,
  }) =>
      pickFromGallery(picker: picker);

  static Future<GalleryPickResult> _finalizePersist(
    String? savedPath, {
    required ImageImportMethod method,
    required String sourceLabel,
  }) async {
    if (savedPath == null || savedPath.isEmpty) {
      AppLogger.error('ImageImport: persist failed ($sourceLabel)');
      return GalleryPickResult.failed(
        'Не удалось сохранить изображение. Попробуйте «Файл» → Downloads.',
      );
    }

    final validation = await ImageImportDiagnostics.validatePath(savedPath);
    if (!validation.isValid) {
      AppLogger.error(
        'ImageImport: validation failed ($sourceLabel): ${validation.message}',
      );
      return GalleryPickResult.failed(
        validation.message.isNotEmpty
            ? validation.message
            : 'Изображение повреждено или недоступно',
      );
    }

    AppLogger.info(
      'ImageImport: success method=$method path=$savedPath '
      'bytes=${validation.byteLength}',
    );
    return GalleryPickResult.success(savedPath, method: method);
  }

  static Future<bool> _ensureGalleryPermission() async {
    if (Platform.isAndroid) {
      return _ensureAndroidGalleryPermissionIfNeeded();
    }
    if (!Platform.isIOS) {
      return true;
    }
    return _ensureIosPhotosPermission();
  }

  static Future<bool> _ensureAndroidGalleryPermissionIfNeeded() async {
    try {
      var photos = await Permission.photos.status;
      if (photos.isGranted || photos.isLimited) return true;

      photos = await Permission.photos.request();
      if (photos.isGranted || photos.isLimited) return true;
      if (photos.isPermanentlyDenied) return false;

      var storage = await Permission.storage.status;
      if (storage.isGranted) return true;

      storage = await Permission.storage.request();
      if (storage.isGranted) return true;
      if (storage.isPermanentlyDenied) return false;

      return true;
    } on MissingPluginException catch (e, stack) {
      AppLogger.error(
        'ImageImport: permission_handler missing, continue with picker',
        error: e,
        stackTrace: stack,
      );
      return true;
    } catch (e, stack) {
      AppLogger.error('ImageImport: permission check failed', error: e, stackTrace: stack);
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

  static Future<void> openAppSettingsIfNeeded() async {
    try {
      await openAppSettings();
    } on MissingPluginException catch (e, stack) {
      AppLogger.error('ImageImport: openAppSettings failed', error: e, stackTrace: stack);
    }
  }
}
