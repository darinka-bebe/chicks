import 'package:flutter/material.dart';

import '../../../core/theme/app_brand_colors.dart';
import 'outfit_preview_metrics.dart';

/// Compact aesthetic tag — intrinsic width, single line.
class OutfitStyleChip extends StatelessWidget {
  const OutfitStyleChip({
    super.key,
    required this.label,
    this.maxWidth = OutfitPreviewMetrics.chipMaxWidth,
  });

  final String label;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        decoration: BoxDecoration(
          color: AppBrandColors.pink.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            height: 1.1,
            color: AppBrandColors.pink.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}
