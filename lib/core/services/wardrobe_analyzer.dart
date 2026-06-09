import '../../data/models/wardrobe_item.dart';
import '../constants/wardrobe_catalog.dart';
import '../localization/app_locale.dart';
import '../localization/locale_tri.dart';
import '../models/wardrobe_analysis_snapshot.dart';
import '../models/wardrobe_inventory_profile.dart';
import '../models/wardrobe_insight.dart';
import '../models/wardrobe_outfit_slot.dart';
import 'wardrobe_slot_classifier.dart';

/// Rule-based wardrobe balance and gap analysis (no image / Vision).
abstract final class WardrobeAnalyzer {
  static String _l(String ru, String en) => AppLocale.pick(ru: ru, en: en);

  static const _analysisSlots = [
    WardrobeOutfitSlot.top,
    WardrobeOutfitSlot.bottom,
    WardrobeOutfitSlot.dress,
    WardrobeOutfitSlot.set,
    WardrobeOutfitSlot.outerwear,
    WardrobeOutfitSlot.shoes,
    WardrobeOutfitSlot.accessory,
  ];

  static WardrobeAnalysisSnapshot analyze(List<WardrobeItem> items) {
    if (items.isEmpty) {
      return WardrobeAnalysisSnapshot(
        totalItems: 0,
        slotCounts: const {},
        colorCounts: const {},
        styleCounts: const {},
        neutralItemCount: 0,
        darkToneCount: 0,
        formalItemCount: 0,
        hoodieLikeCount: 0,
        mostUsedSlot: null,
        mostRepeatedColor: null,
        mostVersatileItem: null,
        missingSlots: const [],
        overloadedSlots: const [],
        inventory: WardrobeInventoryProfile.fromItems(const []),
      );
    }

    final inventory = WardrobeInventoryProfile.fromItems(items);

    final slotCounts = <WardrobeOutfitSlot, int>{};
    final colorCounts = <String, int>{};
    final styleCounts = <String, int>{};
    var neutralCount = 0;
    var darkCount = 0;
    var formalCount = 0;
    var hoodieCount = 0;

    WardrobeItem? versatileBest;
    var versatileScore = -1.0;

    for (final item in items) {
      final slot = WardrobeSlotClassifier.classify(item);
      slotCounts[slot] = (slotCounts[slot] ?? 0) + 1;

      final colorKey = _normalizeColor(item.color);
      if (colorKey.isNotEmpty) {
        colorCounts[colorKey] = (colorCounts[colorKey] ?? 0) + 1;
      }

      if (_isNeutralColor(item)) neutralCount++;
      if (_isDarkTone(item)) darkCount++;
      if (_isFormalItem(item)) formalCount++;

      final title = item.title.toLowerCase();
      if (title.contains('худи') ||
          title.contains('hoodie') ||
          title.contains('свитшот') ||
          title.contains('sweatshirt')) {
        hoodieCount++;
      }

      for (final style in item.styles) {
        final key = style.trim().toLowerCase();
        if (key.isEmpty) continue;
        styleCounts[key] = (styleCounts[key] ?? 0) + 1;
      }

      final score = _versatilityScore(item);
      if (score > versatileScore) {
        versatileScore = score;
        versatileBest = item;
      }
    }

    final total = items.length;
    WardrobeOutfitSlot? mostUsed;
    var maxSlot = 0;
    for (final slot in _analysisSlots) {
      final c = slotCounts[slot] ?? 0;
      if (c > maxSlot) {
        maxSlot = c;
        mostUsed = slot;
      }
    }

    String? topColor;
    var topColorCount = 0;
    for (final entry in colorCounts.entries) {
      if (entry.value > topColorCount) {
        topColorCount = entry.value;
        topColor = entry.key;
      }
    }

    final missing = <WardrobeOutfitSlot>[];
    final overloaded = <WardrobeOutfitSlot>[];

    if (total >= 4) {
      if (!inventory.hasTop) {
        missing.add(WardrobeOutfitSlot.top);
      }
      if (!inventory.hasBottomCoverage) {
        missing.add(WardrobeOutfitSlot.bottom);
      }
      if (!inventory.hasShoes) {
        missing.add(WardrobeOutfitSlot.shoes);
      }
    }

    for (final slot in _analysisSlots) {
      final count = slotCounts[slot] ?? 0;
      if (total >= 6 && count >= 4 && count / total >= 0.38) {
        overloaded.add(slot);
      }
    }

    return WardrobeAnalysisSnapshot(
      totalItems: total,
      slotCounts: slotCounts,
      colorCounts: colorCounts,
      styleCounts: styleCounts,
      neutralItemCount: neutralCount,
      darkToneCount: darkCount,
      formalItemCount: formalCount,
      hoodieLikeCount: hoodieCount,
      mostUsedSlot: mostUsed,
      mostRepeatedColor: topColor,
      mostVersatileItem: versatileBest,
      missingSlots: missing,
      overloadedSlots: overloaded,
      inventory: inventory,
    );
  }

