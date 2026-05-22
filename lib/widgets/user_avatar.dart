import 'dart:io';

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/services/profile_avatar_storage.dart';
import '../core/theme/app_brand_colors.dart';

enum _AvatarDisplay { placeholder, loading, network, file }

/// Circular avatar — [BoxFit.cover], centered; invalid paths show placeholder.
class UserAvatar extends StatefulWidget {
  const UserAvatar({
    super.key,
    required this.photoUrl,
    this.radius = AppConstants.avatarRadius,
    this.userId,
    this.avatarRevision = 0,
  });

  final String photoUrl;
  final double radius;

  /// When set, resolves canonical avatar file under app documents.
  final String? userId;

  /// Increment when the file at [photoUrl] was overwritten (same path).
  final int avatarRevision;

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  _AvatarDisplay _display = _AvatarDisplay.placeholder;
  String? _networkUrl;
  File? _localFile;
  int _fileVersion = 0;

  @override
  void initState() {
    super.initState();
    _resolveSource();
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl ||
        oldWidget.userId != widget.userId ||
        oldWidget.avatarRevision != widget.avatarRevision) {
      _fileVersion++;
      _resolveSource();
    }
  }

  Future<void> _resolveSource() async {
    final trimmed = widget.photoUrl.trim();
    if (trimmed.isEmpty) {
      _setPlaceholder();
      return;
    }

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      if (!mounted) return;
      setState(() {
        _display = _AvatarDisplay.network;
        _networkUrl = trimmed;
        _localFile = null;
      });
      return;
    }

    if (!mounted) return;
    setState(() => _display = _AvatarDisplay.loading);

    final resolved = await ProfileAvatarStorage.resolveValidLocalPath(
      trimmed,
      uid: widget.userId,
    );

    if (!mounted) return;

    if (resolved.isEmpty) {
      _setPlaceholder();
      return;
    }

    if (resolved.toLowerCase().startsWith('http')) {
      setState(() {
        _display = _AvatarDisplay.network;
        _networkUrl = resolved;
        _localFile = null;
      });
      return;
    }

    final file = File(resolved);
    if (await file.exists() && await file.length() > 0) {
      setState(() {
        _display = _AvatarDisplay.file;
        _localFile = file;
        _networkUrl = null;
      });
    } else {
      _setPlaceholder();
    }
  }

  void _setPlaceholder() {
    if (!mounted) return;
    setState(() {
      _display = _AvatarDisplay.placeholder;
      _networkUrl = null;
      _localFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final diameter = widget.radius * 2;

    return SizedBox(
      width: diameter,
      height: diameter,
      child: ClipOval(
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: _buildContent(diameter),
        ),
      ),
    );
  }

  Widget _buildContent(double size) {
    switch (_display) {
      case _AvatarDisplay.loading:
        return _placeholder(size, showSpinner: true);
      case _AvatarDisplay.network:
        return Image.network(
          _networkUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => _placeholder(size),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _placeholder(size, showSpinner: true);
          },
        );
      case _AvatarDisplay.file:
        return Image.file(
          _localFile!,
          key: ValueKey('${_localFile!.path}_$_fileVersion'),
          width: size,
          height: size,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          gaplessPlayback: false,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => _placeholder(size),
        );
      case _AvatarDisplay.placeholder:
        return _placeholder(size);
    }
  }

  Widget _placeholder(double size, {bool showSpinner = false}) {
    return ColoredBox(
      color: AppBrandColors.iconBackground,
      child: Center(
        child: showSpinner
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppBrandColors.pink,
                ),
              )
            : Icon(
                Icons.person_rounded,
                size: size * 0.48,
                color: AppBrandColors.pink.withValues(alpha: 0.5),
              ),
      ),
    );
  }
}
