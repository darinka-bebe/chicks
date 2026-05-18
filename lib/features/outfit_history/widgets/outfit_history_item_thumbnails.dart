import 'package:flutter/material.dart';

import '../../../core/services/wardrobe_recommendation_resolver.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../data/models/wardrobe_item.dart';
import '../../chat/widgets/chat_wardrobe_thumbnail.dart';

/// Compact wardrobe preview strip for history list cards.
class OutfitHistoryItemThumbnails extends StatelessWidget {
  const OutfitHistoryItemThumbnails({
    super.key,
    required this.recommendedItemIds,
    required this.wardrobeItems,
    this.height = 72,
    this.maxVisible = 3,
  });

  final List<String> recommendedItemIds;
  final List<WardrobeItem> wardrobeItems;
  final double height;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final items = WardrobeRecommendationResolver.resolveItems(
      requestedIds: recommendedItemIds,
      wardrobe: wardrobeItems,
    );

    if (items.isEmpty) {
      return _PlaceholderStrip(height: height);
    }

    final visible = items.take(maxVisible).toList();
    const thumbWidth = 56.0;
    const overlap = 10.0;
    final stripWidth =
        thumbWidth + (visible.length - 1) * (thumbWidth - overlap);

    return SizedBox(
      height: height,
      width: stripWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * (thumbWidth - overlap),
              child: _ThumbFrame(
                child: ChatWardrobeThumbnail(
                  item: visible[i],
                  width: thumbWidth,
                  height: height - 4,
                  cacheWidth: 120,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThumbFrame extends StatelessWidget {
  const _ThumbFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: child,
      ),
    );
  }
}

class _PlaceholderStrip extends StatelessWidget {
  const _PlaceholderStrip({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppBrandColors.iconBackground,
            AppBrandColors.pink.withValues(alpha: 0.15),
          ],
        ),
      ),
      child: const Icon(
        Icons.checkroom_rounded,
        color: AppBrandColors.pink,
        size: 28,
      ),
    );
  }
}
