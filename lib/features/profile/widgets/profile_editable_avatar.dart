import 'package:flutter/material.dart';

import '../../../core/services/gallery_image_picker_service.dart';
import '../../../core/services/profile_avatar_crop_service.dart';
import '../../../core/services/profile_avatar_picker_service.dart';
import '../../../core/services/profile_avatar_service.dart';
import '../../../core/services/profile_avatar_storage.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../widgets/user_avatar.dart';

/// Editable circular profile avatar with gallery picker.
class ProfileEditableAvatar extends StatefulWidget {
  const ProfileEditableAvatar({
    super.key,
    required this.photoUrl,
    this.userId,
    this.avatarRevision = 0,
    this.radius = 52,
    this.onPhotoUpdated,
  });

  final String photoUrl;
  final String? userId;
  final int avatarRevision;
  final double radius;
  final ValueChanged<String>? onPhotoUpdated;

  @override
  State<ProfileEditableAvatar> createState() => _ProfileEditableAvatarState();
}

class _ProfileEditableAvatarState extends State<ProfileEditableAvatar> {
  bool _isUpdating = false;
  String? _previewPath;

  String get _effectivePhotoUrl => _previewPath ?? widget.photoUrl;

  Future<void> _changePhoto() async {
    if (_isUpdating) return;

    final loc = AppLocalizations.of(context);
    final gallery = await ProfileAvatarPickerService.pickGalleryFile();
    if (!mounted) return;

    if (gallery.status == ProfileAvatarPickStatus.cancelled) {
      return;
    }
    if (gallery.status == ProfileAvatarPickStatus.permissionDenied) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              gallery.message ?? loc.profileAvatarPermissionDenied,
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      await GalleryImagePickerService.openAppSettingsIfNeeded();
      return;
    }
    if (!gallery.isSuccess || gallery.localPath == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(gallery.message ?? loc.profileAvatarPickFailed),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      return;
    }

    final crop = await ProfileAvatarCropService.cropSquare(
      gallery.localPath!,
      context: context,
    );
    if (!mounted) return;
    if (crop.cancelled || !crop.hasPath) {
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final result =
          await ProfileAvatarService.commitPermanentPath(crop.path!);
      if (!mounted) return;

      if (result.isSuccess &&
          result.localPath != null &&
          ProfileAvatarStorage.isStoredAvatarPath(result.localPath)) {
        setState(() => _previewPath = result.localPath);
        widget.onPhotoUpdated?.call(result.localPath!);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(result.message ?? loc.profileAvatarUpdated),
              behavior: SnackBarBehavior.floating,
            ),
          );
        return;
      }

      if (result.status == ProfileAvatarUpdateStatus.cancelled) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(result.message ?? loc.profileAvatarSaveFailed),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  void didUpdateWidget(ProfileEditableAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl &&
        widget.photoUrl.isNotEmpty &&
        widget.photoUrl == _previewPath) {
      setState(() => _previewPath = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final innerSize = widget.radius * 2;
    final outerSize = innerSize + 12;

    final loc = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: loc.profileAvatarChangeLabel,
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
                width: innerSize,
                height: innerSize,
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
                child: ClipOval(
                  child: SizedBox(
                    width: innerSize - 8,
                    height: innerSize - 8,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        UserAvatar(
                          key: ValueKey(
                            '${_effectivePhotoUrl}_${widget.avatarRevision}',
                          ),
                          photoUrl: _effectivePhotoUrl,
                          userId: widget.userId,
                          avatarRevision: widget.avatarRevision,
                          radius: widget.radius,
                        ),
                        if (_isUpdating)
                          ColoredBox(
                            color: Colors.white.withValues(alpha: 0.72),
                            child: const Center(
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
                      ],
                    ),
                  ),
                ),
              ),
              if (!_isUpdating)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppBrandColors.pink,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
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
