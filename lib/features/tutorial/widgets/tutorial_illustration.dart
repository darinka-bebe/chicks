import 'package:flutter/material.dart';

import '../../../core/theme/app_brand_colors.dart';
import '../data/tutorial_pages.dart';

class TutorialIllustration extends StatelessWidget {
  const TutorialIllustration({
    super.key,
    required this.data,
    required this.pageIndex,
  });

  final TutorialPageData data;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    final gradient = data.gradientColors ??
        [
          AppBrandColors.iconBackground,
          AppBrandColors.background,
        ];

    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(pageIndex),
      tween: Tween(begin: 0.88, end: 1),
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: AppBrandColors.pink.withValues(alpha: 0.12),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 12,
              right: 20,
              child: Icon(
                Icons.circle,
                size: 10,
                color: AppBrandColors.pink.withValues(alpha: 0.2),
              ),
            ),
            Positioned(
              bottom: 18,
              left: 24,
              child: Icon(
                Icons.circle,
                size: 6,
                color: AppBrandColors.pink.withValues(alpha: 0.15),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.72),
                    boxShadow: [
                      BoxShadow(
                        color: AppBrandColors.pink.withValues(alpha: 0.1),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        data.icon,
                        size: 52,
                        color: AppBrandColors.pink,
                      ),
                      Positioned(
                        right: 22,
                        bottom: 26,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppBrandColors.pink.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            data.accentIcon,
                            size: 18,
                            color: AppBrandColors.pink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
