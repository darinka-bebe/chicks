import 'package:flutter/material.dart';

import '../../../core/theme/app_brand_colors.dart';
import 'quiz_visual_theme.dart';

/// Unified onboarding quiz answer card — elevated, feminine, easy to scan.
class QuizOptionCard extends StatelessWidget {
  const QuizOptionCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.hint,
    this.leading,
  });

  final String label;
  final String? hint;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  static const double _leadingSlot = QuizVisualTheme.optionPreviewSize;
  static const double _radioSlot = 28;
  static const double _minCardHeight = 88;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(QuizVisualTheme.cardRadius),
        splashColor: AppBrandColors.pink.withValues(alpha: 0.12),
        highlightColor: AppBrandColors.pink.withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: _minCardHeight),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: QuizVisualTheme.optionCardDecoration(selected: selected),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                SizedBox(
                  width: _leadingSlot,
                  height: _leadingSlot,
                  child: leading,
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w700,
                        color: AppBrandColors.title,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (hint != null && hint!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        hint!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? AppBrandColors.pink.withValues(alpha: 0.72)
                              : const Color(0xFF8A7A82),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: _radioSlot,
                height: _radioSlot,
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: selected
                      ? AppBrandColors.pink
                      : const Color(0xFFD4B8C4),
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
