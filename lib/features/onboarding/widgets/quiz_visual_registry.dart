import 'package:flutter/material.dart';

import '../../../core/models/body_shape_type.dart';
import '../../../core/models/seasonal_color_type.dart';
import 'body_type_illustration.dart';
import 'color_type_illustration.dart';
import 'quiz_color_preview.dart';
import 'quiz_icon_preview.dart';
import 'quiz_visual_theme.dart';

/// Maps every quiz option id → consistent vector preview.
abstract final class QuizVisualRegistry {
  static Widget forBodyOption(
    String optionId, {
    bool emphasized = false,
    double size = QuizVisualTheme.optionPreviewSize,
  }) {
    final asset = BodyTypeIllustrationAssets.forOptionId(optionId);
    if (_isBodyOption(optionId)) {
      return BodyTypeIllustration(
        assetPath: asset,
        size: size,
        emphasized: emphasized,
      );
    }
    return QuizIconPreview(
      icon: Icons.help_outline_rounded,
      size: size,
      emphasized: emphasized,
    );
  }

  static Widget forColorOption(
    String optionId, {
    bool emphasized = false,
    double size = QuizVisualTheme.optionPreviewSize,
  }) {
    final asset = ColorTypeIllustrationAssets.forOptionId(optionId);
    if (asset != null) {
      return ColorTypeIllustration(
        assetPath: asset,
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

  static bool _isBodyOption(String id) =>
      id.startsWith('shape_') ||
      id.startsWith('prop_') ||
      id.startsWith('waist_') ||
      id.startsWith('fit_') ||
      id.startsWith('height_');

  static Widget forColorResult(SeasonalColorType type, {double size = 112}) {
    return QuizColorPreview(
      colors: _paletteForSeason(type),
      size: size,
      emphasized: true,
    );
  }

  static List<Color>? _colorsForOption(String id) => switch (id) {
        'eye_light_blue' => const [Color(0xFF9EC5E8), Color(0xFFB8D4E8)],
        'eye_green_hazel' => const [Color(0xFF7FA882), Color(0xFF9BB59E)],
        'eye_warm_brown' => const [Color(0xFF8B5E3C), Color(0xFFA67B52)],
        'eye_dark_brown' => const [Color(0xFF3D2914), Color(0xFF5C4033)],
        'hair_light_blonde' => const [Color(0xFFE8D4A8), Color(0xFFF5E6C8)],
        'hair_golden' => const [Color(0xFFC8860A), Color(0xFFE8A84A)],
        'hair_cool_brown' => const [Color(0xFF6B5344), Color(0xFF8B7355)],
        'hair_dark' => const [Color(0xFF2A2018), Color(0xFF4A3C32)],
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
        'contrast_low' => const [
            Color(0xFFE8E0D8),
            Color(0xFFD8D0C8),
            Color(0xFFC8C0B8),
          ],
        'contrast_medium' => const [
            Color(0xFF8B7355),
            Color(0xFFF5F0E8),
            Color(0xFF3D2914),
          ],
        'contrast_high' => const [
            Color(0xFF1A1A1A),
            Color(0xFFF5F5F5),
            Color(0xFF6B4428),
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

  static List<Color> _paletteForSeason(SeasonalColorType type) =>
      switch (type) {
        SeasonalColorType.lightSpring => const [
            Color(0xFFFFB6C8),
            Color(0xFF98D8C8),
            Color(0xFFFFF0A8),
          ],
        SeasonalColorType.warmAutumn => const [
            Color(0xFFC8860A),
            Color(0xFF8B5A2B),
            Color(0xFF6B8F3A),
          ],
        SeasonalColorType.softSummer => const [
            Color(0xFFB8C5E8),
            Color(0xFFE8C4D8),
            Color(0xFFD4E8F0),
          ],
        SeasonalColorType.coolWinter => const [
            Color(0xFF4169E1),
            Color(0xFF9370DB),
            Color(0xFF2F4F4F),
          ],
      };
}
