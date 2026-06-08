import '../../data/models/wardrobe_item.dart';
import '../models/wardrobe_outfit_slot.dart';

/// Compact wardrobe statistics for analysis and low-token AI prompts.
class WardrobeAnalysisSnapshot {
  const WardrobeAnalysisSnapshot({
    required this.totalItems,
    required this.slotCounts,
    required this.colorCounts,
    required this.styleCounts,
    required this.neutralItemCount,
    required this.darkToneCount,
    required this.formalItemCount,
    required this.hoodieLikeCount,
    required this.mostUsedSlot,
    required this.mostRepeatedColor,
    required this.mostVersatileItem,
    required this.missingSlots,
    required this.overloadedSlots,
  });

  final int totalItems;
  final Map<WardrobeOutfitSlot, int> slotCounts;
  final Map<String, int> colorCounts;
  final Map<String, int> styleCounts;
  final int neutralItemCount;
  final int darkToneCount;
  final int formalItemCount;
  final int hoodieLikeCount;
  final WardrobeOutfitSlot? mostUsedSlot;
  final String? mostRepeatedColor;
  final WardrobeItem? mostVersatileItem;
  final List<WardrobeOutfitSlot> missingSlots;
  final List<WardrobeOutfitSlot> overloadedSlots;

  int countFor(WardrobeOutfitSlot slot) => slotCounts[slot] ?? 0;

  String get compactSummary {
    if (totalItems == 0) return 'empty';

    final parts = <String>[
      'n=$totalItems',
      'top=${countFor(WardrobeOutfitSlot.top)}',
      'bottom=${countFor(WardrobeOutfitSlot.bottom)}',
      'dress=${countFor(WardrobeOutfitSlot.dress)}',
      'set=${countFor(WardrobeOutfitSlot.set)}',
      'outer=${countFor(WardrobeOutfitSlot.outerwear)}',
      'shoes=${countFor(WardrobeOutfitSlot.shoes)}',
      'acc=${countFor(WardrobeOutfitSlot.accessory)}',
      'neutral=$neutralItemCount',
      'dark=$darkToneCount',
      'formal=$formalItemCount',
      'hoodies=$hoodieLikeCount',
    ];

    if (mostRepeatedColor != null) {
      parts.add('topColor=$mostRepeatedColor');
    }
    if (mostUsedSlot != null) {
      parts.add('topSlot=${mostUsedSlot!.name}');
    }
    if (missingSlots.isNotEmpty) {
      parts.add('missing=${missingSlots.map((s) => s.name).join(",")}');
    }
    if (overloadedSlots.isNotEmpty) {
      parts.add('overload=${overloadedSlots.map((s) => s.name).join(",")}');
    }

    final topColors = colorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (topColors.isNotEmpty) {
      final colorLine = topColors
          .take(4)
          .map((e) => '${e.key}×${e.value}')
          .join(',');
      parts.add('colors:$colorLine');
    }

    return parts.join('; ');
  }
}
