import 'dart:io';

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_brand_colors.dart';

enum _AvatarDisplay { placeholder, loading, network, file }

/// Circular avatar with [BoxFit.cover] — preserves aspect ratio, no stretch.
class UserAvatar extends StatefulWidget {
  const UserAvatar({
    super.key,
    required this.photoUrl,
    this.radius = AppConstants.avatarRadius,
  });

  final String photoUrl;
  final double radius;

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  _AvatarDisplay _display = _AvatarDisplay.placeholder;
  String? _networkUrl;
  File? _localFile;

  @override
  void initState() {
    super.initState();
    _resolveSource();
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl) {
      _resolveSource();
    }
  }

  Future<void> _resolveSource() async {
    final trimmed = widget.photoUrl.trim();
    if (trimmed.isEmpty) {
      if (!mounted) return;
      setState(() {
        _display = _AvatarDisplay.placeholder;
        _networkUrl = null;
        _localFile = null;
      });
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

    final file = File(trimmed);
    final exists = await file.exists();
    final hasBytes = exists && await file.length() > 0;

    if (!mounted) return;
    setState(() {
      if (hasBytes) {
        _display = _AvatarDisplay.file;
        _localFile = file;
        _networkUrl = null;
      } else {
        _display = _AvatarDisplay.placeholder;
        _localFile = null;
        _networkUrl = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.radius * 2;

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: ColoredBox(
          color: AppBrandColors.iconBackground,
          child: _buildContent(size),
        ),
      ),
    );
  }

  Widget _buildContent(double size) {
    switch (_display) {
      case _AvatarDisplay.loading:
        return Center(
          child: SizedBox(
            width: size * 0.35,
            height: size * 0.35,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: AppBrandColors.pink,
            ),
          ),
        );
      case _AvatarDisplay.network:
        return Image.network(
          _networkUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _placeholder(size),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _placeholder(size);
          },
        );
      case _AvatarDisplay.file:
        return Image.file(
          _localFile!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _placeholder(size),
        );
      case _AvatarDisplay.placeholder:
        return _placeholder(size);
    }
  }

  Widget _placeholder(double size) {
    return Center(
      child: Icon(
        Icons.person_rounded,
        size: size * 0.52,
        color: AppBrandColors.pink.withValues(alpha: 0.5),
      ),
    );
  }
}
