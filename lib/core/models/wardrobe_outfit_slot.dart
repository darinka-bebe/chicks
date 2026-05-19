/// Canonical outfit slots — at most one item per slot in a curated look.
enum WardrobeOutfitSlot {
  top,
  bottom,
  dress,
  outerwear,
  shoes,
  accessory,
  unknown,
}

extension WardrobeOutfitSlotX on WardrobeOutfitSlot {
  /// Display order in prompts and UI strips.
  static const List<WardrobeOutfitSlot> outfitOrder = [
    WardrobeOutfitSlot.dress,
    WardrobeOutfitSlot.top,
    WardrobeOutfitSlot.bottom,
    WardrobeOutfitSlot.outerwear,
    WardrobeOutfitSlot.shoes,
    WardrobeOutfitSlot.accessory,
  ];

  String get promptLabelRu => switch (this) {
        WardrobeOutfitSlot.top => 'Верх (топ) — максимум 1',
        WardrobeOutfitSlot.bottom => 'Низ — максимум 1',
        WardrobeOutfitSlot.dress => 'Платье — максимум 1 (вместо верх+низ)',
        WardrobeOutfitSlot.outerwear => 'Верхняя одежда — максимум 1',
        WardrobeOutfitSlot.shoes => 'Обувь — максимум 1',
        WardrobeOutfitSlot.accessory => 'Аксессуары — максимум 1',
        WardrobeOutfitSlot.unknown => 'Прочее',
      };

  String get sectionTitleRu => switch (this) {
        WardrobeOutfitSlot.top => 'ВЕРХ (топы, рубашки, свитера, худи)',
        WardrobeOutfitSlot.bottom => 'НИЗ (брюки, джинсы, юбки, шорты)',
        WardrobeOutfitSlot.dress => 'ПЛАТЬЯ',
        WardrobeOutfitSlot.outerwear => 'ВЕРХНЯЯ ОДЕЖДА',
        WardrobeOutfitSlot.shoes => 'ОБУВЬ',
        WardrobeOutfitSlot.accessory => 'АКСЕССУАРЫ',
        WardrobeOutfitSlot.unknown => 'ПРОЧЕЕ',
      };
}
