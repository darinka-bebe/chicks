import 'package:flutter/material.dart';

import '../../../core/models/wardrobe_analysis_snapshot.dart';
import '../../../core/models/wardrobe_outfit_slot.dart';
import '../../../core/theme/app_brand_colors.dart';

/// Horizontal category counts for wardrobe insights.
class WardrobeStatsStrip extends StatelessWidget {
  const WardrobeStatsStrip({super.key, required this.snapshot});

  final WardrobeAnalysisSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final chips = <_StatChipData>[
      _StatChipData(
        label: 'Верх',
        count: snapshot.countFor(WardrobeOutfitSlot.top) +
            snapshot.countFor(WardrobeOutfitSlot.dress),
      ),
      _StatChipData(
        label: 'Низ',
        count: snapshot.countFor(WardrobeOutfitSlot.bottom),
      ),
      _StatChipData(
        label: 'Обувь',
        count: snapshot.countFor(WardrobeOutfitSlot.shoes),
      ),
      _StatChipData(
        label: 'Верх. одежда',
        count: snapshot.countFor(WardrobeOutfitSlot.outerwear),
      ),
      _StatChipData(
        label: 'Аксессуары',
        count: snapshot.countFor(WardrobeOutfitSlot.accessory),
      ),
    ];

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final chip = chips[index];
          final isLow = snapshot.totalItems >= 4 && chip.count == 0;
          return _StatChip(data: chip, highlightGap: isLow);
        },
      ),
    );
  }
}

class _StatChipData {
  const _StatChipData({required this.label, required this.count});

  final String label;
  final int count;
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.data,
    required this.highlightGap,
  });

  final _StatChipData data;
  final bool highlightGap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlightGap
              ? AppBrandColors.pink.withValues(alpha: 0.45)
              : AppBrandColors.pink.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${data.count}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: highlightGap ? AppBrandColors.pink : AppBrandColors.title,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
