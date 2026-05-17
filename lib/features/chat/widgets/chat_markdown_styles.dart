import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/theme/app_brand_colors.dart';

/// Markdown styling for AI stylist bubbles (Chicks pink theme).
abstract final class ChatMarkdownStyles {
  static MarkdownStyleSheet? _cachedSheet;
  static Brightness? _cachedBrightness;

  /// Reuses [MarkdownStyleSheet] per theme brightness (avoids rebuild cost).
  static MarkdownStyleSheet cachedAiBubble(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (_cachedSheet != null && _cachedBrightness == brightness) {
      return _cachedSheet!;
    }
    _cachedBrightness = brightness;
    _cachedSheet = aiBubble(context);
    return _cachedSheet!;
  }

  static MarkdownStyleSheet aiBubble(BuildContext context) {
    const base = TextStyle(
      fontSize: 15,
      height: 1.5,
      color: AppBrandColors.title,
      letterSpacing: 0.1,
    );

    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: base,
      pPadding: const EdgeInsets.only(bottom: 10),
      h1: base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppBrandColors.pink,
        height: 1.35,
      ),
      h1Padding: const EdgeInsets.only(top: 4, bottom: 8),
      h2: base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppBrandColors.pink,
        height: 1.35,
      ),
      h2Padding: const EdgeInsets.only(top: 6, bottom: 6),
      h3: base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppBrandColors.pink,
        height: 1.35,
      ),
      h3Padding: const EdgeInsets.only(top: 8, bottom: 4),
      strong: base.copyWith(fontWeight: FontWeight.w700),
      em: base.copyWith(fontStyle: FontStyle.italic),
      listBullet: base.copyWith(
        color: AppBrandColors.pink,
        fontWeight: FontWeight.w700,
      ),
      listIndent: 22,
      listBulletPadding: const EdgeInsets.only(right: 6),
      blockSpacing: 12,
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppBrandColors.pink.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      blockquote: base.copyWith(
        color: AppBrandColors.title.withValues(alpha: 0.85),
      ),
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      blockquoteDecoration: BoxDecoration(
        color: AppBrandColors.iconBackground,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppBrandColors.pink, width: 3),
        ),
      ),
      code: base.copyWith(
        fontSize: 13,
        backgroundColor: AppBrandColors.iconBackground,
      ),
    );
  }
}
