import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/models/wardrobe_item.dart';
import '../theme/app_brand_colors.dart';
import '../utils/logger.dart';

/// Shows a wardrobe photo from cloud URL, assets or local file.
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

  static bool looksLikeRemoteUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  static bool looksLikeForeignLocalPath(String path) {
    if (path.isEmpty || isAssetPath(path) || looksLikeRemoteUrl(path)) {
      return false;
    }
    if (Platform.isAndroid && path.contains('/data/user/')) return false;
    if (Platform.isIOS && path.contains('/Containers/Data/Application/')) {
      return false;
    }
    return path.contains('/') &&
        (path.contains('wardrobe_images') ||
            path.contains('/data/') ||
            path.contains('/Containers/'));
  }

  @override
  Widget build(BuildContext context) {
    final url = item.imageUrl?.trim() ?? '';
    if (url.isNotEmpty && looksLikeRemoteUrl(url)) {
      return Image.network(
        url,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (_, error, __) {
          AppLogger.warning(
            'WardrobeItemImage: network load failed item=${item.id} '
            'url=$url error=$error',
          );
          return _buildLocalFallback();
        },
      );
    }

    return _buildLocalFallback();
  }

  Widget _buildLocalFallback() {
    final path = item.imagePath?.trim() ?? '';
    if (path.isEmpty) {
      AppLogger.debug(
        'WardrobeItemImage: no image item=${item.id} title="${item.title}"',
      );
      return _placeholder();
    }

    if (looksLikeRemoteUrl(path)) {
      return Image.network(
        path,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (_, error, __) {
          AppLogger.warning(
            'WardrobeItemImage: legacy url in imagePath failed '
            'item=${item.id} url=$path error=$error',
          );
          return _placeholder();
        },
      );
    }

    if (isAssetPath(path)) {
      return Image.asset(
        path,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (_, error, __) {
          AppLogger.warning(
            'WardrobeItemImage: asset load failed item=${item.id} '
            'path=$path error=$error',
          );
          return _placeholder();
        },
      );
    }

    final file = File(path);
    if (!file.existsSync()) {
      AppLogger.warning(
        'WardrobeItemImage: local file missing item=${item.id} path=$path '
        'imageUrl=${item.imageUrl ?? "(none)"}',
      );
      return _placeholder();
    }

    return Image.file(
      file,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      errorBuilder: (_, error, __) {
        AppLogger.warning(
          'WardrobeItemImage: file load failed item=${item.id} '
          'path=$path error=$error',
        );
        return _placeholder();
      },
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
