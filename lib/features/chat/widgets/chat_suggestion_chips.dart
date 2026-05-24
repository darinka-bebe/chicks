import 'package:flutter/material.dart';

import '../../../core/constants/stylist_suggestion_chips.dart';
import '../../../core/theme/app_brand_colors.dart';

/// Horizontal quick-pick chips for mood, weather, and occasion prompts.
class ChatSuggestionChips extends StatelessWidget {
  const ChatSuggestionChips({
    super.key,
    required this.enabled,
    required this.onChipTap,
  });

  final bool enabled;
  final ValueChanged<StylistSuggestionChip> onChipTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        primary: false,
        itemCount: StylistContextCatalog.suggestionChips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = StylistContextCatalog.suggestionChips[index];
          return FilterChip(
            label: Text(
              chip.displayLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: enabled ? AppBrandColors.title : Colors.grey,
              ),
            ),
            selected: false,
            onSelected: enabled ? (_) => onChipTap(chip) : null,
            showCheckmark: false,
            backgroundColor: AppBrandColors.iconBackground,
            side: BorderSide(
              color: enabled
                  ? AppBrandColors.pink.withValues(alpha: 0.35)
                  : Colors.grey.shade300,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
    );
  }
}
