import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/repositories/auth_repository.dart'
    show AuthRepository, AuthException;
import '../utils/logger.dart';
import 'image_import_diagnostics.dart';
import 'profile_avatar_crop_service.dart';
import 'profile_avatar_picker_service.dart';
import 'profile_avatar_storage.dart';

enum ProfileAvatarUpdateStatus {
  success,
  cancelled,
  permissionDenied,
  failed,
}

class ProfileAvatarUpdateResult {
  const ProfileAvatarUpdateResult({
    required this.status,
    this.localPath,
    this.message,
  });

  final ProfileAvatarUpdateStatus status;
  final String? localPath;
  final String? message;

  bool get isSuccess => status == ProfileAvatarUpdateStatus.success;
}

/// Profile avatar — always persisted under app documents ([ProfileAvatarStorage]).
abstract final class ProfileAvatarService {
  /// Gallery → bottom-sheet crop → persist to profile.
  static Future<ProfileAvatarUpdateResult> pickFromGalleryAndSave({
    required BuildContext context,
  }) async {
    final auth = AuthRepository.instance;
    if (!auth.isLoggedIn) {
      return const ProfileAvatarUpdateResult(
        status: ProfileAvatarUpdateStatus.failed,
        message: 'Войдите в аккаунт, чтобы сохранить фото',
      );
    }

    final gallery = await ProfileAvatarPickerService.pickGalleryFile();
    if (gallery.status == ProfileAvatarPickStatus.cancelled) {
      return const ProfileAvatarUpdateResult(
        status: ProfileAvatarUpdateStatus.cancelled,
      );
    }
    if (gallery.status == ProfileAvatarPickStatus.permissionDenied) {
      return ProfileAvatarUpdateResult(
        status: ProfileAvatarUpdateStatus.permissionDenied,
        message: gallery.message,
      );
    }
    if (!gallery.isSuccess || gallery.localPath == null) {
      return ProfileAvatarUpdateResult(
        status: ProfileAvatarUpdateStatus.failed,
        message: gallery.message ?? 'Не удалось выбрать фото',
      );
    }

    if (!context.mounted) {
      return const ProfileAvatarUpdateResult(
        status: ProfileAvatarUpdateStatus.cancelled,
      );
    }

    final crop = await ProfileAvatarCropService.cropSquare(
      gallery.localPath!,
      context: context,
    );
    if (crop.cancelled || !crop.hasPath) {
      return const ProfileAvatarUpdateResult(
        status: ProfileAvatarUpdateStatus.cancelled,
      );
    }

    return commitPermanentPath(crop.path!);
  }

  /// Validates, persists to prefs, and prunes old avatar files.
  static Future<ProfileAvatarUpdateResult> commitPermanentPath(
    String candidatePath,
  ) async {
    final auth = AuthRepository.instance;
    if (!auth.isLoggedIn) {
      return const ProfileAvatarUpdateResult(
        status: ProfileAvatarUpdateStatus.failed,
        message: 'Войдите в аккаунт, чтобы сохранить фото',
      );
    }

    final uid = auth.currentUser.uid;
    String permanent = '';

    try {
      final file = File(candidatePath);
      if (await file.exists() && await file.length() > 0) {
        final bytes = await file.readAsBytes();
        permanent =
            await ProfileAvatarStorage.persistBytesForUser(uid, bytes) ?? '';
      }
    } catch (e, stack) {
      AppLogger.error(
        'ProfileAvatarService.commitPermanentPath read failed',
        error: e,
        stackTrace: stack,
      );
    }

    if (permanent.isEmpty) {
      permanent = await ProfileAvatarStorage.ensurePermanentAvatarPath(
        candidatePath,
        uid: uid,
      );
    }

    if (permanent.isEmpty ||
        (!ProfileAvatarStorage.isStoredAvatarPath(permanent) &&
            !permanent.toLowerCase().startsWith('http'))) {
      return const ProfileAvatarUpdateResult(
        status: ProfileAvatarUpdateStatus.failed,
        message: 'Не удалось сохранить фото профиля',
      );
    }

    final validation = await ImageImportDiagnostics.validatePath(permanent);
    if (!validation.isValid) {
      await ProfileAvatarStorage.deleteIfStored(permanent);
      return ProfileAvatarUpdateResult(
        status: ProfileAvatarUpdateStatus.failed,
        message: validation.message.isNotEmpty
            ? validation.message
            : 'Изображение повреждено или недоступно',
      );
    }

    final previousPath = auth.currentUser.photoUrl;
    try {
      await auth.updatePhotoPath(permanent);
    } on AuthException catch (e) {
      return ProfileAvatarUpdateResult(
        status: ProfileAvatarUpdateStatus.failed,
        message: e.message,
      );
    } catch (_) {
      return const ProfileAvatarUpdateResult(
        status: ProfileAvatarUpdateStatus.failed,
        message: 'Не удалось обновить профиль',
      );
    }

    if (ProfileAvatarStorage.isStoredAvatarPath(previousPath) &&
        previousPath != permanent) {
      await ProfileAvatarStorage.deleteIfStored(previousPath);
    }
    await ProfileAvatarStorage.pruneLegacyAvatars(
      uid: uid,
      keepPath: permanent,
    );

    return ProfileAvatarUpdateResult(
      status: ProfileAvatarUpdateStatus.success,
      localPath: permanent,
      message: 'Фото профиля обновлено',
    );
  }
}
