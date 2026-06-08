import 'package:flutter/material.dart';

import '../../../core/theme/app_brand_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class WardrobeSearchBar extends StatelessWidget {
  const WardrobeSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: value.text.isNotEmpty
                  ? AppBrandColors.pink.withValues(alpha: 0.35)
                  : AppBrandColors.pink.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: AppBrandColors.pink.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: loc.wardrobeSearchHint,
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppBrandColors.pink.withValues(alpha: 0.85),
              ),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                        onClear?.call();
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 14,
              ),
            ),
          ),
        );
      },
    );
  }
}
