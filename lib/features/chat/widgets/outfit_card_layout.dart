import 'package:flutter/material.dart';

import 'outfit_preview_metrics.dart';

/// Precomputed fixed dimensions for one outfit row.
class OutfitCardLayout {
  const OutfitCardLayout({
    required this.cardWidth,
    required this.cardHeight,
    required this.innerImageWidth,
    required this.imageHeight,
    required this.bodyMinHeight,
    required this.textContentWidth,
  });

  final double cardWidth;
  final double cardHeight;
  final double innerImageWidth;
  final double imageHeight;
  final double bodyMinHeight;
  final double textContentWidth;

  factory OutfitCardLayout.of(BuildContext context) {
    final width = OutfitPreviewMetrics.cardWidth(context);
    return OutfitCardLayout(
      cardWidth: width,
      cardHeight: OutfitPreviewMetrics.cardHeight(context, width),
      innerImageWidth: OutfitPreviewMetrics.innerImageWidth(width),
      imageHeight: OutfitPreviewMetrics.imageHeight,
      bodyMinHeight: OutfitPreviewMetrics.bodyContentHeight,
      textContentWidth: width - OutfitPreviewMetrics.bodyPaddingH * 2,
    );
  }
}
