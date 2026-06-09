import '../../data/models/wardrobe_item.dart';
import '../models/wardrobe_outfit_slot.dart';
import '../services/wardrobe_slot_classifier.dart';

/// What the user already owns — used to avoid «buy/add X» tips when X exists.
class WardrobeInventoryProfile {
  const WardrobeInventoryProfile({
    required this.hasTop,
    required this.hasBottomCoverage,
    required this.hasDress,
    required this.hasSet,
    required this.hasShoes,
    required this.hasOuterwear,
    required this.hasAccessory,
    required this.hasNeutralTop,
    required this.hasNeutralBottom,
    required this.hasLightAccent,
    required this.hasFormalPiece,
    required this.hasJeans,
    required this.hasWhiteTop,
    required this.hasCasualShoes,
    required this.hasDressyShoes,
    required this.ownedItemLines,
  });

  final bool hasTop;
  final bool hasBottomCoverage;
  final bool hasDress;
  final bool hasSet;
  final bool hasShoes;
  final bool hasOuterwear;
  final bool hasAccessory;
  final bool hasNeutralTop;
  final bool hasNeutralBottom;
  final bool hasLightAccent;
  final bool hasFormalPiece;
  final bool hasJeans;
  final bool hasWhiteTop;
  final bool hasCasualShoes;
  final bool hasDressyShoes;
  final List<String> ownedItemLines;

  /// Enough basics to mix outfits without pushing «add jeans/white tee».
  bool get hasStrongNeutralBase {
    final versatileLower =
        hasNeutralBottom || hasJeans || hasDress || hasSet;
    final linkingTop = hasNeutralTop || hasWhiteTop;
    if (linkingTop && versatileLower) return true;
    // Fully covered slots with several neutrals still count as balanced.
    return hasTop &&
        hasBottomCoverage &&
        (hasNeutralTop || hasNeutralBottom || hasJeans);
  }

  factory WardrobeInventoryProfile.fromItems(List<WardrobeItem> items) {
    var hasTop = false;
    var hasBottom = false;
    var hasDress = false;
    var hasSet = false;
    var hasShoes = false;
    var hasOuterwear = false;
    var hasAccessory = false;
    var hasNeutralTop = false;
    var hasNeutralBottom = false;
    var hasLightAccent = false;
    var hasFormalPiece = false;
    var hasJeans = false;
    var hasWhiteTop = false;
    var hasCasualShoes = false;
    var hasDressyShoes = false;
    final lines = <String>[];

    for (final item in items) {
      final slot = WardrobeSlotClassifier.classify(item);
      final blob = _blob(item);

      lines.add('${item.category}: ${item.title.trim()}');

      if (slot == WardrobeOutfitSlot.top) {
        hasTop = true;
        if (_isNeutralItem(item)) hasNeutralTop = true;
        if (_matches(blob, _whiteTopPatterns)) hasWhiteTop = true;
      } else if (slot == WardrobeOutfitSlot.bottom) {
        hasBottom = true;
        if (_isNeutralItem(item)) hasNeutralBottom = true;
        if (_matches(blob, _jeansPatterns)) hasJeans = true;
      } else if (slot == WardrobeOutfitSlot.dress) {
        hasDress = true;
        if (_isNeutralItem(item)) hasNeutralTop = true;
      } else if (slot == WardrobeOutfitSlot.set) {
        hasSet = true;
      } else if (slot == WardrobeOutfitSlot.outerwear) {
        hasOuterwear = true;
      } else if (slot == WardrobeOutfitSlot.shoes) {
        hasShoes = true;
        if (_matches(blob, _casualShoePatterns)) hasCasualShoes = true;
        if (_matches(blob, _dressyShoePatterns)) hasDressyShoes = true;
      } else if (slot == WardrobeOutfitSlot.accessory) {
        hasAccessory = true;
      } else {
        if (_matches(blob, _jeansPatterns)) {
          hasBottom = true;
          hasJeans = true;
        }
        if (_matches(blob, _shoePatterns)) {
          hasShoes = true;
          if (_matches(blob, _casualShoePatterns)) hasCasualShoes = true;
          if (_matches(blob, _dressyShoePatterns)) hasDressyShoes = true;
        }
        if (_matches(blob, _outerwearPatterns)) hasOuterwear = true;
        if (_matches(blob, _accessoryPatterns)) hasAccessory = true;
        if (_matches(blob, _topPatterns)) {
          hasTop = true;
          if (_isNeutralItem(item)) hasNeutralTop = true;
        }
      }

      if (_isLightAccent(item)) hasLightAccent = true;
      if (_isFormalItem(item)) hasFormalPiece = true;
    }

    final bottomCoverage = hasBottom || hasDress || hasSet;

    return WardrobeInventoryProfile(
      hasTop: hasTop || hasDress || hasSet,
      hasBottomCoverage: bottomCoverage,
      hasDress: hasDress,
      hasSet: hasSet,
      hasShoes: hasShoes,
      hasOuterwear: hasOuterwear,
      hasAccessory: hasAccessory,
      hasNeutralTop: hasNeutralTop,
      hasNeutralBottom: hasNeutralBottom,
      hasLightAccent: hasLightAccent,
      hasFormalPiece: hasFormalPiece,
      hasJeans: hasJeans,
      hasWhiteTop: hasWhiteTop,
      hasCasualShoes: hasCasualShoes,
      hasDressyShoes: hasDressyShoes,
      ownedItemLines: lines,
    );
  }

  String ownedSummaryForAi({int maxItems = 24}) {
    if (ownedItemLines.isEmpty) return 'none';
    return ownedItemLines.take(maxItems).join('; ');
  }

