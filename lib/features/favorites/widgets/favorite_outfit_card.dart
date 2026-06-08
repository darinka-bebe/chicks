import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/stylist_suggestion_chips.dart';
import '../../../core/localization/outfit_display.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../data/models/favorite_outfit.dart';
import '../../../data/models/wardrobe_item.dart';
import '../../outfit_history/widgets/outfit_history_item_thumbnails.dart';

class FavoriteOutfitCard extends StatelessWidget {
  const FavoriteOutfitCard({
    super.key,
    required this.outfit,
    required this.wardrobeItems,
    required this.onTap,
  });

  final FavoriteOutfit outfit;
  final List<WardrobeItem> wardrobeItems;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final dateLabel =
        DateFormat('d MMM yyyy', locale).format(outfit.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutfitHistoryItemThumbnails(
                  recommendedItemIds: outfit.recommendedItemIds,
                  wardrobeItems: wardrobeItems,
                  height: 88,
                  maxVisible: 3,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              OutfitDisplay.favoriteTitle(outfit),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppBrandColors.title,
                                height: 1.25,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.favorite_rounded,
                            color: AppBrandColors.pink,
                            size: 20,
                          ),
                        ],
                      ),
                      if (outfit.hasContext) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ...outfit.moods.map(
                              (tag) => _TagChip(
                                StylistContextCatalog.displayMood(tag),
                              ),
                            ),
                            ...outfit.occasions.map(
                              (tag) => _TagChip(
                                StylistContextCatalog.displayOccasion(tag),
                              ),
                            ),
                            ...outfit.weather.map(
                              (tag) => _TagChip(
                                StylistContextCatalog.displayWeather(tag),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        OutfitDisplay.favoriteExcerpt(outfit),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        dateLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppBrandColors.iconBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppBrandColors.pink,
        ),
      ),
    );
  }
}
