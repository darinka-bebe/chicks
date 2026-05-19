import 'package:flutter/material.dart';

import '../../../core/models/body_shape_type.dart';

/// Static reference illustrations for body-type UI (from design assets).
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

/// Displays a cropped reference body-type illustration asset.
class BodyTypeIllustration extends StatelessWidget {
  const BodyTypeIllustration({
    super.key,
    required this.assetPath,
    this.width = 84,
    this.height = 118,
    this.emphasized = false,
  });

  BodyTypeIllustration.forOptionId(
    String optionId, {
    super.key,
    this.width = 84,
    this.height = 118,
    this.emphasized = false,
  }) : assetPath = BodyTypeIllustrationAssets.forOptionId(optionId);

  BodyTypeIllustration.forBodyShape(
    BodyShapeType shape, {
    super.key,
    this.width = 84,
    this.height = 118,
    this.emphasized = false,
  }) : assetPath = BodyTypeIllustrationAssets.forBodyShape(shape);

  final String assetPath;
  final double width;
  final double height;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: emphasized ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        width: width,
        height: height,
        child: Image.asset(
          assetPath,
          width: width,
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: const Color(0xFFFFF0F7),
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey[400],
              size: width * 0.35,
            ),
          ),
        ),
      ),
    );
  }
}
