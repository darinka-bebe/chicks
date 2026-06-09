import 'package:flutter/material.dart';

import '../../data/models/wardrobe_item.dart';
import '../localization/app_locale.dart';
import '../localization/style_terms.dart';
import 'stylist_suggestion_chips.dart';

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

  static String displayCategory(String key) => AppLocale.pick(
        ru: key,
        en: _categoryEn[key] ?? key,
        kk: _categoryKk[key] ?? _categoryEn[key] ?? key,
      );

  static String displaySeason(String key) => AppLocale.pick(
        ru: key,
        en: _seasonEn[key] ?? key,
        kk: _seasonKk[key] ?? _seasonEn[key] ?? key,
      );

  static String displayOccasion(String key) {
    final lower = key.trim().toLowerCase();
    if (_stylistOccasionKeys.contains(lower)) {
      return StylistContextCatalog.displayOccasion(lower);
    }

    final canonical = _occasionAliases[lower] ?? key;
    return AppLocale.pick(
      ru: _occasionRu[canonical] ?? _occasionRu[lower] ?? key,
      en: _occasionEn[canonical] ?? _occasionEn[lower] ?? key,
      kk: _occasionKk[canonical] ??
          _occasionKk[lower] ??
          _occasionEn[canonical] ??
          key,
    );
  }

  static bool _isOccasionValue(String value) {
    final lower = value.trim().toLowerCase();
    if (_stylistOccasionKeys.contains(lower)) return true;
    if (_occasionAliases.containsKey(lower)) return true;
    return occasions.any((o) => o.toLowerCase() == lower);
  }

  static const _stylistOccasionKeys = {
    'school',
    'date',
    'office',
    'walk',
    'party',
  };

  static const _occasionAliases = {
    'school': 'школа',
    'walk': 'прогулка',
  };

  static String displayVibe(String key) => AppLocale.pick(
        ru: key,
        en: _vibeEn[key] ?? key,
        kk: _vibeKk[key] ?? _vibeEn[key] ?? key,
      );

  static String displayStyle(String key) {
    switch (key) {
      case 'casual':
        return StyleTerms.casual();
      case 'old money':
        return StyleTerms.oldMoney();
      case 'streetwear':
        return StyleTerms.streetwear();
      case 'clean girl':
        return StyleTerms.cleanGirl();
      case 'sporty':
        return StyleTerms.sporty();
      case 'feminine':
        return StyleTerms.feminine();
      default:
        return key;
    }
  }

  static String displayFit(String key) => AppLocale.pick(
        ru: _fitRu[key] ?? key,
        en: key,
        kk: _fitKk[key] ?? key,
      );

  static String displayColor(String key) {
    final trimmed = key.trim();
    if (trimmed.isEmpty || trimmed == unspecifiedColor) {
      return AppLocale.pick(
        ru: unspecifiedColor,
        en: 'Not specified',
        kk: 'Көрсетілмеген',
      );
    }
    if (AppLocale.isRussian()) return key;

    final lower = trimmed.toLowerCase();
    final colorMap = AppLocale.isKazakh() ? _colorKk : _colorEn;
    for (final entry in colorMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return key;
  }

  /// Card / details title — localized when stored title is Russian or English.
  static String displayItemTitle(WardrobeItem item) {
    final title = item.title.trim();
    if (title.isEmpty) return displayCategory(item.category);
    if (AppLocale.isRussian()) return title;

    if (!_cyrillic.hasMatch(title)) {
      final fromEnglish = _localizeEnglishTitle(item, title);
      if (fromEnglish != null && fromEnglish.isNotEmpty) return fromEnglish;
      return title;
    }

    final inferred = _inferLocalizedTitle(item, title);
    if (inferred != null && inferred.isNotEmpty) return inferred;

    final translated = _translateRuTitleWords(title);
    if (_acceptLocalizedTitle(title, translated)) return translated;

    return displayCategory(item.category);
  }

  /// Kazakh uses Cyrillic; English UI still requires Latin-only titles.
  static bool _acceptLocalizedTitle(String original, String candidate) {
    final normalized = candidate.trim();
    if (normalized.isEmpty) return false;
    if (normalized.toLowerCase() == original.trim().toLowerCase()) return false;
    if (AppLocale.isKazakh()) return true;
    return !_cyrillic.hasMatch(normalized);
  }

  static String? _localizeEnglishTitle(WardrobeItem item, String enTitle) {
    final lower = enTitle.toLowerCase();
    final colorFromField = _colorLabelFromStorage(item.color);
    final colorFromTitle = _colorLabelFromEnglishTitle(lower);
    final color = colorFromField ?? colorFromTitle;
    final hasColor = color != null;

    final garment = _matchEnglishGarment(lower);

    if (garment != null && hasColor) return '$color $garment';
    if (garment != null) return garment;
    if (hasColor) return '$color ${displayCategory(item.category)}';
    return null;
  }

  static String? _inferLocalizedTitle(WardrobeItem item, String ruTitle) {
    final colorFromField = _colorLabelFromStorage(item.color);
    final colorFromTitle = _colorLabelFromTitle(ruTitle);
    final color = colorFromField ?? colorFromTitle;
    final hasColor = color != null;

    final garment = _matchGarment(ruTitle);

    if (garment != null && hasColor) return '$color $garment';
    if (garment != null) return garment;

    if (hasColor) {
      return '$color ${displayCategory(item.category)}';
    }

    final translated = _translateRuTitleWords(ruTitle);
    if (_acceptLocalizedTitle(ruTitle, translated)) return translated;
    return null;
  }

  static String? _colorLabelFromStorage(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == unspecifiedColor) return null;
    final label = displayColor(trimmed);
    if (label == trimmed && _cyrillic.hasMatch(trimmed)) return null;
    if (label == 'Not specified' || label == 'Көрсетілмеген') return null;
    return label;
  }

  static String? _colorLabelFromTitle(String title) {
    final lower = title.toLowerCase();
    final colorMap = AppLocale.isKazakh()
        ? _colorKk
        : AppLocale.isRussian()
            ? null
            : _colorEn;
    if (colorMap == null) return null;

    String? best;
    var bestLen = 0;
    for (final entry in colorMap.entries) {
      if (lower.contains(entry.key) && entry.key.length > bestLen) {
        best = entry.value;
        bestLen = entry.key.length;
      }
    }
    return best;
  }

  static String? _matchGarment(String title) {
    final lower = title.toLowerCase();
    final garmentMap = AppLocale.isKazakh() ? _garmentKk : _garmentEn;

    String? best;
    var bestLen = 0;
    for (final entry in garmentMap.entries) {
      if (lower.contains(entry.key) && entry.key.length > bestLen) {
        best = entry.value;
        bestLen = entry.key.length;
      }
    }
    return best;
  }

  static String? _colorLabelFromEnglishTitle(String lower) {
    final colorMap =
        AppLocale.isKazakh() ? _colorEnglishKk : _colorEnglishEn;

    String? best;
    var bestLen = 0;
    for (final entry in colorMap.entries) {
      if (lower.contains(entry.key) && entry.key.length > bestLen) {
        best = entry.value;
        bestLen = entry.key.length;
      }
    }
    return best;
  }

  static String? _matchEnglishGarment(String lower) {
    String? bestStem;
    var bestLen = 0;
    for (final entry in _englishGarmentStems.entries) {
      if (lower.contains(entry.key) && entry.key.length > bestLen) {
        bestStem = entry.value;
        bestLen = entry.key.length;
      }
    }
    if (bestStem == null) return null;
    return _garmentLabelForStem(bestStem);
  }

  static String? _garmentLabelForStem(String stem) {
    final map = AppLocale.isKazakh() ? _garmentKk : _garmentEn;
    return map[stem];
  }

  static String _translateRuTitleWords(String title) {
    final wordMap = AppLocale.isKazakh() ? _titleWordKk : _titleWordEn;
    var result = title;
    for (final entry in wordMap.entries) {
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
    if (styles.contains(value)) return displayStyle(value);
    if (fits.contains(value)) return displayFit(value);
    if (_isOccasionValue(value)) return displayOccasion(value);
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
    if (AppLocale.isKazakh()) {
      return '$count зат';
    }
    return count == 1 ? '$count item' : '$count items';
  }

  static String countShownLabel(int shown, int total) => AppLocale.pick(
        ru: '$shown из $total ${_itemsWord(total)}',
        en: '$shown of $total ${total == 1 ? 'item' : 'items'}',
        kk: '$shown / $total зат',
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

  static const _categoryKk = {
    'Верх': 'Жоғғы киім',
    'Низ': 'Төменгі киім',
    'Платья': 'Көйлектер',
    'Комплекты': 'Комплекттер',
    'Верхняя одежда': 'Сырт киім',
    'Обувь': 'Аяқ киім',
    'Аксессуары': 'Аксессуарлар',
  };

  static const _categoryEn = {
    'Верх': 'Tops',
    'Низ': 'Bottoms',
    'Платья': 'Dresses',
    'Комплекты': 'Sets',
    'Верхняя одежда': 'Outerwear',
    'Обувь': 'Shoes',
    'Аксессуары': 'Accessories',
  };

  static const _seasonKk = {
    'Весна': 'Көктем',
    'Лето': 'Жаз',
    'Осень': 'Күз',
    'Зима': 'Қыс',
    'Всесезон': 'Барлық маусым',
  };

  static const _seasonEn = {
    'Весна': 'Spring',
    'Лето': 'Summer',
    'Осень': 'Autumn',
    'Зима': 'Winter',
    'Всесезон': 'All-season',
  };

  static const _occasionRu = {
    'школа': 'Школа',
    'прогулка': 'Прогулка',
    'office': 'Офис',
    'date': 'Свидание',
    'party': 'Вечеринка',
  };

  static const _occasionKk = {
    'школа': 'Мектеп',
    'прогулка': 'Серуен',
    'office': 'Офис',
    'date': 'Кездесу',
    'party': 'Кеш',
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
    'майк': 'Tank top',
    'водолаз': 'Turtleneck',
    'лонгслив': 'Long sleeve',
    'поло': 'Polo shirt',
    'бомбер': 'Bomber jacket',
    'ветровк': 'Windbreaker',
    'дубленк': 'Shearling coat',
    'шуб': 'Fur coat',
    'мокасин': 'Loafers',
    'босонож': 'Sandals',
    'угг': 'Uggs',
    'тапк': 'Slippers',
    'галош': 'Galoshes',
    'колгот': 'Tights',
    'чулк': 'Stockings',
    'носк': 'Socks',
    'перчат': 'Gloves',
    'пижам': 'Pajamas',
    'купальник': 'Swimsuit',
    'бикини': 'Bikini',
    'шорты': 'Shorts',
    'жакет': 'Jacket',
    'тренч': 'Trench coat',
    'парк': 'Parka',
    'анорак': 'Anorak',
    'бейсбол': 'Baseball cap',
    'бейсболк': 'Baseball cap',
    'берет': 'Beret',
    'панам': 'Bucket hat',
    'клатч': 'Clutch',
    'рюкзак': 'Backpack',
    'кошел': 'Wallet',
    'брелок': 'Keychain',
    'серьг': 'Earrings',
    'колье': 'Necklace',
    'браслет': 'Bracelet',
    'часы': 'Watch',
    'пояс': 'Belt',
    'галстук': 'Tie',
    'бабочк': 'Bow tie',
    'жилетк': 'Waistcoat',
    'комбинезон': 'Jumpsuit',
    'боди': 'Bodysuit',
    'корсет': 'Corset',
    'туник': 'Tunic',
    'кимоно': 'Kimono',
    'накидк': 'Cape',
    'пончо': 'Poncho',
    'косух': 'Biker jacket',
    'дутк': 'Puffer jacket',
    'уг': 'Uggs',
  };

  static const _garmentKk = {
    'футболк': 'Футболка',
    'рубашк': 'Жейде',
    'блуз': 'Блузка',
    'топ': 'Топ',
    'кофт': 'Свитер',
    'свитер': 'Свитер',
    'свитшот': 'Свитшот',
    'худи': 'Худи',
    'кардиган': 'Кардиган',
    'жилет': 'Жилет',
    'джинс': 'Джинс',
    'брюк': 'Шалбар',
    'штаны': 'Шалбар',
    'юбк': 'Юбка',
    'шорт': 'Шорт',
    'леггинс': 'Леггинс',
    'плать': 'Көйлек',
    'сарафан': 'Сарафан',
    'кроссовк': 'Кроссовка',
    'кед': 'Кед',
    'ботинк': 'Етік',
    'сапог': 'Етік',
    'туфл': 'Туфли',
    'лофер': 'Лофер',
    'сандал': 'Сандал',
    'шлёп': 'Шлёпан',
    'шлеп': 'Шлёпан',
    'куртк': 'Куртка',
    'пальт': 'Пальто',
    'пуховик': 'Пуховик',
    'пиджак': 'Пиджак',
    'плащ': 'Плащ',
    'костюм': 'Костюм',
    'комплект': 'Комплект',
    'спортивн': 'Спорт костюмі',
    'сумк': 'Сөмке',
    'шарф': 'Шарф',
    'шапк': 'Бас киім',
    'кепк': 'Кепка',
    'очк': 'Көзілдірік',
    'украшен': 'Әшекей',
    'ремен': 'Белбеу',
    'майк': 'Майка',
    'водолаз': 'Водолазка',
    'лонгслив': 'Лонгслив',
    'поло': 'Поло',
    'бомбер': 'Бомбер',
    'ветровк': 'Желкен',
    'дубленк': 'Тон пальто',
    'шуб': 'Мех жакет',
    'мокасин': 'Мокасин',
    'босонож': 'Сандал',
    'угг': 'Угги',
    'тапк': 'Тапочка',
    'галош': 'Галоша',
    'колгот': 'Колготки',
    'чулк': 'Шұлық',
    'носк': 'Шұлық',
    'перчат': 'Қолғап',
    'пижам': 'Пижама',
    'купальник': 'Жүзу киімі',
    'бикини': 'Бикини',
    'шорты': 'Шорт',
    'жакет': 'Жакет',
    'тренч': 'Тренч',
    'парк': 'Парка',
    'анорак': 'Анорак',
    'бейсбол': 'Бейсболка',
    'бейсболк': 'Бейсболка',
    'берет': 'Берет',
    'панам': 'Панама',
    'клатч': 'Клатч',
    'рюкзак': 'Рюкзак',
    'кошел': 'Әмиян',
    'брелок': 'Брелок',
    'серьг': 'Сырға',
    'колье': 'Мойынбау',
    'браслет': 'Білезік',
    'часы': 'Сағат',
    'пояс': 'Белбеу',
    'галстук': 'Галстук',
    'бабочк': 'Көбелек',
    'жилетк': 'Жилет',
    'комбинезон': 'Комбинезон',
    'боди': 'Боди',
    'корсет': 'Корсет',
    'туник': 'Туника',
    'кимоно': 'Кимоно',
    'накидк': 'Жамылғы',
    'пончо': 'Пончо',
    'косух': 'Косуха',
    'дутк': 'Пуховик',
    'уг': 'Угги',
    'футболка': 'Футболка',
    'рубашка': 'Жейде',
    'блузка': 'Блузка',
    'кроссовки': 'Кроссовка',
    'кроссовка': 'Кроссовка',
    'кеды': 'Кед',
    'джинсы': 'Джинс',
    'брюки': 'Шалбар',
    'юбка': 'Юбка',
    'платье': 'Көйлек',
    'куртка': 'Куртка',
    'пальто': 'Пальто',
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
    r'джинсов[а-яё]*': 'Denim',
    r'шёлков[а-яё]*': 'Silk',
    r'шелков[а-яё]*': 'Silk',
    r'хлопков[а-яё]*': 'Cotton',
    r'шерстян[а-яё]*': 'Wool',
    r'вельветов[а-яё]*': 'Corduroy',
    r'атласн[а-яё]*': 'Satin',
    r'кружевн[а-яё]*': 'Lace',
    r'стёган[а-яё]*': 'Quilted',
    r'стеган[а-яё]*': 'Quilted',
    r'укороченн[а-яё]*': 'Cropped',
    r'удлинённ[а-яё]*': 'Longline',
    r'удлиненн[а-яё]*': 'Longline',
    r'мини': 'Mini',
    r'макси': 'Maxi',
    r'миди': 'Midi',
    r'футболк[а-яё]*': 'T-shirt',
    r'рубашк[а-яё]*': 'Shirt',
    r'блузк[а-яё]*': 'Blouse',
    r'кроссовк[а-яё]*': 'Sneakers',
    r'джинс[а-яё]*': 'Jeans',
    r'брюк[а-яё]*': 'Trousers',
    r'юбк[а-яё]*': 'Skirt',
    r'плать[а-яё]*': 'Dress',
    r'куртк[а-яё]*': 'Jacket',
    r'пальт[а-яё]*': 'Coat',
    r'свитшот[а-яё]*': 'Sweatshirt',
    r'худи': 'Hoodie',
    r'майк[а-яё]*': 'Tank top',
    r'водолазк[а-яё]*': 'Turtleneck',
    r'лонгслив[а-яё]*': 'Long sleeve',
    r'бомбер[а-яё]*': 'Bomber jacket',
    r'ветровк[а-яё]*': 'Windbreaker',
    r'мокасин[а-яё]*': 'Loafers',
    r'сапог[а-яё]*': 'Boots',
    r'ботинк[а-яё]*': 'Boots',
    r'туфл[а-яё]*': 'Heels',
    r'сандал[а-яё]*': 'Sandals',
    r'шорт[а-яё]*': 'Shorts',
    r'леггинс[а-яё]*': 'Leggings',
    r'сумк[а-яё]*': 'Bag',
    r'рюкзак[а-яё]*': 'Backpack',
    r'шарф[а-яё]*': 'Scarf',
    r'шапк[а-яё]*': 'Hat',
    r'кепк[а-яё]*': 'Cap',
    r'очк[а-яё]*': 'Glasses',
    r'ремен[а-яё]*': 'Belt',
    r'пиджак[а-яё]*': 'Blazer',
    r'пуховик[а-яё]*': 'Puffer jacket',
    r'кардиган[а-яё]*': 'Cardigan',
    r'жилет[а-яё]*': 'Vest',
    r'свитер[а-яё]*': 'Sweater',
    r'кофт[а-яё]*': 'Knit top',
    r'топ[а-яё]*': 'Top',
  };

  static const _titleWordKk = {
    r'бел[а-яё]*': 'Ақ',
    r'ч[её]рн[а-яё]*': 'Қара',
    r'син[а-яё]*': 'Көк',
    r'голуб[а-яё]*': 'Ашық көк',
    r'красн[а-яё]*': 'Қызыл',
    r'розов[а-яё]*': 'Қызғылт',
    r'бежев[а-яё]*': 'Беж',
    r'сер[а-яё]*': 'Сұр',
    r'зел[её]н[а-яё]*': 'Жасыл',
    r'ж[её]лт[а-яё]*': 'Сары',
    r'фиолетов[а-яё]*': 'Күлгін',
    r'коричнев[а-яё]*': 'Қоңыр',
    r'кожан[а-яё]*': 'Тері',
    r'вязан[а-яё]*': 'Тоқылған',
    r'оверсайз': 'Oversize',
    r'классическ[а-яё]*': 'Классикалық',
    r'спортивн[а-яё]*': 'Спорттық',
    r'повседневн[а-яё]*': 'Күнделікті',
    r'джинсов[а-яё]*': 'Деним',
    r'шёлков[а-яё]*': 'Жібек',
    r'шелков[а-яё]*': 'Жібек',
    r'хлопков[а-яё]*': 'Бақыл',
    r'шерстян[а-яё]*': 'Жүн',
    r'укороченн[а-яё]*': 'Қысқа',
    r'удлинённ[а-яё]*': 'Ұзын',
    r'удлиненн[а-яё]*': 'Ұзын',
    r'футболк[а-яё]*': 'Футболка',
    r'рубашк[а-яё]*': 'Жейде',
    r'блузк[а-яё]*': 'Блузка',
    r'кроссовк[а-яё]*': 'Кроссовка',
    r'кед[а-яё]*': 'Кед',
    r'джинс[а-яё]*': 'Джинс',
    r'брюк[а-яё]*': 'Шалбар',
    r'штаны': 'Шалбар',
    r'юбк[а-яё]*': 'Юбка',
    r'плать[а-яё]*': 'Көйлек',
    r'куртк[а-яё]*': 'Куртка',
    r'пальт[а-яё]*': 'Пальто',
    r'свитшот[а-яё]*': 'Свитшот',
    r'худи': 'Худи',
    r'майк[а-яё]*': 'Майка',
    r'водолазк[а-яё]*': 'Водолазка',
    r'лонгслив[а-яё]*': 'Лонгслив',
    r'бомбер[а-яё]*': 'Бомбер',
    r'ветровк[а-яё]*': 'Желкен',
    r'мокасин[а-яё]*': 'Мокасин',
    r'сапог[а-яё]*': 'Етік',
    r'ботинк[а-яё]*': 'Етік',
    r'туфл[а-яё]*': 'Туфли',
    r'сандал[а-яё]*': 'Сандал',
    r'шорт[а-яё]*': 'Шорт',
    r'леггинс[а-яё]*': 'Леггинс',
    r'сумк[а-яё]*': 'Сөмке',
    r'рюкзак[а-яё]*': 'Рюкзак',
    r'шарф[а-яё]*': 'Шарф',
    r'шапк[а-яё]*': 'Бас киім',
    r'кепк[а-яё]*': 'Кепка',
    r'очк[а-яё]*': 'Көзілдірік',
    r'ремен[а-яё]*': 'Белбеу',
    r'пиджак[а-яё]*': 'Пиджак',
    r'пуховик[а-яё]*': 'Пуховик',
    r'кардиган[а-яё]*': 'Кардиган',
    r'жилет[а-яё]*': 'Жилет',
    r'свитер[а-яё]*': 'Свитер',
    r'кофт[а-яё]*': 'Свитер',
    r'топ[а-яё]*': 'Топ',
    r'сарафан[а-яё]*': 'Сарафан',
    r'комплект[а-яё]*': 'Комплект',
    r'костюм[а-яё]*': 'Костюм',
    r'пижам[а-яё]*': 'Пижама',
    r'купальник[а-яё]*': 'Жүзу киімі',
    r'перчат[а-яё]*': 'Қолғап',
    r'серьг[а-яё]*': 'Сырға',
    r'колье': 'Мойынбау',
    r'браслет[а-яё]*': 'Білезік',
    r'часы': 'Сағат',
    r'галстук[а-яё]*': 'Галстук',
    r'пончо': 'Пончо',
    r'туник[а-яё]*': 'Туника',
    r'комбинезон[а-яё]*': 'Комбинезон',
    r'боди': 'Боди',
    r'корсет[а-яё]*': 'Корсет',
    r'кимоно': 'Кимоно',
    r'накидк[а-яё]*': 'Жамылғы',
    r'косух[а-яё]*': 'Косуха',
    r'тренч[а-яё]*': 'Тренч',
    r'парк[а-яё]*': 'Парка',
    r'анорак[а-яё]*': 'Анорак',
    r'поло': 'Поло',
    r'босонож[а-яё]*': 'Сандал',
    r'шлёп[а-яё]*': 'Шлёпан',
    r'шлеп[а-яё]*': 'Шлёпан',
    r'угг[а-яё]*': 'Угги',
    r'колгот[а-яё]*': 'Колготки',
    r'носк[а-яё]*': 'Шұлық',
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

  static const _colorKk = {
    'бел': 'Ақ',
    'чёрн': 'Қара',
    'черн': 'Қара',
    'син': 'Көк',
    'голуб': 'Ашық көк',
    'красн': 'Қызыл',
    'розов': 'Қызғылт',
    'беж': 'Беж',
    'сер': 'Сұр',
    'зел': 'Жасыл',
    'жёлт': 'Сары',
    'желт': 'Сары',
    'фиолет': 'Күлгін',
    'корич': 'Қоңыр',
    'хаки': 'Хаки',
    'пудр': 'Пудра',
    'карамел': 'Карамель',
  };

  static const _vibeKk = {
    'минимализм': 'Минимализм',
    'романтичный': 'Романтик',
    'дерзкий': 'Батыл',
    'уютный': 'Ыңғайлы',
    'элегантный': 'Сәнді',
    'игривый': 'Ойыншы',
  };

  static const _vibeEn = {
    'минимализм': 'Minimalism',
    'романтичный': 'Romantic',
    'дерзкий': 'Bold',
    'уютный': 'Cozy',
    'элегантный': 'Elegant',
    'игривый': 'Playful',
  };

  static const _fitRu = {
    'oversized': 'оверсайз',
    'slim': 'облегающий',
    'relaxed': 'свободный',
    'regular': 'стандартный',
  };

  static const _fitKk = {
    'oversized': 'oversize',
    'slim': 'тар',
    'relaxed': 'бос',
    'regular': 'стандартты',
  };

  static const _colorEnglishEn = {
    'light blue': 'Light blue',
    'white': 'White',
    'black': 'Black',
    'blue': 'Blue',
    'red': 'Red',
    'pink': 'Pink',
    'beige': 'Beige',
    'gray': 'Gray',
    'grey': 'Gray',
    'green': 'Green',
    'yellow': 'Yellow',
    'purple': 'Purple',
    'brown': 'Brown',
    'khaki': 'Khaki',
  };

  static const _colorEnglishKk = {
    'light blue': 'Ашық көк',
    'white': 'Ақ',
    'black': 'Қара',
    'blue': 'Көк',
    'red': 'Қызыл',
    'pink': 'Қызғылт',
    'beige': 'Беж',
    'gray': 'Сұр',
    'grey': 'Сұр',
    'green': 'Жасыл',
    'yellow': 'Сары',
    'purple': 'Күлгін',
    'brown': 'Қоңыр',
    'khaki': 'Хаки',
  };

  /// English vision titles → Russian stem keys in [_garmentEn] / [_garmentKk].
  static const _englishGarmentStems = {
    'tracksuit': 'спортивн',
    'sweatshirt': 'свитшот',
    'turtleneck': 'водолаз',
    'long sleeve': 'лонгслив',
    'long-sleeve': 'лонгслив',
    't-shirt': 'футболк',
    'tee shirt': 'футболк',
    'polo shirt': 'поло',
    'tank top': 'майк',
    'puffer jacket': 'пуховик',
    'bomber jacket': 'бомбер',
    'windbreaker': 'ветровк',
    'trench coat': 'тренч',
    'biker jacket': 'косух',
    'leather jacket': 'куртк',
    'baseball cap': 'бейсболк',
    'bucket hat': 'панам',
    'bow tie': 'бабочк',
    'co-ord set': 'комплект',
    'coord set': 'комплект',
    'matching set': 'комплект',
    'sneakers': 'кроссовк',
    'trainers': 'кроссовк',
    'loafers': 'лофер',
    'sandals': 'сандал',
    'heels': 'туфл',
    'boots': 'ботинк',
    'slippers': 'тапк',
    'hoodie': 'худи',
    'cardigan': 'кардиган',
    'sweater': 'свитер',
    'blouse': 'блуз',
    'jumpsuit': 'комбинезон',
    'bodysuit': 'боди',
    'leggings': 'леггинс',
    'sundress': 'сарафан',
    'backpack': 'рюкзак',
    'sneaker': 'кроссовк',
    'jeans': 'джинс',
    'shirt': 'рубашк',
    'shorts': 'шорт',
    'skirt': 'юбк',
    'dress': 'плать',
    'jacket': 'куртк',
    'coat': 'пальт',
    'blazer': 'пиджак',
    'pants': 'штаны',
    'trousers': 'брюк',
    'top': 'топ',
    'vest': 'жилет',
    'scarf': 'шарф',
    'hat': 'шапк',
    'cap': 'кепк',
    'bag': 'сумк',
    'belt': 'ремен',
    'glasses': 'очк',
    'watch': 'часы',
    'suit': 'костюм',
    'parka': 'парк',
    'anorak': 'анорак',
    'corset': 'корсет',
    'tunic': 'туник',
    'kimono': 'кимоно',
    'poncho': 'пончо',
    'bikini': 'бикини',
    'swimsuit': 'купальник',
    'pajamas': 'пижам',
    'pajama': 'пижам',
    'socks': 'носк',
    'tights': 'колгот',
    'gloves': 'перчат',
    'earrings': 'серьг',
    'necklace': 'колье',
    'bracelet': 'браслет',
    'tie': 'галстук',
    'clutch': 'клатч',
    'wallet': 'кошел',
    'uggs': 'угг',
    'tee': 'футболк',
    'polo': 'поло',
    'denim': 'джинс',
  };
}
