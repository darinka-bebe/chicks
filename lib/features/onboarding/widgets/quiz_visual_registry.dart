import 'package:flutter/material.dart';

import '../../../core/constants/seasonal_palette_catalog.dart';
import '../../../core/models/body_shape_type.dart';
import '../../../core/models/seasonal_color_type.dart';
import 'body_type_illustration.dart';
import 'color_type_illustration.dart';
import 'contrast_level_illustration.dart';
import 'quiz_color_preview.dart';
import 'quiz_icon_preview.dart';
import 'seasonal_palette_swatch.dart';
import 'quiz_visual_theme.dart';

/// Maps every quiz option id → consistent vector preview.
abstract final class QuizVisualRegistry {
  static Widget forBodyOption(
    String optionId, {
    bool emphasized = false,
    double size = QuizVisualTheme.optionPreviewSize,
  }) {
    if (_usesSilhouette(optionId)) {
      return BodyTypeIllustration.forOptionId(
        optionId,
        size: size,
        emphasized: emphasized,
      );
    }
    return QuizIconPreview(
      icon: _iconForBodyOption(optionId),
      size: size,
      emphasized: emphasized,
    );
  }

  static bool _usesSilhouette(String id) =>
      id.startsWith('shape_') || id.startsWith('prop_');

  static IconData _iconForBodyOption(String id) => switch (id) {
        'waist_defined' => Icons.hourglass_bottom_rounded,
        'waist_soft' => Icons.waves_rounded,
        'waist_straight' => Icons.horizontal_rule_rounded,
        'fit_fitted' => Icons.straighten_rounded,
        'fit_balanced' => Icons.checkroom_outlined,
        'fit_oversized' => Icons.air_rounded,
        'height_petite' => Icons.height_rounded,
        'height_average' => Icons.social_distance_rounded,
        'height_tall' => Icons.vertical_align_top_rounded,
        _ => Icons.help_outline_rounded,
      };

  static Widget forColorOption(
    String optionId, {
    bool emphasized = false,
    double size = QuizVisualTheme.optionPreviewSize,
  }) {
    final contrastVariant = ContrastLevelVariant.fromOptionId(optionId);
    if (contrastVariant != null) {
      return ContrastLevelIllustration(
        variant: contrastVariant,
        size: size,
        emphasized: emphasized,
      );
    }

    final assetPath = colorQuizAssetPath(optionId);
    if (assetPath != null) {
      return ColorTypeIllustration(
        assetPath: assetPath,
        size: size,
        emphasized: emphasized,
      );
    }

    final colors = _colorsForOption(optionId);
    if (colors != null) {
      return QuizColorPreview(
        colors: colors,
        secondaryColor: _secondaryForOption(optionId),
        size: size,
        emphasized: emphasized,
      );
    }

    return QuizIconPreview(
      icon: Icons.palette_outlined,
      size: size,
      emphasized: emphasized,
    );
  }

  static Widget forBodyResult(BodyShapeType shape, {double size = 112}) {
    return BodyTypeIllustration.forBodyShape(
      shape,
      size: size,
      emphasized: true,
    );
  }

  /// Premium palette block — only for the final color type result.
  static Widget forColorResult(SeasonalColorType type, {double size = 112}) {
    return SeasonalPaletteSwatch(
      colors: SeasonalPaletteCatalog.colorsFor(type.paletteId),
      size: size,
      emphasized: true,
    );
  }

  static List<Color>? _colorsForOption(String id) => switch (id) {
        'eye_light_blue' => const [Color(0xFF9EC5E8), Color(0xFFB8D4E8)],
        'eye_green_hazel' => const [Color(0xFF7FA882), Color(0xFF9BB59E)],
        'eye_warm_brown' => const [Color(0xFF8B5E3C), Color(0xFFA67B52)],
        'eye_dark_brown' => const [Color(0xFF3D2914), Color(0xFF5C4033)],
        'undertone_warm' => const [
            Color(0xFFE8B88A),
            Color(0xFFF0C9A0),
            Color(0xFFD4956A),
          ],
        'undertone_cool' => const [
            Color(0xFFE8C4D4),
            Color(0xFFD4E8F0),
            Color(0xFFF0E8F5),
          ],
        'undertone_neutral' => const [
            Color(0xFFD4C4B8),
            Color(0xFFE8DDD4),
            Color(0xFFC8B8A8),
          ],
        'depth_light' => const [Color(0xFFF5E6D8), Color(0xFFE8D4C4)],
        'depth_medium' => const [Color(0xFFC49A7A), Color(0xFFD4A88A)],
        'depth_deep' => const [Color(0xFF6B4428), Color(0xFF8B5A3C)],
        _ => null,
      };

  static Color? _secondaryForOption(String id) => switch (id) {
        'undertone_warm' => const Color(0xFFFFE4C4),
        'undertone_cool' => const Color(0xFFE8F0FF),
        _ => null,
      };
}
