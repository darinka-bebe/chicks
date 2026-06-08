import 'package:flutter/material.dart';

import '../../data/models/wardrobe_item.dart';
import '../localization/app_locale.dart';

/// Categories, seasons, style metadata, and icons for wardrobe items.
/// Storage keys stay Russian; use [display*] helpers for UI labels.
abstract final class WardrobeCatalog {
  static const unspecifiedColor = 'Не указан';

  static final _cyrillic = RegExp(r'[А-Яа-яЁё]');

  static const List<String> categories = [
    'Верх',
    'Низ',
    'Платья',
    'Комплекты',
    'Верхняя одежда',
    'Обувь',
    'Аксессуары',
  ];

  static const List<String> seasons = [
    'Весна',
    'Лето',
    'Осень',
    'Зима',
    'Всесезон',
  ];

  static const List<String> styles = [
    'casual',
    'old money',
    'streetwear',
    'clean girl',
    'sporty',
    'feminine',
  ];

  static const List<String> occasions = [
    'школа',
    'прогулка',
    'office',
    'date',
    'party',
  ];

  static const List<String> fits = [
    'oversized',
    'slim',
    'relaxed',
    'regular',
  ];

  static const List<String> vibes = [
    'минимализм',
    'романтичный',
    'дерзкий',
    'уютный',
    'элегантный',
    'игривый',
  ];

  static String displayCategory(String key) =>
      AppLocale.pick(ru: key, en: _categoryEn[key] ?? key);

  static String displaySeason(String key) =>
      AppLocale.pick(ru: key, en: _seasonEn[key] ?? key);

  static String displayOccasion(String key) =>
      AppLocale.pick(ru: key, en: _occasionEn[key] ?? key);

  static String displayVibe(String key) =>
      AppLocale.pick(ru: key, en: _vibeEn[key] ?? key);

