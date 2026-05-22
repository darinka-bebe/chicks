import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/models/wardrobe_item.dart';
import '../theme/app_brand_colors.dart';

/// Shows a wardrobe photo from assets or local file; falls back to category icon.
class WardrobeItemImage extends StatelessWidget {
  const WardrobeItemImage({
    super.key,
    required this.item,
    this.fit = BoxFit.cover,
    this.iconSize = 48,
  });

  final WardrobeItem item;
  final BoxFit fit;
  final double iconSize;

  static bool isAssetPath(String? path) {
    final trimmed = path?.trim() ?? '';
    return trimmed.startsWith('assets/');
  }

  @override
  Widget build(BuildContext context) {
    final path = item.imagePath?.trim() ?? '';
    if (path.isEmpty) {
      return _placeholder();
    }

    if (isAssetPath(path)) {
      return Image.asset(
        path,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    return Image.file(
      File(path),
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(
        item.placeholderIcon,
        size: iconSize,
        color: AppBrandColors.pink.withValues(alpha: 0.85),
      ),
    );
  }
}
