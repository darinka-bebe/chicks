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
  static const double _radioSlot = 32;

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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: QuizVisualTheme.optionCardDecoration(selected: selected),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null)
                SizedBox(
                  width: _leadingSlot,
                  height: _leadingSlot,
                  child: Center(child: leading),
                ),
              if (leading != null) const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w700,
                        color: AppBrandColors.title,
                        height: 1.25,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (hint != null && hint!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        hint!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? AppBrandColors.pink.withValues(alpha: 0.72)
                              : const Color(0xFF8A7A82),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: _radioSlot,
                height: _radioSlot,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      key: ValueKey(selected),
                      color: selected
                          ? AppBrandColors.pink
                          : const Color(0xFFD4B8C4),
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
