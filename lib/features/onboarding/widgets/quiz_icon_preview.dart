import 'package:flutter/material.dart';

import '../../../core/theme/app_brand_colors.dart';
import 'quiz_visual_theme.dart';

/// Styled Material icon for quiz options (color contrast, fallback).
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
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: size * 0.42,
              color: AppBrandColors.pink,
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
