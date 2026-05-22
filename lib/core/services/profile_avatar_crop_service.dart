import 'dart:io';

import 'package:flutter/material.dart';

import '../../features/profile/widgets/profile_avatar_crop_screen.dart';
import '../utils/logger.dart';

/// Result of avatar crop attempt.
class ProfileAvatarCropResult {
  const ProfileAvatarCropResult({
    required this.path,
    this.cancelled = false,
    this.usedOriginalWithoutCropUi = false,
  });

  const ProfileAvatarCropResult.cancelled()
      : path = null,
        cancelled = true,
        usedOriginalWithoutCropUi = false;

  final String? path;
  final bool cancelled;
  final bool usedOriginalWithoutCropUi;

  bool get hasPath => path != null && path!.isNotEmpty;
}

/// Square crop UI for profile avatar (bottom sheet, Flutter-only).
abstract final class ProfileAvatarCropService {
  /// Opens a bottom-sheet crop editor over [context].
  static Future<ProfileAvatarCropResult> cropSquare(
    String sourcePath, {
    required BuildContext context,
  }) async {
    final trimmed = sourcePath.trim();
    if (trimmed.isEmpty) {
      return const ProfileAvatarCropResult.cancelled();
    }

    if (!context.mounted) {
      return const ProfileAvatarCropResult.cancelled();
    }

    try {
      final croppedPath = await showModalBottomSheet<String?>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black54,
        builder: (_) => ProfileAvatarCropSheet(sourcePath: trimmed),
      );

      if (croppedPath == null || croppedPath.trim().isEmpty) {
        return const ProfileAvatarCropResult.cancelled();
      }

      final path = croppedPath.trim();
      final file = File(path);
      if (!await file.exists() || await file.length() == 0) {
        AppLogger.warning('ProfileAvatarCrop: empty crop result');
        return const ProfileAvatarCropResult.cancelled();
      }

      AppLogger.info('ProfileAvatarCrop: cropped $path');
      return ProfileAvatarCropResult(path: path);
    } catch (e, stack) {
      AppLogger.error(
        'ProfileAvatarCrop.cropSquare failed',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