  static List<WardrobeInsight> buildInsights(WardrobeAnalysisSnapshot snapshot) {
    if (snapshot.totalItems == 0) {
      return [
        WardrobeInsight(
          id: 'empty',
          title: _l('Гардероб пуст', 'Wardrobe is empty'),
          body: _l(
            'Добавь несколько базовых вещей — верх, низ и обувь — '
            'и я смогу подсказать, чего не хватает для сбалансированных образов.',
            'Add a few basics — top, bottom, and shoes — '
            'and I can point out what is missing for balanced outfits.',
          ),
          kind: WardrobeInsightKind.tip,
        ),
      ];
    }

    final insights = <WardrobeInsight>[];
    var id = 0;
    String nextId(String prefix) => '${prefix}_${id++}';

    for (final slot in snapshot.missingSlots) {
      insights.add(
        WardrobeInsight(
          id: nextId('gap'),
          title: _missingTitle(slot),
          body: _missingBody(slot, snapshot),
          kind: WardrobeInsightKind.gap,
        ),
      );
    }

    final inv = snapshot.inventory;
    final shoesCount = snapshot.countFor(WardrobeOutfitSlot.shoes);

    if (shoesCount == 1 &&
        snapshot.totalItems >= 8 &&
        !inv.hasCasualShoes &&
        !inv.hasDressyShoes) {
      insights.add(
        WardrobeInsight(
          id: nextId('gap'),
          title: _l(
            'Мало обуви для разных образов',
            'Not enough shoes for different looks',
          ),
          body: _l(
            'С одной парой сложно менять настроение лука. '
            'Вторая пара в другом стиле сделает комбинации гибче.',
            'With only one pair it is hard to change the mood of a look. '
            'A second pair in a different style will make outfits more flexible.',
          ),
          kind: WardrobeInsightKind.gap,
        ),
      );
    } else if (shoesCount == 1 &&
        snapshot.totalItems >= 8 &&
        inv.hasCasualShoes &&
        !inv.hasDressyShoes) {
      insights.add(
        WardrobeInsight(
          id: nextId('gap'),
          title: _l(
            'Нет более нарядной обуви',
            'No dressier shoes yet',
          ),
          body: _l(
            'Повседневная обувь уже есть — для свиданий и событий пригодится '
            'пара чуть наряднее (лоферы, ботинки или туфли).',
            'You already have casual shoes — for dates and events, '
            'a slightly dressier pair (loafers, boots, or heels) would help.',
          ),
          kind: WardrobeInsightKind.gap,
        ),
      );
    }

    if (snapshot.hoodieLikeCount >= 3 &&
        shoesCount < 2 &&
        !inv.hasAccessory) {
      insights.add(
        WardrobeInsight(
          id: nextId('balance'),
          title: _l('Много похожих верхов', 'Many similar tops'),
          body: _l(
            'Несколько худи или свитшотов — а акцентов мало. '
            'Один яркий аксессуар разнообразит готовые комбинации без новых верхов.',
            'Several hoodies or sweatshirts — but few accents. '
            'One bold accessory will vary your combos without more tops.',
          ),
          kind: WardrobeInsightKind.balance,
        ),
      );
    }

    for (final slot in snapshot.overloadedSlots) {
      if (slot == WardrobeOutfitSlot.top &&
          snapshot.hoodieLikeCount >= 3) {
        continue;
      }
      final weak = _weakSlotLabels(inv);
      insights.add(
        WardrobeInsight(
          id: nextId('balance'),
          title: _l('Перекос по категории', 'Category imbalance'),
          body: _l(
            'В категории «${slot.displayNameLower}» уже ${snapshot.countFor(slot)} '
            'из ${snapshot.totalItems} вещей. Сейчас слабее: $weak.',
            'You already have ${snapshot.countFor(slot)} of ${snapshot.totalItems} items '
            'in «${slot.displayNameLower}». Weaker areas now: $weak.',



          ),
          kind: WardrobeInsightKind.balance,
        ),
      );
    }

    if (!inv.hasStrongNeutralBase && snapshot.totalItems >= 5) {
      insights.add(
        WardrobeInsight(
          id: nextId('gap'),
          title: _l(
            'Мало базовых нейтральных вещей',
            'Few basic neutral pieces',
          ),
          body: _missingNeutralBody(inv),
          kind: WardrobeInsightKind.gap,
        ),
      );
    }

    if (snapshot.darkToneCount >= (snapshot.totalItems * 0.55).ceil() &&
        snapshot.totalItems >= 4 &&
        !inv.hasLightAccent) {
      insights.add(
        WardrobeInsight(
          id: nextId('color'),
          title: _l('Преобладают тёмные тона', 'Dark tones dominate'),
          body: _l(
            'Большая часть гардероба в тёмной гамме. Добавь светлый верх '
            'или акцентный аксессуар — контраст оживит повседневные луки.',
            'Most of your wardrobe is in dark tones. Add a light top '
            'or a bold accessory — contrast will freshen everyday looks.',
          ),
          kind: WardrobeInsightKind.color,
        ),
      );
    }

    if (!inv.hasFormalPiece &&
        snapshot.formalItemCount == 0 &&
        snapshot.totalItems >= 8) {
      insights.add(
        WardrobeInsight(
          id: nextId('style'),
          title: _l(
            'Мало нарядных / formal-вариантов',
            'Few dressy / formal options',
          ),
          body: inv.hasDress
              ? _l(
                  'Почти нет вещей для офиса или события. '
                  'Один более собранный верх или жакет расширит поводы.',
                  'Little for office or events. '
                  'One polished top or blazer will open more occasions.',
                )
              : _l(
                  'Почти нет вещей для офиса, свидания или события. '
                  'Один более собранный верх или платье расширят сценарии образов.',
                  'Almost nothing for office, dates, or events. '
                  'One more polished top or dress will open up new outfit scenarios.',
                ),
          kind: WardrobeInsightKind.style,
        ),
      );
    }

    final repeatedStyle = _mostRepeatedStyle(snapshot.styleCounts);
    if (repeatedStyle != null && repeatedStyle.value >= 4) {
      insights.add(
        WardrobeInsight(
          id: nextId('style'),
          title: _l('Повторяется один стиль', 'One style repeats often'),
          body: _l(
            'Стиль «${repeatedStyle.key}» встречается часто. '
            'Попробуй 1–2 вещи в другом направлении — образы перестанут выглядеть однообразно.',
            'The «${repeatedStyle.key}» style shows up often. '
            'Try 1–2 pieces in a different direction — outfits will stop looking samey.',
          ),
          kind: WardrobeInsightKind.style,
        ),
      );
    }

    if (snapshot.mostUsedSlot != null) {
      insights.add(
        WardrobeInsight(
          id: nextId('highlight'),
          title: _l(
            'Самая заполненная категория',
            'Most filled category',
          ),
          body: _l(
            'Больше всего вещей в категории «${snapshot.mostUsedSlot!.displayNameLower}» '
            '(${snapshot.countFor(snapshot.mostUsedSlot!)} шт.). '
            'Имеет смысл развивать слабые слоты, а не только эту группу.',
            'Most items are in «${snapshot.mostUsedSlot!.displayNameLower}» '
            '(${snapshot.countFor(snapshot.mostUsedSlot!)} pcs). '
            'It makes sense to grow weaker slots, not only this group.',
          ),
          kind: WardrobeInsightKind.highlight,
        ),
      );
    }

    if (snapshot.mostRepeatedColor != null &&
        (snapshot.colorCounts[snapshot.mostRepeatedColor!] ?? 0) >= 3 &&
        !inv.hasLightAccent) {
      final c = snapshot.mostRepeatedColor!;
      final colorLabel = WardrobeCatalog.displayColor(c);
      final n = snapshot.colorCounts[c]!;
      insights.add(
        WardrobeInsight(
          id: nextId('highlight'),
          title: _l('Самый частый цвет', 'Most common color'),
          body: _l(
            'Оттенок «$colorLabel» встречается $n раз. '
            'Контрастный акцент из другой категории оживит готовые сочетания.',
            'The shade «$colorLabel» appears $n times. '
            'A contrasting accent from another category will freshen your combos.',
          ),
          kind: WardrobeInsightKind.highlight,
        ),
      );
    }

    final versatile = snapshot.mostVersatileItem;
    if (versatile != null && snapshot.totalItems >= 4) {
      insights.add(
        WardrobeInsight(
          id: nextId('highlight'),
          title: _l('Самая универсальная вещь', 'Most versatile item'),
          body: _l(
            '«${WardrobeCatalog.displayItemTitle(versatile)}» — сильный базовый элемент: '
            'её проще всего встроить в разные образы. Строй луки вокруг неё.',
            '«${WardrobeCatalog.displayItemTitle(versatile)}» is a strong base piece: '
            'it is the easiest to mix into different outfits. Build looks around it.',
          ),
          kind: WardrobeInsightKind.highlight,
        ),
      );
    }

    if (insights.length < 3) {
      insights.add(
        WardrobeInsight(
          id: nextId('tip'),
          title: _l('Гардероб в хорошей форме', 'Wardrobe looks balanced'),
          body: _l(
            'Баланс категорий выглядит неплохо. Продолжай добавлять базу '
            'и 1–2 акцента под разные поводы — стилист подберёт образы точнее.',
            'Category balance looks good. Keep adding basics '
            'and 1–2 accents for different occasions — the stylist will pick outfits more accurately.',
          ),
          kind: WardrobeInsightKind.tip,
        ),
      );
    }

    return _filterContradictory(insights, inv).take(8).toList();
  }

