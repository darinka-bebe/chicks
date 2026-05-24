import 'package:flutter/material.dart';

import 'quiz_visual_theme.dart';

/// Color / tone swatches for the seasonal color quiz.
class QuizColorPreview extends StatelessWidget {
  const QuizColorPreview({
    super.key,
    required this.colors,
    this.size = QuizVisualTheme.optionPreviewSize,
    this.emphasized = false,
    this.secondaryColor,
  });

  final List<Color> colors;
  final Color? secondaryColor;
  final double size;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final useCompactPalette = colors.length >= 3 && size <= 96;

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: QuizVisualTheme.previewFillDecoration(
          emphasized: emphasized,
        ),
        child: Padding(
          padding: EdgeInsets.all(useCompactPalette ? 8 : 10),
          child: useCompactPalette
              ? _CompactPaletteStripes(colors: colors)
              : colors.length == 1
                  ? _SwatchCircle(color: colors.first)
                  : Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              for (final c in colors)
                                Expanded(child: _SwatchCircle(color: c)),
                            ],
                          ),
                        ),
                        if (secondaryColor != null) ...[
                          const SizedBox(height: 6),
                          _SwatchBar(color: secondaryColor!),
                        ],
                      ],
                    ),
        ),
      ),
    );
  }
}

class _CompactPaletteStripes extends StatelessWidget {
  const _CompactPaletteStripes({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          for (final color in colors.take(3))
            Expanded(
              child: ColoredBox(color: color),
            ),
        ],
      ),
    );
  }
}

class _SwatchCircle extends StatelessWidget {
  const _SwatchCircle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwatchBar extends StatelessWidget {
  const _SwatchBar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
