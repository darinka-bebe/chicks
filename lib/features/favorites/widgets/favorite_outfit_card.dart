import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_brand_colors.dart';
import '../../../data/models/favorite_outfit.dart';

class FavoriteOutfitCard extends StatelessWidget {
  const FavoriteOutfitCard({
    super.key,
    required this.outfit,
    required this.onTap,
  });

  final FavoriteOutfit outfit;
  final VoidCallback onTap;

  String get _excerpt {
    final plain = outfit.recommendation
        .replaceAll(RegExp(r'[#*>`\[\]]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (plain.length <= 120) return plain;
    return '${plain.substring(0, 117)}…';
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM yyyy').format(outfit.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppBrandColors.iconBackground,
                      AppBrandColors.pink.withValues(alpha: 0.22),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      right: 16,
                      top: 14,
                      child: Icon(
                        Icons.favorite_rounded,
                        color: AppBrandColors.pink,
                        size: 22,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 48, 12),
                      child: Text(
                        outfit.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppBrandColors.title,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (outfit.hasContext) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...outfit.moods.map((tag) => _TagChip(tag)),
                          ...outfit.occasions.map((tag) => _TagChip(tag)),
                          ...outfit.weather.map((tag) => _TagChip(tag)),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      _excerpt,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppBrandColors.iconBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppBrandColors.pink,
        ),
      ),
    );
  }
}
