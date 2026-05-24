import 'package:flutter/material.dart';

import '../../../core/theme/app_brand_colors.dart';
import 'quiz_visual_theme.dart';

enum ContrastLevelVariant {
  low,
  medium,
  high;

  static ContrastLevelVariant? fromOptionId(String id) => switch (id) {
        'contrast_low' => ContrastLevelVariant.low,
        'contrast_medium' => ContrastLevelVariant.medium,
        'contrast_high' => ContrastLevelVariant.high,
        _ => null,
      };

  String get label => switch (this) {
        ContrastLevelVariant.low => 'low',
        ContrastLevelVariant.medium => 'medium',
        ContrastLevelVariant.high => 'high',
      };

  Color get rightHalfColor => switch (this) {
        ContrastLevelVariant.low => const Color(0xFFD8D8D8),
        ContrastLevelVariant.medium => const Color(0xFF9E9E9E),
        ContrastLevelVariant.high => const Color(0xFF1A1A1A),
      };
}

/// Split-circle contrast preview — matches the color quiz reference UI.
class ContrastLevelIllustration extends StatelessWidget {
  const ContrastLevelIllustration({
    super.key,
    required this.variant,
    this.size = QuizVisualTheme.optionPreviewSize,
    this.emphasized = false,
  });

  final ContrastLevelVariant variant;
  final double size;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: QuizVisualTheme.bodyPreviewDecoration(
          emphasized: emphasized,
          radius: QuizVisualTheme.previewRadius,
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(QuizVisualTheme.previewRadius - 2),
          child: ColoredBox(
            color: emphasized ? const Color(0xFFFFF0F7) : const Color(0xFFFFF8FB),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomPaint(
                  size: Size(size * 0.52, size * 0.52),
                  painter: _SplitCirclePainter(
                    rightColor: variant.rightHalfColor,
                    borderColor: emphasized
                        ? AppBrandColors.pink.withValues(alpha: 0.35)
                        : const Color(0xFFE8D0DC),
                  ),
                ),
                SizedBox(height: size * 0.06),
                Text(
                  variant.label,
                  style: TextStyle(
                    fontSize: size * 0.13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9A8A92),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplitCirclePainter extends CustomPainter {
  const _SplitCirclePainter({
    required this.rightColor,
    required this.borderColor,
  });

  final Color rightColor;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

  // Left half — white
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width / 2, size.height));
    canvas.drawCircle(center, radius - 0.6, Paint()..color = Colors.white);
    canvas.restore();

    // Right half — contrast tone
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
    );
    canvas.drawCircle(center, radius - 0.6, Paint()..color = rightColor);
    canvas.restore();

    // Vertical divider
    canvas.drawLine(
      Offset(size.width / 2, center.dy - radius + 1),
      Offset(size.width / 2, center.dy + radius - 1),
      Paint()
        ..color = borderColor
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _SplitCirclePainter oldDelegate) =>
      oldDelegate.rightColor != rightColor ||
      oldDelegate.borderColor != borderColor;
}
