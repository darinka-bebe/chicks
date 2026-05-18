import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_brand_colors.dart';
import '../../../data/models/outfit_history_entry.dart';
import '../../../data/models/wardrobe_item.dart';
import 'outfit_history_item_thumbnails.dart';

class OutfitHistoryCard extends StatelessWidget {
  const OutfitHistoryCard({
    super.key,
    required this.entry,
    required this.wardrobeItems,
    required this.onTap,
  });

  final OutfitHistoryEntry entry;
  final List<WardrobeItem> wardrobeItems;
  final VoidCallback onTap;

  String get _excerpt {
    final plain = entry.aiResponseText
        .replaceAll(RegExp(r'[#*>`\[\]]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (plain.length <= 100) return plain;
    return '${plain.substring(0, 97)}…';
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        DateFormat('d MMM yyyy, HH:mm').format(entry.createdAt);

    return RepaintBoundary(
      child: Material(
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
                    recommendedItemIds: entry.recommendedItemIds,
                    wardrobeItems: wardrobeItems,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppBrandColors.title,
                            height: 1.25,
                          ),
                        ),
                        if (entry.weatherLabel != null &&
                            entry.weatherLabel!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            entry.weatherLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        if (entry.hasContext) ...[
                          const SizedBox(height: 8),
                          _TagWrap(tags: entry.styleTags),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          _excerpt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          dateLabel,
                          style: TextStyle(
                            fontSize: 11,
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
      ),
    );
  }
}

class _TagWrap extends StatelessWidget {
  const _TagWrap({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final visible = tags.take(4).toList();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: visible.map((tag) => _TagChip(tag)).toList(),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppBrandColors.iconBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppBrandColors.pink,
        ),
      ),
    );
  }
}