  static List<WardrobeInsight> filterContradictoryInsights(
    List<WardrobeInsight> insights,
    WardrobeInventoryProfile inventory,
  ) =>
      insights
          .where(
            (i) => !inventory.contradictsOwned('${i.title} ${i.body}'),
          )
          .toList();

  static List<WardrobeInsight> _filterContradictory(
    List<WardrobeInsight> insights,
    WardrobeInventoryProfile inventory,
  ) =>
      filterContradictoryInsights(insights, inventory);

  static String missingNeutralBody(WardrobeInventoryProfile inv) =>
      _missingNeutralBody(inv);

  static String _weakSlotLabels(WardrobeInventoryProfile inv) {
    final weak = <String>[];
    if (!inv.hasBottomCoverage) {
      weak.add(_l('низ', 'bottoms'));
    }
    if (!inv.hasShoes) {
      weak.add(_l('обувь', 'shoes'));
    }
    if (!inv.hasAccessory) {
      weak.add(_l('аксессуары', 'accessories'));
    }
    if (!inv.hasOuterwear) {
      weak.add(_l('верхняя одежда', 'outerwear'));
    }
    if (weak.isEmpty) {
      return _l('другие категории', 'other categories');
    }
    return weak.join(_l(', ', ', '));
  }

  static String _missingNeutralBody(WardrobeInventoryProfile inv) {
    if (!inv.hasNeutralTop && !inv.hasWhiteTop && !inv.hasNeutralBottom) {
      return LocaleTri.pick(
        ru: 'Не хватает связующих баз: нейтральный верх и универсальный низ '
            'упрощают ежедневные комбинации.',
        en: 'You are missing linking basics: a neutral top and versatile bottom '
            'make everyday combos easier.',
        kk: 'Негізгі базалар жетіспейді: нейтралды жоғғы және әмбебап төменгі '
            'күнделікті үйлесімдерді жеңілдетеді.',
      );
    }
    if (!inv.hasNeutralTop && !inv.hasWhiteTop) {
      return LocaleTri.pick(
        ru: 'Низ уже есть — добавь нейтральный верх (белый, беж, серый), '
            'чтобы быстрее собирать образы.',
        en: 'You already have bottoms — add a neutral top (white, beige, gray) '
            'to build looks faster.',
        kk: 'Төменгі киім бар — нейтралды жоғғы (ақ, беж, сұр) қосыңыз.',
      );
    }
    if (inv.hasJeans) {
      return LocaleTri.pick(
        ru: 'Верх есть — добавь универсальные брюки или юбку нейтрального оттенка.',
        en: 'You have tops — add versatile trousers or a neutral skirt.',
        kk: 'Жоғғы киім бар — әмбебап шалбар немесе бейтарап юбка қосыңыз.',
      );
    }
    return LocaleTri.pick(
      ru: 'Верх есть — не хватает универсального низа (брюки или юбка нейтрального оттенка).',
      en: 'You have tops — add a versatile bottom (trousers or a neutral skirt).',
      kk: 'Жоғғы киім бар — әмбебап төменгі киім (шалбар немесе юбка) жетіспейді.',
    );
  }

