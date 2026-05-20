import 'package:flutter/material.dart';

import '../../../core/services/gallery_image_picker_service.dart';
import '../../../core/services/profile_avatar_service.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../widgets/user_avatar.dart';

/// Editable circular profile avatar with gallery picker.
class ProfileEditableAvatar extends StatefulWidget {
  const ProfileEditableAvatar({
    super.key,
    required this.photoUrl,
    this.radius = 52,
  });

  final String photoUrl;
  final double radius;

  @override
  State<ProfileEditableAvatar> createState() => _ProfileEditableAvatarState();
}

class _ProfileEditableAvatarState extends State<ProfileEditableAvatar> {
  bool _isUpdating = false;

  Future<void> _changePhoto() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    try {
      final result = await ProfileAvatarService.pickFromGalleryAndSave();
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();

      if (result.isSuccess) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Фото профиля обновлено'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (result.status == ProfileAvatarUpdateStatus.cancelled) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Не удалось выбрать фото'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );

      if (result.status == ProfileAvatarUpdateStatus.permissionDenied) {
        await GalleryImagePickerService.openAppSettingsIfNeeded();
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final outerSize = widget.radius * 2 + 12;

    return Semantics(
      button: true,
      label: 'Изменить фото профиля',
      child: GestureDetector(
        onTap: _isUpdating ? null : _changePhoto,
        child: SizedBox(
          width: outerSize,
          height: outerSize,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppBrandColors.pink.withValues(alpha: 0.45),
                      AppBrandColors.pink.withValues(alpha: 0.18),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppBrandColors.pink.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: _isUpdating
                      ? SizedBox(
                          width: widget.radius * 2,
                          height: widget.radius * 2,
                          child: const ColoredBox(
                            color: AppBrandColors.iconBackground,
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppBrandColors.pink,
                                ),
                              ),
                            ),
                          ),
                        )
                      : UserAvatar(
                          photoUrl: widget.photoUrl,
                          radius: widget.radius,
                        ),
                ),
              ),
              Positioned(
                right: 4,
                bottom: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppBrandColors.pink,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(7),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
