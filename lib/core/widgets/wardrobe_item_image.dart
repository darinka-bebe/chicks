import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/models/wardrobe_item.dart';
import '../theme/app_brand_colors.dart';
import '../utils/logger.dart';

/// Wardrobe photo: cloud URL, local file (pending upload), or bundled asset.
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

  @override
  Widget build(BuildContext context) {
    final url = item.displayImageUrl;
    if (url != null) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (_, __) => _loadingPlaceholder(),
        errorWidget: (_, __, error) {
          AppLogger.warning(
            'WardrobeItemImage: load failed item=${item.id} url=$url error=$error',
          );
          return _placeholder();
        },
      );
    }

    final asset = item.imagePath?.trim() ?? '';
    if (WardrobeItem.isAssetPath(asset)) {
      return Image.asset(
        asset,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (_, error, __) {
          AppLogger.warning(
            'WardrobeItemImage: asset failed item=${item.id} path=$asset',
          );
          return _placeholder();
        },
      );
    }

    final localPath = WardrobeItem.pendingLocalPath(item);
    if (localPath != null) {
      return Image.file(
        File(localPath),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (_, error, __) {
          AppLogger.warning(
            'WardrobeItemImage: local file failed item=${item.id} path=$localPath error=$error',
          );
          return _placeholder();
        },
      );
    }

    return _placeholder();
  }

  Widget _loadingPlaceholder() {
    return ColoredBox(
      color: AppBrandColors.iconBackground,
      child: Center(
        child: SizedBox(
          width: iconSize * 0.55,
          height: iconSize * 0.55,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppBrandColors.pink.withValues(alpha: 0.7),
          ),
        ),
      ),
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
