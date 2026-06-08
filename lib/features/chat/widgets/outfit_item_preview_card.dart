import 'package:flutter/material.dart';

import '../../../core/constants/wardrobe_catalog.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../data/models/wardrobe_item.dart';
import 'chat_wardrobe_thumbnail.dart';
import 'outfit_card_layout.dart';
import 'outfit_item_tags.dart';
import 'outfit_preview_metrics.dart';
import 'outfit_style_chip.dart';

/// Polished Pinterest-style wardrobe card with fixed layout slots.
class OutfitItemPreviewCard extends StatelessWidget {
  const OutfitItemPreviewCard({
    super.key,
    required this.item,
    required this.layout,
    this.onTap,
  });

  final WardrobeItem item;
  final OutfitCardLayout layout;
  final VoidCallback? onTap;

  static const TextStyle _titleStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.12,
    color: AppBrandColors.title,
    letterSpacing: -0.1,
  );

  static final TextStyle _metaStyle = TextStyle(
    fontSize: 9.5,
    height: 1.12,
    fontWeight: FontWeight.w500,
    color: Colors.grey[600],
  );

  @override
  Widget build(BuildContext context) {
    final tags = OutfitItemTags.aestheticLabels(item);
    final metaLine = _metaLine(item);

    return MediaQuery.withNoTextScaling(
      child: SizedBox(
        width: layout.cardWidth,
        height: layout.cardHeight,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(OutfitPreviewMetrics.cardRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: AppBrandColors.pink.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                    child: ChatWardrobeThumbnail(
                      item: item,
                      width: layout.innerImageWidth,
                      height: layout.imageHeight,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        OutfitPreviewMetrics.bodyPaddingH,
                        OutfitPreviewMetrics.bodyPaddingTop,
                        OutfitPreviewMetrics.bodyPaddingH,
                        OutfitPreviewMetrics.bodyPaddingBottom,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final gaps = OutfitPreviewMetrics.gapAfterTitle +
                              OutfitPreviewMetrics.gapBeforeChips;
                          final chipHeight = (constraints.maxHeight -
                                  OutfitPreviewMetrics.titleBlockHeight -
                                  OutfitPreviewMetrics.metaHeight -
                                  gaps)
                              .clamp(0.0, OutfitPreviewMetrics.chipRowHeight);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: OutfitPreviewMetrics.titleBlockHeight,
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    WardrobeCatalog.displayItemTitle(item),
                                    maxLines: OutfitPreviewMetrics.titleMaxLines,
                                    overflow: TextOverflow.ellipsis,
                                    textHeightBehavior:
                                        OutfitPreviewMetrics.compactTextHeight,
                                    style: _titleStyle,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: OutfitPreviewMetrics.gapAfterTitle,
                              ),
                              SizedBox(
                                height: OutfitPreviewMetrics.metaHeight,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    metaLine.isEmpty ? '\u00A0' : metaLine,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textHeightBehavior:
                                        OutfitPreviewMetrics.compactTextHeight,
                                    style: _metaStyle,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: OutfitPreviewMetrics.gapBeforeChips,
                              ),
                              SizedBox(
                                height: chipHeight,
                                width: layout.textContentWidth,
                                child: _TagStrip(
                                  tags: tags,
                                  height: chipHeight,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
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

  static String _metaLine(WardrobeItem item) {
    final parts = <String>[];
    if (item.category.trim().isNotEmpty) {
      parts.add(WardrobeCatalog.displayCategory(item.category));
    }
    if (item.color.trim().isNotEmpty) {
      parts.add(WardrobeCatalog.displayColor(item.color));
    }
    return parts.join(' · ');
  }
}

class _TagStrip extends StatelessWidget {
  const _TagStrip({
    required this.tags,
    required this.height,
  });

  final List<String> tags;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return SizedBox(height: height);
    }

    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(
          children: [
            for (var i = 0; i < tags.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              OutfitStyleChip(label: tags[i]),
            ],
          ],
        ),
      ),
    );
  }
}
