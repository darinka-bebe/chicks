import '../localization/app_locale.dart';

/// Canonical outfit slots — at most one item per slot in a curated look.
enum WardrobeOutfitSlot {
  top,
  bottom,
  dress,
  /// Matching set: tracksuit, suit, co-ord — replaces top + bottom.
  set,
  outerwear,
  shoes,
  accessory,
  unknown,
}

extension WardrobeOutfitSlotX on WardrobeOutfitSlot {
  /// Display order in prompts and UI strips.
  static const List<WardrobeOutfitSlot> outfitOrder = [
    WardrobeOutfitSlot.dress,
    WardrobeOutfitSlot.set,
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
        WardrobeOutfitSlot.set => 'Комплект — максимум 1 (вместо верх+низ)',
        WardrobeOutfitSlot.outerwear => 'Верхняя одежда — максимум 1',
        WardrobeOutfitSlot.shoes => 'Обувь — максимум 1',
        WardrobeOutfitSlot.accessory => 'Аксессуары — максимум 1',
        WardrobeOutfitSlot.unknown => 'Прочее',
      };

  String get displayName => AppLocale.pick(
        ru: displayNameRu,
        en: displayNameEn,
        kk: displayNameKk,
      );

  String get displayNameLower => AppLocale.pick(
        ru: displayNameRu.toLowerCase(),
        en: displayNameEnLower,
        kk: displayNameKkLower,
      );

  String get statsStripLabel => AppLocale.pick(
        ru: statsStripLabelRu,
        en: statsStripLabelEn,
        kk: statsStripLabelKk,
      );

  String get compositionLabel => AppLocale.pick(
        ru: compositionLabelRu,
        en: compositionLabelEn,
        kk: displayNameKk,
      );

  String get displayNameRu => switch (this) {
        WardrobeOutfitSlot.top => 'Верх',
        WardrobeOutfitSlot.bottom => 'Низ',
        WardrobeOutfitSlot.dress => 'Платье',
        WardrobeOutfitSlot.set => 'Комплект',
        WardrobeOutfitSlot.outerwear => 'Верхняя одежда',
        WardrobeOutfitSlot.shoes => 'Обувь',
        WardrobeOutfitSlot.accessory => 'Аксессуар',
        WardrobeOutfitSlot.unknown => 'Вещь',
      };

  String get displayNameEn => switch (this) {
        WardrobeOutfitSlot.top => 'Top',
        WardrobeOutfitSlot.bottom => 'Bottom',
        WardrobeOutfitSlot.dress => 'Dress',
        WardrobeOutfitSlot.set => 'Set',
        WardrobeOutfitSlot.outerwear => 'Outerwear',
        WardrobeOutfitSlot.shoes => 'Shoes',
        WardrobeOutfitSlot.accessory => 'Accessory',
        WardrobeOutfitSlot.unknown => 'Item',
      };

  String get displayNameEnLower => switch (this) {
        WardrobeOutfitSlot.top => 'top',
        WardrobeOutfitSlot.bottom => 'bottom',
        WardrobeOutfitSlot.dress => 'dress',
        WardrobeOutfitSlot.set => 'set',
        WardrobeOutfitSlot.outerwear => 'outerwear',
        WardrobeOutfitSlot.shoes => 'shoes',
        WardrobeOutfitSlot.accessory => 'accessory',
        WardrobeOutfitSlot.unknown => 'item',
      };

  String get displayNameKk => switch (this) {
        WardrobeOutfitSlot.top => 'Жоғғы киім',
        WardrobeOutfitSlot.bottom => 'Төменгі киім',
        WardrobeOutfitSlot.dress => 'Көйлек',
        WardrobeOutfitSlot.set => 'Комплект',
        WardrobeOutfitSlot.outerwear => 'Сырт киім',
        WardrobeOutfitSlot.shoes => 'Аяқ киім',
        WardrobeOutfitSlot.accessory => 'Аксессуар',
        WardrobeOutfitSlot.unknown => 'Зат',
      };

  String get displayNameKkLower => switch (this) {
        WardrobeOutfitSlot.top => 'жоғғы киім',
        WardrobeOutfitSlot.bottom => 'төменгі киім',
        WardrobeOutfitSlot.dress => 'көйлек',
        WardrobeOutfitSlot.set => 'комплект',
        WardrobeOutfitSlot.outerwear => 'сырт киім',
        WardrobeOutfitSlot.shoes => 'аяқ киім',
        WardrobeOutfitSlot.accessory => 'аксессуар',
        WardrobeOutfitSlot.unknown => 'зат',
      };

  String get statsStripLabelRu => switch (this) {
        WardrobeOutfitSlot.top => 'Верх',
        WardrobeOutfitSlot.bottom => 'Низ',
        WardrobeOutfitSlot.shoes => 'Обувь',
        WardrobeOutfitSlot.outerwear => 'Верх. одежда',
        WardrobeOutfitSlot.accessory => 'Аксессуары',
        WardrobeOutfitSlot.dress => 'Платья',
        WardrobeOutfitSlot.set => 'Комплекты',
        WardrobeOutfitSlot.unknown => 'Прочее',
      };

  String get statsStripLabelEn => switch (this) {
        WardrobeOutfitSlot.top => 'Tops',
        WardrobeOutfitSlot.bottom => 'Bottoms',
        WardrobeOutfitSlot.shoes => 'Shoes',
        WardrobeOutfitSlot.outerwear => 'Outerwear',
        WardrobeOutfitSlot.accessory => 'Accessories',
        WardrobeOutfitSlot.dress => 'Dresses',
        WardrobeOutfitSlot.set => 'Sets',
        WardrobeOutfitSlot.unknown => 'Other',
      };

  String get statsStripLabelKk => switch (this) {
        WardrobeOutfitSlot.top => 'Жоғғы киім',
        WardrobeOutfitSlot.bottom => 'Төменгі киім',
        WardrobeOutfitSlot.shoes => 'Аяқ киім',
        WardrobeOutfitSlot.outerwear => 'Сырт киім',
        WardrobeOutfitSlot.accessory => 'Аксессуарлар',
        WardrobeOutfitSlot.dress => 'Көйлектер',
        WardrobeOutfitSlot.set => 'Комплекттер',
        WardrobeOutfitSlot.unknown => 'Басқа',
      };

  String get compositionLabelRu => displayNameRu;

  String get compositionLabelEn => displayNameEn;

  String get sectionTitleRu => switch (this) {
        WardrobeOutfitSlot.top => 'ВЕРХ (топы, рубашки, свитера, худи)',
        WardrobeOutfitSlot.bottom => 'НИЗ (брюки, джинсы, юбки, шорты)',
        WardrobeOutfitSlot.dress => 'ПЛАТЬЯ',
        WardrobeOutfitSlot.set =>
          'КОМПЛЕКТЫ (костюм, спортивный костюм, коорд-сет)',
        WardrobeOutfitSlot.outerwear => 'ВЕРХНЯЯ ОДЕЖДА',
        WardrobeOutfitSlot.shoes => 'ОБУВЬ',
        WardrobeOutfitSlot.accessory => 'АКСЕССУАРЫ',
        WardrobeOutfitSlot.unknown => 'ПРОЧЕЕ',
      };
}
