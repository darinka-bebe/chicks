import 'package:flutter/material.dart';

/// Fixed outfit-card dimensions — stable row height, no flex overflow.
abstract final class OutfitPreviewMetrics {
  static const double cardRadius = 16;
  static const double imageRadius = 12;
  static const double imageInset = 6;

  static const double _minCardWidth = 116;
  static const double _maxCardWidth = 136;

  static const double imageHeight = 148;

  static const double bodyPaddingH = 9;
  static const double bodyPaddingTop = 7;
  static const double bodyPaddingBottom = 7;

  static const int titleMaxLines = 2;
  static const double titleBlockHeight = 28;

  static const double metaHeight = 11;
  static const double gapAfterTitle = 2;
  static const double gapBeforeChips = 3;

  static const double chipRowHeight = 18;
  static const double chipMaxWidth = 88;
  static const double chipRowMinHeight = 14;

  /// Extra room so font metrics never overflow the card on small screens.
  static const double layoutSlack = 6;

  /// Tighter line boxes — avoids ~2px ascent/descent overflow on some platforms.
  static const TextHeightBehavior compactTextHeight = TextHeightBehavior(
    applyHeightToFirstAscent: false,
    applyHeightToLastDescent: false,
  );

  static double get imageSectionHeight => imageInset + imageHeight;

  static double cardWidth(BuildContext context) {
    final bubbleMax = MediaQuery.sizeOf(context).width * 0.84;
    return (bubbleMax * 0.44).clamp(_minCardWidth, _maxCardWidth);
  }

  static double innerImageWidth(double cardWidth) =>
      cardWidth - imageInset * 2;

  /// Fixed inner body slots (padding + title + meta + chips).
  static double get bodyContentHeight =>
      bodyPaddingTop +
      titleBlockHeight +
      gapAfterTitle +
      metaHeight +
      gapBeforeChips +
      chipRowHeight +
      bodyPaddingBottom;

  static double cardHeight(BuildContext context, double cardWidth) =>
      imageSectionHeight + bodyContentHeight + layoutSlack;

  /// Matches [ChatMessageBubble] AI text/header horizontal padding.
  static const double chatBubbleHorizontalPadding = 18;

  /// Extra inset so first/last cards sit fully inside the rounded bubble.
  static const double rowEdgeInset = 6;

  /// Gap between outfit cards in the horizontal list.
  static const double rowCardGap = 12;

  static double rowSpacing() => rowCardGap;

  /// [ListView] horizontal padding from the bubble edge (content pad + inset).
  static const double rowScrollPaddingHorizontal =
      chatBubbleHorizontalPadding + rowEdgeInset;
}
