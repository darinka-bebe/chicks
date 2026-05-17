import '../constants/wardrobe_catalog.dart';
import '../../data/models/clothing_vision_analysis.dart';

/// Maps free-form Vision API output to [WardrobeCatalog] values.
abstract final class ClothingVisionMapper {
  static ClothingVisionAnalysis toCatalogValues(ClothingVisionAnalysis raw) {
    return ClothingVisionAnalysis(
      title: raw.title,
      category: _matchCategory(raw.category, raw.clothingType),
      color: raw.color,
      clothingType: raw.clothingType,
      styles: _matchMany(raw.styles, WardrobeCatalog.styles),
      seasons: _matchMany(
        raw.seasons,
        WardrobeCatalog.seasons,
        fallback: WardrobeCatalog.seasons.last,
      ),
      occasions: _matchMany(raw.occasions, WardrobeCatalog.occasions),
      vibes: _matchMany(raw.vibes, WardrobeCatalog.vibes),
      fit: _matchOne(raw.fit, WardrobeCatalog.fits),
      outfitContext: raw.outfitContext,
    );
  }

  static String _matchCategory(String category, String clothingType) {
    final hint = '${category.toLowerCase()} ${clothingType.toLowerCase()}';

    const synonyms = <String, String>{
      'верх': 'Верх',
      'top': 'Верх',
      'shirt': 'Верх',
      'blouse': 'Верх',
      'свитер': 'Верх',
      'низ': 'Низ',
      'bottom': 'Низ',
      'pants': 'Низ',
      'jeans': 'Низ',
      'брюки': 'Низ',
      'юбк': 'Низ',
      'плать': 'Платья',
      'dress': 'Платья',
      'верхняя': 'Верхняя одежда',
      'coat': 'Верхняя одежда',
      'jacket': 'Верхняя одежда',
      'пальт': 'Верхняя одежда',
      'обув': 'Обувь',
      'shoe': 'Обувь',
      'boot': 'Обувь',
      'аксессуар': 'Аксессуары',
      'bag': 'Аксессуары',
      'accessory': 'Аксессуары',
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

    if (WardrobeCatalog.categories.contains(category)) {
      return category;
    }

    return WardrobeCatalog.categories.first;
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
    final lower = value.toLowerCase();
    for (final option in allowed) {
      if (option.toLowerCase() == lower) return option;
      if (lower.contains(option.toLowerCase()) ||
          option.toLowerCase().contains(lower)) {
        return option;
      }
    }
    return '';
  }
}
