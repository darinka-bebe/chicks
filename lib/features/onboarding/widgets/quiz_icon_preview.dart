import 'package:flutter/material.dart';

import '../../../core/theme/app_brand_colors.dart';
import 'quiz_visual_theme.dart';

/// Styled Material icon for quiz options with soft geometric backdrop.
class QuizIconPreview extends StatelessWidget {
  const QuizIconPreview({
    super.key,
    required this.icon,
    this.size = QuizVisualTheme.optionPreviewSize,
    this.emphasized = false,
    this.badge,
  });

  final IconData icon;
  final double size;
  final bool emphasized;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: QuizVisualTheme.previewFillDecoration(
          emphasized: emphasized,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              top: size * 0.1,
              right: size * 0.08,
              child: _GeoCircle(
                diameter: size * 0.28,
                color: AppBrandColors.pink.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              bottom: size * 0.12,
              left: size * 0.06,
              child: _GeoCircle(
                diameter: size * 0.2,
                color: AppBrandColors.pink.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              top: size * 0.22,
              left: size * 0.1,
              child: Transform.rotate(
                angle: 0.35,
                child: _GeoBar(
                  width: size * 0.14,
                  height: size * 0.34,
                  color: AppBrandColors.pink.withValues(alpha: 0.07),
                ),
              ),
            ),
            Icon(
              icon,
              size: size * 0.4,
              color: emphasized
                  ? AppBrandColors.pink
                  : AppBrandColors.pink.withValues(alpha: 0.88),
            ),
            if (badge != null)
              Positioned(
                bottom: 8,
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: size * 0.11,
                    fontWeight: FontWeight.w800,
                    color: QuizVisualTheme.outlineColor.withValues(alpha: 0.45),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GeoCircle extends StatelessWidget {
  const _GeoCircle({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _GeoBar extends StatelessWidget {
  const _GeoBar({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(width),
      ),
    );
  }
}
