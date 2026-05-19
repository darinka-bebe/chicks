import '../../data/models/wardrobe_item.dart';
import '../models/wardrobe_outfit_slot.dart';
import 'wardrobe_slot_classifier.dart';

/// Groups wardrobe items by [WardrobeOutfitSlot] for prompts and curation.
abstract final class WardrobeOutfitGrouper {
  static Map<WardrobeOutfitSlot, List<WardrobeItem>> emptyGrouped() {
    return {
      for (final slot in WardrobeOutfitSlotX.outfitOrder) slot: <WardrobeItem>[],
      WardrobeOutfitSlot.unknown: <WardrobeItem>[],
    };
  }

  static Map<WardrobeOutfitSlot, List<WardrobeItem>> group(
    List<WardrobeItem> items,
  ) {
    final grouped = emptyGrouped();

    for (final item in items) {
      try {
        final slot = WardrobeSlotClassifier.classify(item);
        (grouped[slot] ??= <WardrobeItem>[]).add(item);
      } catch (_) {
        (grouped[WardrobeOutfitSlot.unknown] ??= <WardrobeItem>[]).add(item);
      }
    }

    for (final list in grouped.values) {
      list.sort((a, b) => a.title.compareTo(b.title));
    }

    return grouped;
  }

  static int itemCount(Map<WardrobeOutfitSlot, List<WardrobeItem>> grouped) {
    return grouped.values.fold<int>(0, (sum, list) => sum + list.length);
  }
}
