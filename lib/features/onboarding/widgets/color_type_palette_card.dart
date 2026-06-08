import 'package:flutter/material.dart';

import '../../../core/constants/seasonal_palette_catalog.dart';
import '../../../core/models/seasonal_color_type.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'seasonal_palette_swatch.dart';

/// Profile / list card for a seasonal color type (reference-style layout).
class ColorTypePaletteCard extends StatelessWidget {
  const ColorTypePaletteCard({
    super.key,
    required this.paletteId,
    this.title,
    this.description,
    this.trailing,
    this.compact = false,
    this.emphasized = false,
    this.onTap,
    this.swatchSize,
  });

  ColorTypePaletteCard.fromColorType({
    super.key,
    required SeasonalColorType type,
    this.trailing,
    this.compact = false,
    this.emphasized = false,
    this.onTap,
    this.swatchSize,
  })  : paletteId = type.paletteId,
        title = type.displayName,
        description = type.shortDescription;

  final SeasonalPaletteId paletteId;
  final String? title;
  final String? description;
  final Widget? trailing;
  final bool compact;
  final bool emphasized;
  final VoidCallback? onTap;
  final double? swatchSize;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final resolvedSwatchSize = swatchSize ?? (compact ? 72.0 : 80.0);
    final resolvedTitle = title ?? paletteId.displayName;
    final resolvedDescription = description ?? paletteId.shortDescription;

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SeasonalPaletteSwatch(
          colors: SeasonalPaletteCatalog.colorsFor(paletteId),
          size: resolvedSwatchSize,
          emphasized: emphasized,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.profileColorType,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppBrandColors.pink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                resolvedTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppBrandColors.title,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                resolvedDescription,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );
  }
}
