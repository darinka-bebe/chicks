import 'package:flutter/material.dart';

import '../../../core/models/body_shape_type.dart';
import 'quiz_visual_theme.dart';

/// Static fashion-style silhouette PNGs (exported design assets).
abstract final class BodyTypeIllustrationAssets {
  static const _base = 'assets/body_types';

  static const pear = '$_base/pear.png';
  static const rectangle = '$_base/rectangle.png';
  static const apple = '$_base/apple.png';
  static const hourglass = '$_base/hourglass.png';
  static const invertedTriangle = '$_base/inverted_triangle.png';

  static String forOptionId(String optionId) {
    return switch (optionId) {
      'shape_hourglass' => hourglass,
      'shape_pear' => pear,
      'shape_rectangle' => rectangle,
      'shape_apple' => apple,
      'shape_inverted' => invertedTriangle,
      'prop_narrow_shoulders' || 'prop_wide_hips' => pear,
      'prop_balanced' => hourglass,
      'prop_broad_shoulders' => invertedTriangle,
      'waist_defined' || 'fit_fitted' || 'height_average' => hourglass,
      'waist_soft' || 'fit_balanced' || 'height_petite' || 'height_tall' =>
        hourglass,
      'waist_straight' => rectangle,
      'fit_oversized' => apple,
      _ => rectangle,
    };
  }

  static String forBodyShape(BodyShapeType shape) {
    return switch (shape) {
      BodyShapeType.hourglass => hourglass,
      BodyShapeType.pear => pear,
      BodyShapeType.rectangle => rectangle,
      BodyShapeType.apple => apple,
      BodyShapeType.invertedTriangle => invertedTriangle,
    };
  }
}

/// Sharp static body illustration inside a square preview with a crisp frame.
class BodyTypeIllustration extends StatelessWidget {
  const BodyTypeIllustration({
    super.key,
    required this.assetPath,
    this.size = QuizVisualTheme.optionPreviewSize,
    this.emphasized = false,
  });

  BodyTypeIllustration.forOptionId(
    String optionId, {
    super.key,
    this.size = QuizVisualTheme.optionPreviewSize,
    this.emphasized = false,
  }) : assetPath = BodyTypeIllustrationAssets.forOptionId(optionId);

  BodyTypeIllustration.forBodyShape(
    BodyShapeType shape, {
    super.key,
    this.size = QuizVisualTheme.optionPreviewSize,
    this.emphasized = false,
  }) : assetPath = BodyTypeIllustrationAssets.forBodyShape(shape);

  final String assetPath;
  final double size;
  final bool emphasized;

  static double _snapSide(BuildContext context, double logical) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (logical * dpr).round() / dpr;
  }

  @override
  Widget build(BuildContext context) {
    final side = _snapSide(context, size);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (side * dpr).round().clamp(144, 640);
    const radius = QuizVisualTheme.bodyPreviewRadius;
    const borderWidth = 2.0;
    const innerRadius = radius - borderWidth;

    return SizedBox(
      width: side,
      height: side,
      child: DecoratedBox(
        decoration: QuizVisualTheme.bodyPreviewDecoration(
          emphasized: emphasized,
          radius: radius,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(innerRadius),
          child: Image.asset(
            assetPath,
            width: side,
            height: side,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            cacheWidth: cacheWidth,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey[400],
              size: side * 0.35,
            ),
          ),
        ),
      ),
    );
  }
}
