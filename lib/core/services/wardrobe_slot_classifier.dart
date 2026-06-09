import '../../data/models/wardrobe_item.dart';
import '../models/wardrobe_outfit_slot.dart';

/// Maps wardrobe [WardrobeItem.category] (and title hints) to outfit slots.
abstract final class WardrobeSlotClassifier {
  static WardrobeOutfitSlot classify(WardrobeItem item) {
    try {
      final category = item.category.trim().toLowerCase();

      final fromCategory = _fromCategory(category);
      if (fromCategory != WardrobeOutfitSlot.unknown) {
        return fromCategory;
      }

      return _fromTitleHints(item.title.trim());
    } catch (_) {
      return WardrobeOutfitSlot.unknown;
    }
  }

  static WardrobeOutfitSlot _fromCategory(String category) {
    if (category == 'верх' || category == 'tops' || category == 'top') {
      return WardrobeOutfitSlot.top;
    }
    if (category == 'низ' ||
        category == 'bottoms' ||
        category == 'bottom') {
      return WardrobeOutfitSlot.bottom;
    }
    if (category == 'платья' ||
        category == 'платье' ||
        category == 'dresses' ||
        category == 'dress') {
      return WardrobeOutfitSlot.dress;
    }
    if (category == 'комплекты' ||
        category == 'комплект' ||
        category == 'костюм' ||
        category == 'костюмы' ||
        category == 'sets' ||
        category == 'set') {
      return WardrobeOutfitSlot.set;
    }
    if (category == 'верхняя одежда' ||
        category == 'outerwear' ||
        category == 'jackets') {
      return WardrobeOutfitSlot.outerwear;
    }
    if (category == 'обувь' || category == 'shoes' || category == 'footwear') {
      return WardrobeOutfitSlot.shoes;
    }
    if (category == 'аксессуары' ||
        category == 'аксессуар' ||
        category == 'accessories' ||
        category == 'accessory') {
      return WardrobeOutfitSlot.accessory;
    }
    return WardrobeOutfitSlot.unknown;
  }

  static WardrobeOutfitSlot _fromTitleHints(String title) {
    final t = title.toLowerCase();

    if (_matchesAny(t, const [
      'платье',
      'сарафан',
      'dress',
      'jumpsuit',
      'комбинезон',
    ])) {
      return WardrobeOutfitSlot.dress;
    }
    if (_matchesAny(t, const [
      'костюм',
      'комплект',
      'коорд',
      'co-ord',
      'coord set',
      'tracksuit',
      'sport suit',
      'спортивн',
      'twin set',
      'двойк',
      'ансамбл',
      'set',
    ])) {
      return WardrobeOutfitSlot.set;
    }
    if (_matchesAny(t, const [
      'куртк',
      'пальто',
      'плащ',
      'тренч',
      'пухов',
      'ветровк',
      'кардиган',
      'жилет',
      'бомбер',
      'coat',
      'jacket',
    ])) {
      return WardrobeOutfitSlot.outerwear;
    }
    if (_matchesAny(t, const [
      'кроссов',
      'ботин',
      'туфл',
      'лодк',
      'сапог',
      'босонож',
      'сандал',
      'кед',
      'шлёп',
      'мокасин',
      'heel',
      'sneaker',
      'boot',
    ])) {
      return WardrobeOutfitSlot.shoes;
    }
    if (_matchesAny(t, const [
      'сумк',
      'рюкзак',
      'шарф',
      'шапк',
      'пояс',
      'ремен',
      'очк',
      'украшен',
      'серьг',
      'колье',
      'браслет',
      'часы',
      'кепк',
      'шляп',
      'bag',
      'belt',
      'hat',
      'scarf',
    ])) {
      return WardrobeOutfitSlot.accessory;
    }
    if (_matchesAny(t, const [
      'джинс',
      'брюк',
      'юбк',
      'шорт',
      'леггинс',
      'штаны',
      'карго',
      'pants',
      'skirt',
      'jeans',
    ])) {
      return WardrobeOutfitSlot.bottom;
    }
    if (_matchesAny(t, const [
      'худи',
      'свитер',
      'рубаш',
      'футбол',
      'топ',
      'блуз',
      'водолаз',
      'лонгслив',
      'майк',
      'жилет',
      'hoodie',
      'sweater',
      'shirt',
      'blouse',
      'tee',
    ])) {
      return WardrobeOutfitSlot.top;
    }

    return WardrobeOutfitSlot.unknown;
  }

  static bool _matchesAny(String text, List<String> needles) {
    return needles.any(text.contains);
  }
}
