import 'package:flutter/material.dart';

import '../../../core/theme/app_brand_colors.dart';

/// Premium palette block: vertical swatches + accent dots (beauty-app style).
class SeasonalPaletteSwatch extends StatelessWidget {
  const SeasonalPaletteSwatch({
    super.key,
    required this.colors,
    this.size = 72,
    this.emphasized = false,
  });

  final List<Color> colors;
  final double size;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final palette = colors.take(5).toList();
    while (palette.length < 5) {
      palette.add(palette.isNotEmpty ? palette.last : AppBrandColors.iconBackground);
    }

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F8),
          borderRadius: BorderRadius.circular(size * 0.18),
          border: Border.all(
            color: emphasized
                ? AppBrandColors.pink.withValues(alpha: 0.35)
                : AppBrandColors.pink.withValues(alpha: 0.12),
            width: emphasized ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppBrandColors.pink.withValues(alpha: emphasized ? 0.14 : 0.08),
              blurRadius: emphasized ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.12),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < 5; i++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: i == 0 ? 0 : size * 0.018,
                            right: i == 4 ? 0 : size * 0.018,
                          ),
                          child: _VerticalSwatch(color: palette[i]),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: size * 0.06),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final color in palette)
                    _AccentDot(color: color, size: size * 0.07),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerticalSwatch extends StatelessWidget {
  const _VerticalSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _AccentDot extends StatelessWidget {
  const _AccentDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
