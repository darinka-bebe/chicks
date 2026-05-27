import 'package:flutter/material.dart';

import '../../../core/constants/wardrobe_catalog.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../data/wardrobe_filter.dart';

class WardrobeFilterBar extends StatelessWidget {
  const WardrobeFilterBar({
    super.key,
    required this.criteria,
    required this.availableColors,
    required this.availableStyles,
    required this.onCriteriaChanged,
    required this.onClearAll,
  });

  final WardrobeFilterCriteria criteria;
  final Set<String> availableColors;
  final Set<String> availableStyles;
  final ValueChanged<WardrobeFilterCriteria> onCriteriaChanged;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _FilterChip(
                label: 'Избранное',
                icon: Icons.favorite_rounded,
                selected: criteria.favoritesOnly,
                onTap: () => onCriteriaChanged(
                  criteria.copyWith(favoritesOnly: !criteria.favoritesOnly),
                ),
              ),
              const SizedBox(width: 8),
              _DropdownChip(
                label: 'Категория',
                value: criteria.category,
                options: WardrobeCatalog.categories,
                onSelected: (value) => onCriteriaChanged(
                  criteria.copyWith(
                    category: value,
                    clearCategory: value == null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _DropdownChip(
                label: 'Сезон',
                value: criteria.season,
                options: WardrobeCatalog.seasons,
                onSelected: (value) => onCriteriaChanged(
                  criteria.copyWith(
                    season: value,
                    clearSeason: value == null,
                  ),
                ),
              ),
              if (availableColors.isNotEmpty) ...[
                const SizedBox(width: 8),
                _DropdownChip(
                  label: 'Цвет',
                  value: criteria.color,
                  options: availableColors.toList(),
                  onSelected: (value) => onCriteriaChanged(
                    criteria.copyWith(
                      color: value,
                      clearColor: value == null,
                    ),
                  ),
                ),
              ],
              if (availableStyles.isNotEmpty) ...[
                const SizedBox(width: 8),
                _DropdownChip(
                  label: 'Стиль',
                  value: criteria.style,
                  options: availableStyles.toList(),
                  onSelected: (value) => onCriteriaChanged(
                    criteria.copyWith(
                      style: value,
                      clearStyle: value == null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (criteria.hasActiveFilters) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _activeTags(),
                  ),
                ),
                TextButton(
                  onPressed: onClearAll,
                  style: TextButton.styleFrom(
                    foregroundColor: AppBrandColors.pink,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'Сбросить',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _activeTags() {
    final tags = <Widget>[];
    if (criteria.favoritesOnly) {
      tags.add(_ActiveTag(label: 'Избранное'));
    }
    if (criteria.category != null && criteria.category!.isNotEmpty) {
      tags.add(_ActiveTag(label: criteria.category!));
    }
    if (criteria.season != null && criteria.season!.isNotEmpty) {
      tags.add(_ActiveTag(label: criteria.season!));
    }
    if (criteria.color != null && criteria.color!.isNotEmpty) {
      tags.add(_ActiveTag(label: criteria.color!));
    }
    if (criteria.style != null && criteria.style!.isNotEmpty) {
      tags.add(_ActiveTag(label: criteria.style!));
    }
    if (criteria.query.trim().isNotEmpty) {
      tags.add(_ActiveTag(label: '«${criteria.query.trim()}»'));
    }
    return tags;
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.0 : 0.98,
      duration: const Duration(milliseconds: 180),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? AppBrandColors.pink : Colors.grey[600],
              ),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? AppBrandColors.pink : AppBrandColors.title,
        ),
        selectedColor: AppBrandColors.iconBackground,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected
              ? AppBrandColors.pink
              : AppBrandColors.pink.withValues(alpha: 0.18),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _DropdownChip extends StatelessWidget {
  const _DropdownChip({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = value != null && value!.isNotEmpty;
    return PopupMenuButton<String?>(
      onSelected: onSelected,
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        PopupMenuItem<String?>(
          value: null,
          child: Text(
            'Все',
            style: TextStyle(
              color: selected ? Colors.grey[600] : AppBrandColors.pink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...options.map(
          (option) => PopupMenuItem<String?>(
            value: option,
            child: Text(
              option,
              style: TextStyle(
                fontWeight: value == option ? FontWeight.w700 : FontWeight.w500,
                color: value == option
                    ? AppBrandColors.pink
                    : AppBrandColors.title,
              ),
            ),
          ),
        ),
      ],
      child: _ChipShell(
        selected: selected,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected ? value! : label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppBrandColors.pink : AppBrandColors.title,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: selected ? AppBrandColors.pink : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipShell extends StatelessWidget {
  const _ChipShell({required this.selected, required this.child});

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppBrandColors.iconBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? AppBrandColors.pink
              : AppBrandColors.pink.withValues(alpha: 0.18),
        ),
      ),
      child: child,
    );
  }
}

class _ActiveTag extends StatelessWidget {
  const _ActiveTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppBrandColors.iconBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppBrandColors.pink,
        ),
      ),
    );
  }
}
