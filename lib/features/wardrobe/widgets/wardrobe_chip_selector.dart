import 'package:flutter/material.dart';

import '../../../core/theme/app_brand_colors.dart';

/// Selectable metadata chips (single or multi).
class WardrobeChipSelector extends StatelessWidget {
  const WardrobeChipSelector({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.allowMultiple = true,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final List<String> options;
  final List<String> selected;
  final bool allowMultiple;
  final ValueChanged<List<String>> onChanged;

  void _onTap(String value) {
    if (allowMultiple) {
      final next = List<String>.from(selected);
      if (next.contains(value)) {
        next.remove(value);
      } else {
        next.add(value);
      }
      onChanged(next);
    } else {
      if (selected.contains(value)) {
        onChanged([]);
      } else {
        onChanged([value]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppBrandColors.title,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Wrap(
            key: ValueKey(selected.join(',')),
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selected.contains(option);
              return AnimatedScale(
                scale: isSelected ? 1.0 : 0.98,
                duration: const Duration(milliseconds: 150),
                child: FilterChip(
                  label: Text(option),
                  selected: isSelected,
                  showCheckmark: false,
                  onSelected: (_) => _onTap(option),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppBrandColors.pink : AppBrandColors.title,
                  ),
                  selectedColor: AppBrandColors.iconBackground,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? AppBrandColors.pink
                        : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Read-only chip row for details screen.
class WardrobeMetadataChips extends StatelessWidget {
  const WardrobeMetadataChips({
    super.key,
    required this.values,
  });

  final List<String> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return Text(
        '—',
        style: TextStyle(color: Colors.grey[500], fontSize: 14),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values
          .map(
            (value) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppBrandColors.iconBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppBrandColors.pink,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