  static String displayColor(String key) {
    final trimmed = key.trim();
    if (trimmed.isEmpty || trimmed == unspecifiedColor) {
      return AppLocale.pick(ru: unspecifiedColor, en: 'Not specified');
    }
    if (AppLocale.isRussian()) return key;

    final lower = trimmed.toLowerCase();
    for (final entry in _colorEn.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return key;
  }

  /// Card / details title — English fallback when stored title is Russian on EN UI.
  static String displayItemTitle(WardrobeItem item) {
    final title = item.title.trim();
    if (title.isEmpty) return displayCategory(item.category);
    if (AppLocale.isRussian() || !_cyrillic.hasMatch(title)) {
      return title;
    }

    final inferred = _inferEnglishTitle(item, title);
    if (inferred != null) return inferred;

    return displayCategory(item.category);
  }

  static String? _inferEnglishTitle(WardrobeItem item, String ruTitle) {
    final color = displayColor(item.color);
    final hasColor = item.color.trim().isNotEmpty &&
        item.color.trim() != unspecifiedColor &&
        color != 'Not specified';

    final lower = ruTitle.toLowerCase();
    String? garment;
    for (final entry in _garmentEn.entries) {
      if (lower.contains(entry.key)) {
        garment = entry.value;
        break;
      }
    }

    if (garment != null && hasColor) return '$color $garment';
    if (garment != null) return garment;

    if (hasColor) {
      return '$color ${displayCategory(item.category)}';
    }

    final translated = _translateRuTitleWords(ruTitle);
    if (translated.isNotEmpty && !_cyrillic.hasMatch(translated)) {
      return translated;
    }
    return null;
  }

  static String _translateRuTitleWords(String title) {
    var result = title;
    for (final entry in _titleWordEn.entries) {
      result = result.replaceAll(
        RegExp(entry.key, caseSensitive: false),
        entry.value,
      );
    }
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String displayMetadata(String value) {
    if (categories.contains(value)) return displayCategory(value);
    if (seasons.contains(value)) return displaySeason(value);
    if (occasions.contains(value)) return displayOccasion(value);
    if (vibes.contains(value)) return displayVibe(value);
    return displayColor(value);
  }

  static String itemsLabel(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (AppLocale.isRussian()) {
      if (mod100 >= 11 && mod100 <= 14) return '$count вещей';
      if (mod10 == 1) return '$count вещь';
      if (mod10 >= 2 && mod10 <= 4) return '$count вещи';
      return '$count вещей';
    }
    return count == 1 ? '$count item' : '$count items';
  }

  static String countShownLabel(int shown, int total) => AppLocale.pick(
        ru: '$shown из $total ${_itemsWord(total)}',
        en: '$shown of $total ${total == 1 ? 'item' : 'items'}',
      );

  static String _itemsWord(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod100 >= 11 && mod100 <= 14) return 'вещей';
    if (mod10 == 1) return 'вещь';
    if (mod10 >= 2 && mod10 <= 4) return 'вещи';
    return 'вещей';
  }

  static IconData iconForCategory(String category) {
    switch (category) {
      case 'Верх':
        return Icons.checkroom_outlined;
      case 'Низ':
        return Icons.straighten_outlined;
      case 'Платья':
        return Icons.woman_outlined;
      case 'Комплекты':
        return Icons.style_outlined;
      case 'Верхняя одежда':
        return Icons.cloud_outlined;
      case 'Обувь':
        return Icons.directions_run_outlined;
      case 'Аксессуары':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.checkroom_outlined;
    }
  }

  static const _categoryEn = {
    'Верх': 'Tops',
    'Низ': 'Bottoms',
    'Платья': 'Dresses',
    'Комплекты': 'Sets',
    'Верхняя одежда': 'Outerwear',
    'Обувь': 'Shoes',
    'Аксессуары': 'Accessories',
  };

  static const _seasonEn = {
    'Весна': 'Spring',
    'Лето': 'Summer',
    'Осень': 'Autumn',
    'Зима': 'Winter',
    'Всесезон': 'All-season',
  };

  static const _occasionEn = {
    'школа': 'School',
    'прогулка': 'Walk',
    'office': 'Office',
    'date': 'Date',
    'party': 'Party',
  };

  static const _garmentEn = {
    'футболк': 'T-shirt',
    'рубашк': 'Shirt',
    'блуз': 'Blouse',
    'топ': 'Top',
    'кофт': 'Knit top',
    'свитер': 'Sweater',
    'свитшот': 'Sweatshirt',
    'худи': 'Hoodie',
    'кардиган': 'Cardigan',
    'жилет': 'Vest',
    'джинс': 'Jeans',
    'брюк': 'Trousers',
    'штаны': 'Pants',
    'юбк': 'Skirt',
    'шорт': 'Shorts',
    'леггинс': 'Leggings',
    'плать': 'Dress',
    'сарафан': 'Sundress',
    'кроссовк': 'Sneakers',
    'кед': 'Sneakers',
    'ботинк': 'Boots',
    'сапог': 'Boots',
    'туфл': 'Heels',
    'лофер': 'Loafers',
    'сандал': 'Sandals',
    'шлёп': 'Slippers',
    'шлеп': 'Slippers',
    'куртк': 'Jacket',
    'пальт': 'Coat',
    'пуховик': 'Puffer jacket',
    'пиджак': 'Blazer',
    'плащ': 'Trench coat',
    'костюм': 'Suit',
    'комплект': 'Set',
    'спортивн': 'Tracksuit',
    'сумк': 'Bag',
    'шарф': 'Scarf',
    'шапк': 'Hat',
    'кепк': 'Cap',
    'очк': 'Glasses',
    'украшен': 'Jewelry',
    'ремен': 'Belt',
  };

  static const _titleWordEn = {
    r'бел[а-яё]*': 'White',
    r'ч[её]рн[а-яё]*': 'Black',
    r'син[а-яё]*': 'Blue',
    r'голуб[а-яё]*': 'Light blue',
    r'красн[а-яё]*': 'Red',
    r'розов[а-яё]*': 'Pink',
    r'бежев[а-яё]*': 'Beige',
    r'сер[а-яё]*': 'Gray',
    r'зел[её]н[а-яё]*': 'Green',
    r'ж[её]лт[а-яё]*': 'Yellow',
    r'фиолетов[а-яё]*': 'Purple',
    r'коричнев[а-яё]*': 'Brown',
    r'кожан[а-яё]*': 'Leather',
    r'вязан[а-яё]*': 'Knit',
    r'оверсайз': 'Oversized',
    r'классическ[а-яё]*': 'Classic',
    r'спортивн[а-яё]*': 'Sporty',
    r'повседневн[а-яё]*': 'Casual',
  };

  static const _colorEn = {
    'бел': 'White',
    'чёрн': 'Black',
    'черн': 'Black',
    'син': 'Blue',
    'голуб': 'Light blue',
    'красн': 'Red',
    'розов': 'Pink',
    'беж': 'Beige',
    'сер': 'Gray',
    'зел': 'Green',
    'жёлт': 'Yellow',
    'желт': 'Yellow',
    'фиолет': 'Purple',
    'корич': 'Brown',
    'хаки': 'Khaki',
    'пудр': 'Powder',
    'карамел': 'Caramel',
  };

  static const _vibeEn = {
    'минимализм': 'Minimalism',
    'романтичный': 'Romantic',
    'дерзкий': 'Bold',
    'уютный': 'Cozy',
    'элегантный': 'Elegant',
    'игривый': 'Playful',
  };
}
