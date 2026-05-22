import 'package:flutter/material.dart';

import '../../../core/theme/app_brand_colors.dart';

/// Shared layout + colors for all onboarding quiz visuals.
abstract final class QuizVisualTheme {
  static const Color panelFill = Color(0xFFFFF8FB);
  static const Color shapeFill = Color(0x66FF4FA0);
  static const Color outlineColor = Color(0xFF2D1A24);

  /// Option card chrome — separated from screen background (#FFF0F5).
  static const Color cardBorder = Color(0xFFF2D6E2);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color cardSurfaceSelected = Color(0xFFFFF5F9);

  static const double optionPreviewSize = 72;
  static const double resultPreviewSize = 112;

  static const double cardRadius = 20;
  static const double optionCardGap = 16;
  static const double bodyPreviewRadius = 12;
  static const double previewRadius = 16;

  static BoxDecoration optionCardDecoration({
    required bool selected,
  }) =>
      BoxDecoration(
        color: selected ? cardSurfaceSelected : cardSurface,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(
          color: selected ? AppBrandColors.pink : cardBorder,
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: selected
                ? AppBrandColors.pink.withValues(alpha: 0.2)
                : const Color(0xFF2D1A24).withValues(alpha: 0.07),
            blurRadius: selected ? 22 : 14,
            offset: Offset(0, selected ? 8 : 5),
            spreadRadius: selected ? 0 : -1,
          ),
          if (!selected)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.9),
              blurRadius: 0,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
        ],
      );

  /// Soft preview backdrop — no border (color swatches, icons).
  static BoxDecoration previewFillDecoration({bool emphasized = false}) =>
      BoxDecoration(
        color: emphasized ? const Color(0xFFFFF0F7) : panelFill,
        borderRadius: BorderRadius.circular(previewRadius),
      );

  /// Body-type photo slot — square, crisp 2px black frame.
  static BoxDecoration bodyPreviewDecoration({
    bool emphasized = false,
    double radius = bodyPreviewRadius,
  }) =>
      BoxDecoration(
        color: emphasized ? const Color(0xFFFFF0F7) : panelFill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: const Color(0xFF1A1A1A),
          width: 2,
        ),
      );
}
