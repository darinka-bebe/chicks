import '../constants/wardrobe_catalog.dart';
import '../../data/models/clothing_vision_analysis.dart';

/// Maps free-form Vision API output to [WardrobeCatalog] values.
abstract final class ClothingVisionMapper {
  static ClothingVisionAnalysis toCatalogValues(ClothingVisionAnalysis raw) {
    return ClothingVisionAnalysis(
      title: raw.title.trim(),
      category: _matchCategory(raw.category, raw.clothingType),
      color: raw.color.trim(),
      clothingType: raw.clothingType.trim(),
      styles: _matchMany(raw.styles, WardrobeCatalog.styles),
      seasons: _matchMany(
        raw.seasons,
        WardrobeCatalog.seasons,
        fallback: WardrobeCatalog.seasons.last,
      ),
      occasions: _matchMany(raw.occasions, WardrobeCatalog.occasions),
      vibes: _matchMany(raw.vibes, WardrobeCatalog.vibes),
      fit: _matchOne(raw.fit, WardrobeCatalog.fits),
      outfitContext: raw.outfitContext.trim(),
      isDuplicate: raw.isDuplicate,
      duplicateMatchTitle: raw.duplicateMatchTitle,
      recognizable: raw.recognizable,
      recognitionNote: raw.recognitionNote,
    );
  }

  static String _matchCategory(String category, String clothingType) {
    final trimmed = category.trim();
    if (WardrobeCatalog.categories.contains(trimmed)) {
      return trimmed;
    }

    final alias = _categoryAliases['${trimmed.toLowerCase()} ${clothingType.toLowerCase()}'.trim()] ??
        _categoryAliases[trimmed.toLowerCase()] ??
        _categoryAliases[clothingType.toLowerCase()];
    if (alias != null) return alias;

    final hint = '${category.toLowerCase()} ${clothingType.toLowerCase()}';

    const footwearKeys = [
      'кроссов',
      'sneaker',
      'trainer',
      'кед',
      'обув',
      'shoe',
      'boot',
      'loafer',
      'sandal',
      'туфл',
      'ботин',
      'мокасин',
      'slipper',
      'espadrille',
      'heel',
      'flip-flop',
      'flip flop',
      'шлёп',
      'шлеп',
      'ugg',
      'cleat',
    ];
    for (final key in footwearKeys) {
      if (hint.contains(key)) return 'Обувь';
    }

    const synonyms = <String, String>{
      'комплект': 'Комплекты',
      'костюм': 'Комплекты',
      'tracksuit': 'Комплекты',
      'co-ord': 'Комплекты',
      'coord': 'Комплекты',
      'sport suit': 'Комплекты',
      'twin set': 'Комплекты',
      'matching set': 'Комплекты',
      'верхняя': 'Верхняя одежда',
      'outerwear': 'Верхняя одежда',
      'coat': 'Верхняя одежда',
      'jacket': 'Верхняя одежда',
      'пальт': 'Верхняя одежда',
      'пуховик': 'Верхняя одежда',
      'плать': 'Платья',
      'dress': 'Платья',
      'dresses': 'Платья',
      'низ': 'Низ',
      'bottom': 'Низ',
      'bottoms': 'Низ',
      'pants': 'Низ',
      'jeans': 'Низ',
      'брюки': 'Низ',
      'юбк': 'Низ',
      'шорт': 'Низ',
      'skirt': 'Низ',
      'верх': 'Верх',
      'top': 'Верх',
      'tops': 'Верх',
      'shirt': 'Верх',
      'blouse': 'Верх',
      'свитер': 'Верх',
      'худи': 'Верх',
      'hoodie': 'Верх',
      'футбол': 'Верх',
      't-shirt': 'Верх',
      'аксессуар': 'Аксессуары',
      'accessor': 'Аксессуары',
      'сумк': 'Аксессуары',
      'bag': 'Аксессуары',
      'belt': 'Аксессуары',
      'ремен': 'Аксессуары',
      'шарф': 'Аксессуары',
      'scarf': 'Аксессуары',
      'шапк': 'Аксессуары',
      'hat': 'Аксессуары',
      'cap': 'Аксессуары',
      'очк': 'Аксессуары',
      'glasses': 'Аксессуары',
      'jewelry': 'Аксессуары',
      'украшен': 'Аксессуары',
    };

    for (final entry in synonyms.entries) {
      if (hint.contains(entry.key)) {
        return entry.value;
      }
    }

    for (final option in WardrobeCatalog.categories) {
      if (hint.contains(option.toLowerCase())) {
        return option;
      }
    }

    return trimmed;
  }

  static List<String> _matchMany(
    List<String> values,
    List<String> allowed, {
    String? fallback,
  }) {
    final matched = <String>[];
    for (final value in values) {
      final hit = _matchOne(value, allowed);
      if (hit.isNotEmpty && !matched.contains(hit)) {
        matched.add(hit);
      }
    }
    if (matched.isEmpty && fallback != null) {
      return [fallback];
    }
    return matched;
  }

  static String _matchOne(String value, List<String> allowed) {
    if (value.isEmpty) return '';
    final lower = value.toLowerCase().trim();

    for (final option in allowed) {
      if (option.toLowerCase() == lower) return option;
      if (lower.contains(option.toLowerCase()) ||
          option.toLowerCase().contains(lower)) {
        return option;
      }
    }

    final alias = _metadataAliases[lower];
    if (alias != null && allowed.contains(alias)) {
      return alias;
    }

    for (final entry in _metadataAliases.entries) {
      if (lower.contains(entry.key) && allowed.contains(entry.value)) {
        return entry.value;
      }
    }

    return '';
  }

  static const _categoryAliases = <String, String>{
    'tops': 'Верх',
    'top': 'Верх',
    'bottoms': 'Низ',
    'bottom': 'Низ',
    'dresses': 'Платья',
    'dress': 'Платья',
    'sets': 'Комплекты',
    'set': 'Комплекты',
    'outerwear': 'Верхняя одежда',
    'shoes': 'Обувь',
    'footwear': 'Обувь',
    'accessories': 'Аксессуары',
    'accessory': 'Аксессуары',
  };

  static const _metadataAliases = <String, String>{
    'spring': 'Весна',
    'summer': 'Лето',
    'autumn': 'Осень',
    'fall': 'Осень',
    'winter': 'Зима',
    'all-season': 'Всесезон',
    'all season': 'Всесезон',
    'year-round': 'Всесезон',
    'school': 'школа',
    'walk': 'прогулка',
    'stroll': 'прогулка',
    'minimalism': 'минимализм',
    'minimalist': 'минимализм',
    'romantic': 'романтичный',
    'bold': 'дерзкий',
    'edgy': 'дерзкий',
    'cozy': 'уютный',
    'comfy': 'уютный',
    'elegant': 'элегантный',
    'playful': 'игривый',
    'fun': 'игривый',
  };
}
