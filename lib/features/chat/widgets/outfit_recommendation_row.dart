import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/services/wardrobe_recommendation_resolver.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/widgets/chicks_skeleton.dart';
import '../../../data/models/wardrobe_item.dart';
import 'outfit_card_layout.dart';
import 'outfit_item_preview_card.dart';
import 'outfit_preview_metrics.dart';
import 'wardrobe_snapshot_scope.dart';

/// Horizontal outfit strip with uniform card sizing.
class OutfitRecommendationRow extends StatelessWidget {
  const OutfitRecommendationRow({
    super.key,
    required this.recommendedItemIds,
  });

  final List<String> recommendedItemIds;

  static const EdgeInsets _headerPadding = EdgeInsets.symmetric(
    horizontal: OutfitPreviewMetrics.chatBubbleHorizontalPadding,
  );

  @override
  Widget build(BuildContext context) {
    if (recommendedItemIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final snapshot = WardrobeSnapshotScope.maybeOf(context);
    if (snapshot == null) {
      return const _OutfitRowSkeleton();
    }

    final items = WardrobeRecommendationResolver.resolveItems(
      requestedIds: recommendedItemIds,
      wardrobe: snapshot.items,
    );

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final layout = OutfitCardLayout.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: _headerPadding,
            child: _OutfitRowHeader(),
          ),
          const SizedBox(height: 8),
          _OutfitCardScroller(
            layout: layout,
            items: items,
            onCardTap: (item) => _openDetails(context, item),
          ),
        ],
      ),
    );
  }

  void _openDetails(BuildContext context, WardrobeItem item) {
    context.pushNamed(
      RouteNames.wardrobeItemDetailsName,
      extra: item,
    );
  }
}

class _OutfitRowHeader extends StatelessWidget {
  const _OutfitRowHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(
            color: AppBrandColors.pink,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          'Вещи из образа',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppBrandColors.title.withValues(alpha: 0.7),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

/// Horizontal list spanning the full AI bubble width with safe edge insets.
class _OutfitCardScroller extends StatelessWidget {
  const _OutfitCardScroller({
    required this.layout,
    required this.items,
    required this.onCardTap,
  });

  final OutfitCardLayout layout;
  final List<WardrobeItem> items;
  final void Function(WardrobeItem item) onCardTap;

  static const ScrollPhysics _scrollPhysics = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: layout.cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: OutfitPreviewMetrics.rowScrollPaddingHorizontal,
        ),
        physics: _scrollPhysics,
        clipBehavior: Clip.hardEdge,
        primary: false,
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: OutfitPreviewMetrics.rowCardGap),
        itemBuilder: (context, index) {
          final item = items[index];
          return OutfitItemPreviewCard(
            key: ValueKey<String>(item.id),
            item: item,
            layout: layout,
            onTap: () => onCardTap(item),
          );
        },
      ),
    );
  }
}

class _OutfitRowSkeleton extends StatelessWidget {
  const _OutfitRowSkeleton();

  static const EdgeInsets _headerPadding = EdgeInsets.symmetric(
    horizontal: OutfitPreviewMetrics.chatBubbleHorizontalPadding,
  );

  @override
  Widget build(BuildContext context) {
    final layout = OutfitCardLayout.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: _headerPadding,
            child: const ChicksSkeleton(width: 100, height: 11, borderRadius: 4),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: layout.cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: OutfitPreviewMetrics.rowScrollPaddingHorizontal,
              ),
              physics: const NeverScrollableScrollPhysics(),
              clipBehavior: Clip.hardEdge,
              primary: false,
              itemCount: 2,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: OutfitPreviewMetrics.rowCardGap),
              itemBuilder: (_, __) => _CardSkeleton(layout: layout),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.layout});

  final OutfitCardLayout layout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: layout.cardWidth,
      height: layout.cardHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(OutfitPreviewMetrics.cardRadius),
          border: Border.all(
            color: AppBrandColors.pink.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                OutfitPreviewMetrics.imageInset,
                OutfitPreviewMetrics.imageInset,
                OutfitPreviewMetrics.imageInset,
                0,
              ),
              child: ChicksSkeleton(
                width: layout.innerImageWidth,
                height: layout.imageHeight,
                borderRadius: OutfitPreviewMetrics.imageRadius,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