  static String _normalizeColor(String raw) {
    final c = raw.trim().toLowerCase();
    if (c.isEmpty) return _l('не указан', 'unspecified');
    return c.length > 24 ? '${c.substring(0, 24)}…' : c;
  }

  static bool _isNeutralColor(WardrobeItem item) {
    final text = '${item.color} ${item.title}'.toLowerCase();
    return _neutralKeywords.any(text.contains);
  }

  static bool _isDarkTone(WardrobeItem item) {
    final text = '${item.color} ${item.title}'.toLowerCase();
    return text.contains('чёрн') ||
        text.contains('черн') ||
        text.contains('тёмн') ||
        text.contains('темн') ||
        text.contains('уголь') ||
        text.contains('navy') ||
        text.contains('бордо') ||
        text.contains('black') ||
        text.contains('dark');
  }

  static bool _isFormalItem(WardrobeItem item) {
    final text =
        '${item.title} ${item.occasions.join(" ")} ${item.styles.join(" ")}'
            .toLowerCase();
    return text.contains('office') ||
        text.contains('офис') ||
        text.contains('date') ||
        text.contains('свидан') ||
        text.contains('party') ||
        text.contains('вечер') ||
        text.contains('делов');
  }

  static double _versatilityScore(WardrobeItem item) {
    var score = item.occasions.length * 2.0 + item.styles.length * 1.5;
    if (_isNeutralColor(item)) score += 2;
    if (item.season.toLowerCase().contains('всесезон')) score += 1;
    return score;
  }

