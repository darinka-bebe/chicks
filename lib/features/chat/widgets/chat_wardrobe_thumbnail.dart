import 'package:flutter/material.dart';

import '../../../core/services/wardrobe_chat_image_cache.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../data/models/wardrobe_item.dart';
import 'outfit_preview_metrics.dart';

/// Wardrobe photo tile — top-centered crop, rounded, cached decode.
class ChatWardrobeThumbnail extends StatelessWidget {
  const ChatWardrobeThumbnail({
    super.key,
    required this.item,
    required this.width,
    required this.height,
    this.cacheWidth = WardrobeChatImageCache.defaultCacheWidth,
  });

  final WardrobeItem item;
  final double width;
  final double height;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    final imagePath = item.imagePath;
    final hasImage = imagePath != null && imagePath.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(OutfitPreviewMetrics.imageRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: hasImage
            ? Image(
                image: WardrobeChatImageCache.fileProvider(
                  imagePath,
                  cacheWidth: cacheWidth,
                ),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                width: width,
                height: height,
                filterQuality: FilterQuality.low,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => _Placeholder(item: item),
              )
            : _Placeholder(item: item),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.item});

  final WardrobeItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppBrandColors.iconBackground,
            AppBrandColors.pink.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          item.placeholderIcon,
          size: 28,
          color: AppBrandColors.pink.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}
