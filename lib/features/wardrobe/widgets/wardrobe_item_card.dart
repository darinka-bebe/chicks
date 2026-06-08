import 'package:flutter/material.dart';

import '../../../core/constants/wardrobe_catalog.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/widgets/wardrobe_item_image.dart';
import '../../../data/models/wardrobe_item.dart';

class WardrobeItemCard extends StatelessWidget {
  const WardrobeItemCard({
    super.key,
    required this.item,
    this.animationValue = 1,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final WardrobeItem item;
  final double animationValue;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  static String _subtitleLine(WardrobeItem item) {
    final parts = <String>[
      WardrobeCatalog.displayColor(item.color),
      WardrobeCatalog.displaySeason(item.season),
    ];
    if (item.styles.isNotEmpty) {
      parts.add(item.styles.first);
    } else if (item.vibes.isNotEmpty) {
      parts.add(WardrobeCatalog.displayVibe(item.vibes.first));
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final value = animationValue.clamp(0.0, 1.0);
    return Transform.scale(
      scale: 0.92 + (0.08 * value),
      child: Opacity(
        opacity: value,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isFavorite
                      ? AppBrandColors.pink.withValues(alpha: 0.22)
                      : Colors.transparent,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppBrandColors.pink.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                          decoration: BoxDecoration(
                            color: AppBrandColors.iconBackground,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: WardrobeItemImage(item: item),
                        ),
                        if (onFavoriteToggle != null)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Material(
                              color: Colors.white.withValues(alpha: 0.92),
                              shape: const CircleBorder(),
                              elevation: 2,
                              shadowColor:
                                  AppBrandColors.pink.withValues(alpha: 0.2),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: onFavoriteToggle,
                                child: Padding(
                                  padding: const EdgeInsets.all(7),
                                  child: Icon(
                                    isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 18,
                                    color: isFavorite
                                        ? AppBrandColors.pink
                                        : Colors.grey[500],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          WardrobeCatalog.displayItemTitle(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppBrandColors.title,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          WardrobeCatalog.displayCategory(item.category),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _subtitleLine(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
