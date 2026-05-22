import 'package:flutter/material.dart';

import 'quiz_visual_theme.dart';

/// PNG previews for the seasonal color quiz (separate from body-type assets).
abstract final class ColorTypeIllustrationAssets {
  static const _base = 'assets/color_quiz';

  static String? forOptionId(String optionId) {
    const ids = {
      'eye_light_blue',
      'eye_green_hazel',
      'eye_warm_brown',
      'eye_dark_brown',
      'hair_light_blonde',
      'hair_golden',
      'hair_cool_brown',
      'hair_dark',
      'undertone_warm',
      'undertone_cool',
      'undertone_neutral',
      'contrast_low',
      'contrast_medium',
      'contrast_high',
      'depth_light',
      'depth_medium',
      'depth_deep',
    };
    if (!ids.contains(optionId)) return null;
    return '$_base/$optionId.png';
  }
}

/// Illustration tile for color-quiz answer cards.
class ColorTypeIllustration extends StatelessWidget {
  const ColorTypeIllustration({
    super.key,
    required this.assetPath,
    this.size = QuizVisualTheme.optionPreviewSize,
    this.emphasized = false,
  });

  ColorTypeIllustration.forOptionId(
    String optionId, {
    super.key,
    this.size = QuizVisualTheme.optionPreviewSize,
    this.emphasized = false,
  }) : assetPath = ColorTypeIllustrationAssets.forOptionId(optionId) ?? '';

  final String assetPath;
  final double size;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    if (assetPath.isEmpty) {
      return SizedBox(width: size, height: size);
    }

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: QuizVisualTheme.bodyPreviewDecoration(
          emphasized: emphasized,
          radius: QuizVisualTheme.previewRadius,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(QuizVisualTheme.previewRadius - 2),
          child: Image.asset(
            assetPath,
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey[400],
              size: size * 0.35,
            ),
          ),
        ),
      ),
    );
  }
}