  static MapEntry<String, int>? _mostRepeatedStyle(Map<String, int> styles) {
    if (styles.isEmpty) return null;
    return styles.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
  }

  static String _missingTitle(WardrobeOutfitSlot slot) => switch (slot) {
        WardrobeOutfitSlot.bottom => _l(
            'Не хватает базового низа',
            'Missing a basic bottom',
          ),
        WardrobeOutfitSlot.shoes => _l('Мало обуви', 'Not enough shoes'),
        WardrobeOutfitSlot.outerwear => _l(
            'Нет верхней одежды',
            'No outerwear',
          ),
        WardrobeOutfitSlot.accessory => _l(
            'Почти нет аксессуаров',
            'Almost no accessories',
          ),
        WardrobeOutfitSlot.top => _l('Мало верхов', 'Not enough tops'),
        WardrobeOutfitSlot.dress => _l('Нет платьев', 'No dresses'),
        WardrobeOutfitSlot.set => _l('Нет комплектов', 'No matching sets'),
        WardrobeOutfitSlot.unknown => _l(
            'Пробел в гардеробе',
            'Gap in your wardrobe',
          ),
      };

  static String _missingBody(
    WardrobeOutfitSlot slot,
    WardrobeAnalysisSnapshot snapshot,
  ) =>
      switch (slot) {
        WardrobeOutfitSlot.bottom => _l(
          'Без низа или платья сложно собирать цельные образы. '
          'Добавь нейтральные джинсы, брюки или юбку — это быстро расширит комбинации.',
          'Without a bottom or dress it is hard to build complete outfits. '
          'Add neutral jeans, trousers, or a skirt — that quickly expands combinations.',
        ),
        WardrobeOutfitSlot.shoes => _l(
          'Обувь задаёт тон всему луку. Хотя бы одна повседневная '
          'и одна чуть наряднее пара сильно увеличат вариативность.',
          'Shoes set the tone for the whole look. At least one casual '
          'and one slightly dressier pair will greatly increase variety.',
        ),
        WardrobeOutfitSlot.outerwear => _l(
          'Куртка, пальто или жакет пригодятся в прохладную погоду '
          'и добавят завершённость образу.',
          'A jacket, coat, or blazer helps in cool weather '
          'and adds polish to an outfit.',
        ),
        WardrobeOutfitSlot.accessory => _l(
          'Сумка, ремень или украшение часто «собирают» образ. '
          'Один универсальный аксессуар даст много новых сочетаний.',
          'A bag, belt, or jewelry often pulls a look together. '
          'One versatile accessory unlocks many new combinations.',
        ),
        WardrobeOutfitSlot.top => _l(
          'Сейчас мало верхов — добавь базовую футболку, рубашку или свитер.',
          'You have few tops right now — add a basic tee, shirt, or sweater.',
        ),
        WardrobeOutfitSlot.dress => _l(
          'Платье — готовый образ в одной вещи; одно базовое платье '
          'расширит гардероб без лишних комбинаций.',
          'A dress is a full outfit in one piece; one basic dress '
          'expands your wardrobe without extra mixing.',
        ),
        WardrobeOutfitSlot.set => _l(
          'Спортивный костюм или коорд-сет — готовая база; добавляй как '
          'один комплект, а не отдельно верх и низ.',
          'A tracksuit or co-ord set is a ready base; add it as '
          'one set, not separate top and bottom.',
        ),
        WardrobeOutfitSlot.unknown => _l(
          'В гардеробе есть нераспределённые вещи — проверь категории при добавлении.',
          'Some items are uncategorized — check categories when adding pieces.',
        ),
      };

  static const _neutralKeywords = [
    'беж',
    'бел',
    'сер',
    'черн',
    'чёрн',
    'джинс',
    'нейтрал',
    'крем',
    'экрю',
    'camel',
    'white',
    'gray',
    'grey',
    'beige',
    'denim',
    'cream',
    'neutral',
    'khaki',
    'navy',
    'black',
  ];
}
