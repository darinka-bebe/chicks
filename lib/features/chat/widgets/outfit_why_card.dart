import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../core/theme/app_brand_colors.dart';

/// Highlight card for «Почему этот образ подходит» bullets from AI reply.
class OutfitWhyCard extends StatelessWidget {
  const OutfitWhyCard({super.key, required this.bullets});

  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    if (bullets.isEmpty) return const SizedBox.shrink();

    final loc = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppBrandColors.pink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppBrandColors.pink.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 16,
                color: AppBrandColors.pink.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 6),
              Text(
                loc.whyOutfitFits,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppBrandColors.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final bullet in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppBrandColors.pink.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bullet,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
