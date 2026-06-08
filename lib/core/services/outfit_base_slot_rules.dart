import '../../data/models/wardrobe_item.dart';
import '../models/wardrobe_outfit_slot.dart';

/// Resolves dress / set vs top+bottom conflicts when building outfits.
abstract final class OutfitBaseSlotRules {
  static bool hasFullBase(Map<WardrobeOutfitSlot, WardrobeItem> picked) {
    return picked.containsKey(WardrobeOutfitSlot.dress) ||
        picked.containsKey(WardrobeOutfitSlot.set);
  }

  static bool shouldSkipTopOrBottom(
    WardrobeOutfitSlot slot,
    Map<WardrobeOutfitSlot, WardrobeItem> picked,
  ) {
    if (slot != WardrobeOutfitSlot.top && slot != WardrobeOutfitSlot.bottom) {
      return false;
    }
    return hasFullBase(picked);
  }

  static void resolveBaseConflicts(
    Map<WardrobeOutfitSlot, WardrobeItem> picked,
  ) {
    if (hasFullBase(picked)) {
      picked.remove(WardrobeOutfitSlot.top);
      picked.remove(WardrobeOutfitSlot.bottom);
    }

    if (picked.containsKey(WardrobeOutfitSlot.dress) &&
        picked.containsKey(WardrobeOutfitSlot.set)) {
      picked.remove(WardrobeOutfitSlot.set);
    }
  }

  static void appendBaseItems(
    Map<WardrobeOutfitSlot, WardrobeItem> picked,
    void Function(WardrobeOutfitSlot slot) add,
  ) {
    if (picked.containsKey(WardrobeOutfitSlot.dress)) {
      add(WardrobeOutfitSlot.dress);
      return;
    }
    if (picked.containsKey(WardrobeOutfitSlot.set)) {
      add(WardrobeOutfitSlot.set);
      return;
    }

    add(WardrobeOutfitSlot.top);
    add(WardrobeOutfitSlot.bottom);
  }

  static WardrobeItem? primaryBaseItem(
    Map<WardrobeOutfitSlot, WardrobeItem> outfit,
  ) {
    return outfit[WardrobeOutfitSlot.dress] ??
        outfit[WardrobeOutfitSlot.set] ??
        outfit[WardrobeOutfitSlot.top];
  }
}