  /// True when a tip clearly asks to add something the wardrobe already has.
  bool contradictsOwned(String text) {
    final t = text.toLowerCase();
    final checks = <bool Function(String), bool>{
      (s) => _mentions(s, _jeansSuggestPatterns): hasJeans,
      (s) => _mentions(s, _whiteTopSuggestPatterns): hasWhiteTop || hasNeutralTop,
      (s) => _mentions(s, _neutralBottomSuggestPatterns):
          hasNeutralBottom || hasJeans || hasDress || hasSet,
      (s) => _mentions(s, _shoeSuggestPatterns): hasShoes,
      (s) => _mentions(s, _outerwearSuggestPatterns): hasOuterwear,
      (s) => _mentions(s, _accessorySuggestPatterns): hasAccessory,
      (s) => _mentions(s, _dressSuggestPatterns): hasDress,
      (s) => _mentions(s, _formalSuggestPatterns): hasFormalPiece,
      (s) => _mentions(s, _lightAccentSuggestPatterns): hasLightAccent,
    };

    for (final entry in checks.entries) {
      if (entry.value && entry.key(t)) return true;
    }
    return false;
  }

  static String _blob(WardrobeItem item) =>
      '${item.title} ${item.color} ${item.category} '
              '${item.occasions.join(' ')} ${item.styles.join(' ')}'
          .toLowerCase();

  static bool _matches(String blob, List<String> needles) =>
      needles.any(blob.contains);

  static bool _mentions(String text, List<String> needles) =>
      needles.any(text.contains);

  static bool _isNeutralItem(WardrobeItem item) {
    final blob = _blob(item);
    return _neutralKeywords.any(blob.contains);
  }

  static bool _isLightAccent(WardrobeItem item) {
    final blob = _blob(item);
    return _lightKeywords.any(blob.contains);
  }

  static bool _isFormalItem(WardrobeItem item) {
    final blob = _blob(item);
    return _formalKeywords.any(blob.contains);
  }

  static const _neutralKeywords = [
    'беж', 'бел', 'сер', 'черн', 'чёрн', 'джинс', 'нейтрал', 'крем', 'экрю',
    'camel', 'white', 'gray', 'grey', 'beige', 'denim', 'cream', 'neutral',
    'khaki', 'navy', 'black',
  ];

  static const _lightKeywords = [
    'бел', 'молоч', 'крем', 'пастел', 'светл', 'беж', 'экрю', 'пудр',
    'white', 'cream', 'ivory', 'pastel', 'light', 'beige', 'blush',
  ];

  static const _formalKeywords = [
    'office', 'офис', 'date', 'свидан', 'party', 'вечер', 'делов',
    'пиджак', 'blazer', 'костюм', 'suit', 'туфл', 'heel', 'лодк',
  ];

  static const _jeansPatterns = ['джинс', 'jeans', 'denim'];
  static const _whiteTopPatterns = [
    'бел', 'white', 'футбол', 'tee', 'рубаш', 'shirt', 'блуз', 'blouse',
  ];
  static const _topPatterns = [
    'футбол', 'tee', 'рубаш', 'shirt', 'блуз', 'топ', 'худи', 'hoodie',
    'свитер', 'sweater', 'свитшот', 'sweatshirt',
  ];
  static const _shoePatterns = [
    'кроссов', 'sneaker', 'кед', 'ботин', 'boot', 'туфл', 'heel', 'лофер',
    'loafer', 'сандал', 'sandal', 'мокасин',
  ];
  static const _casualShoePatterns = [
    'кроссов', 'sneaker', 'кед', 'сандал', 'sandal', 'мокасин', 'лофер',
    'loafer', 'шлёп', 'slipper',
  ];
  static const _dressyShoePatterns = [
    'туфл', 'heel', 'лодк', 'ботин', 'boot',
  ];
  static const _outerwearPatterns = [
    'куртк', 'пальто', 'плащ', 'тренч', 'пухов', 'жакет', 'jacket', 'coat',
    'кардиган', 'cardigan', 'бомбер',
  ];
  static const _accessoryPatterns = [
    'сумк', 'bag', 'ремен', 'belt', 'шарф', 'scarf', 'шапк', 'hat', 'украшен',
    'jewelry', 'очк', 'glasses',
  ];

  static const _jeansSuggestPatterns = ['джинс', 'jeans', 'denim'];
  static const _whiteTopSuggestPatterns = [
    'бел', 'white', 'футболк', 'tee', 'рубаш', 'shirt',
  ];
  static const _neutralBottomSuggestPatterns = [
    'брюк', 'trouser', 'pants', 'юбк', 'skirt', 'низ', 'bottom',
  ];
  static const _shoeSuggestPatterns = [
    'обув', 'shoe', 'кроссов', 'sneaker', 'ботин', 'boot', 'лофер', 'loafer',
    'туфл', 'heel',
  ];
  static const _outerwearSuggestPatterns = [
    'куртк', 'пальто', 'жакет', 'jacket', 'coat', 'outerwear', 'тренч',
    'кардиган', 'cardigan',
  ];
  static const _accessorySuggestPatterns = [
    'аксессуар', 'accessory', 'сумк', 'bag', 'ремен', 'belt', 'украшен',
  ];
  static const _dressSuggestPatterns = ['плать', 'dress'];
  static const _formalSuggestPatterns = [
    'formal', 'офис', 'office', 'нарядн', 'dressy', 'пиджак', 'blazer',
  ];
  static const _lightAccentSuggestPatterns = [
    'светл', 'light', 'пастел', 'pastel', 'молоч', 'cream', 'бежев',
  ];
}
