import 'gallery_image_picker_service.dart';
import 'image_import_diagnostics.dart';
import 'profile_avatar_storage.dart';
import 'wardrobe_image_storage.dart';
import '../../data/repositories/auth_repository.dart' show AuthRepository, AuthException;

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

/// Picks a gallery photo and persists it as the user's profile avatar.
abstract final class ProfileAvatarService {
  static Future<ProfileAvatarUpdateResult> pickFromGalleryAndSave() async {
    final pick = await GalleryImagePickerService.pickFromGallery();
    if (!pick.isSuccess || pick.localPath == null) {
      return ProfileAvatarUpdateResult(
        status: switch (pick.status) {
          GalleryPickStatus.cancelled => ProfileAvatarUpdateStatus.cancelled,
          GalleryPickStatus.permissionDenied =>
            ProfileAvatarUpdateStatus.permissionDenied,
          _ => ProfileAvatarUpdateStatus.failed,
        },
        message: pick.message,
      );
    }

    return saveFromPickedPath(pick.localPath!);
  }

  static Future<ProfileAvatarUpdateResult> saveFromPickedPath(
    String pickedPath,
  ) async {
    final avatarPath = await ProfileAvatarStorage.persistFromPath(pickedPath);
    if (avatarPath == null || avatarPath.isEmpty) {
      return const ProfileAvatarUpdateResult(
        status: ProfileAvatarUpdateStatus.failed,
        message: 'Не удалось сохранить фото профиля',
      );
    }

    final validation = await ImageImportDiagnostics.validatePath(avatarPath);
    if (!validation.isValid) {
      await ProfileAvatarStorage.deleteIfStored(avatarPath);
      return ProfileAvatarUpdateResult(
        status: ProfileAvatarUpdateStatus.failed,
        message: validation.message.isNotEmpty
            ? validation.message
            : 'Изображение повреждено или недоступно',
      );
    }

    final auth = AuthRepository.instance;
    if (!auth.isLoggedIn) {
      await ProfileAvatarStorage.deleteIfStored(avatarPath);
      return const ProfileAvatarUpdateResult(
        status: ProfileAvatarUpdateStatus.failed,
        message: 'Войдите в аккаунт, чтобы сохранить фото',
      );
    }

    final previousPath = auth.currentUser.photoUrl;
    try {
      await auth.updatePhotoPath(avatarPath);
    } catch (e) {
      await ProfileAvatarStorage.deleteIfStored(avatarPath);
      return const ProfileAvatarUpdateResult(
        status: ProfileAvatarUpdateStatus.failed,
        message: 'Не удалось обновить профиль',
      );
    }

    if (ProfileAvatarStorage.isStoredAvatarPath(previousPath)) {
      await ProfileAvatarStorage.deleteIfStored(previousPath);
    }
    await WardrobeImageStorage.deleteIfStored(pickedPath);

    return ProfileAvatarUpdateResult(
      status: ProfileAvatarUpdateStatus.success,
      localPath: avatarPath,
      message: 'Фото профиля обновлено',
    );
  }
}
