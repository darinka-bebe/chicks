import '../../data/models/wardrobe_item.dart';
import '../models/wardrobe_analysis_snapshot.dart';
import '../models/wardrobe_insight.dart';
import '../models/wardrobe_outfit_slot.dart';
import 'wardrobe_slot_classifier.dart';

/// Rule-based wardrobe balance and gap analysis (no image / Vision).
abstract final class WardrobeAnalyzer {
  static const _analysisSlots = [
    WardrobeOutfitSlot.top,
    WardrobeOutfitSlot.bottom,
    WardrobeOutfitSlot.dress,
    WardrobeOutfitSlot.outerwear,
    WardrobeOutfitSlot.shoes,
    WardrobeOutfitSlot.accessory,
  ];

  static const _essentialSlots = [
    WardrobeOutfitSlot.top,
    WardrobeOutfitSlot.bottom,
    WardrobeOutfitSlot.shoes,
  ];

  static WardrobeAnalysisSnapshot analyze(List<WardrobeItem> items) {
    if (items.isEmpty) {
      return const WardrobeAnalysisSnapshot(
        totalItems: 0,
        slotCounts: {},
        colorCounts: {},
        styleCounts: {},
        neutralItemCount: 0,
        darkToneCount: 0,
        formalItemCount: 0,
        hoodieLikeCount: 0,
        mostUsedSlot: null,
        mostRepeatedColor: null,
        mostVersatileItem: null,
        missingSlots: [],
        overloadedSlots: [],
      );
    }

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
      if (title.contains('худи') || title.contains('hoodie')) hoodieCount++;

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

    for (final slot in _analysisSlots) {
      final count = slotCounts[slot] ?? 0;
      if (count == 0 && _isSlotExpected(slot, total)) {
        missing.add(slot);
      }
      if (total >= 6 && count >= 4 && count / total >= 0.38) {
        overloaded.add(slot);
      }
    }

    if (!_hasBottomCoverage(slotCounts) && total >= 3) {
      if (!missing.contains(WardrobeOutfitSlot.bottom)) {
        missing.add(WardrobeOutfitSlot.bottom);
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
    );
  }

  static List<WardrobeInsight> buildInsights(WardrobeAnalysisSnapshot snapshot) {
    if (snapshot.totalItems == 0) {
      return const [
        WardrobeInsight(
          id: 'empty',
          title: 'Гардероб пуст',
          body:
              'Добавь несколько базовых вещей — верх, низ и обувь — '
              'и я смогу подсказать, чего не хватает для сбалансированных образов.',
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

    if (snapshot.countFor(WardrobeOutfitSlot.shoes) <= 1 &&
        snapshot.totalItems >= 5) {
      insights.add(
        WardrobeInsight(
          id: nextId('gap'),
          title: 'Мало обуви для разных образов',
          body:
              'С одной-двумя парами сложно менять настроение лука. '
              'Подумай о повседневной паре и чуть более нарядной — так гардероб станет гибче.',
          kind: WardrobeInsightKind.gap,
        ),
      );
    }

    if (snapshot.hoodieLikeCount >= 3 &&
        snapshot.countFor(WardrobeOutfitSlot.shoes) <
            snapshot.hoodieLikeCount) {
      insights.add(
        WardrobeInsight(
          id: nextId('balance'),
          title: 'Много похожих верхов',
          body:
              'Похоже, у тебя несколько худи или свитшотов, а обуви и аксессуаров меньше. '
              'Добавь базовую обувь или один акцент — образы сразу станут разнообразнее.',
          kind: WardrobeInsightKind.balance,
        ),
      );
    }

    for (final slot in snapshot.overloadedSlots) {
      if (slot == WardrobeOutfitSlot.top &&
          snapshot.hoodieLikeCount >= 3) {
        continue;
      }
      insights.add(
        WardrobeInsight(
          id: nextId('balance'),
          title: 'Перекос по категории',
          body:
              'В категории «${_slotLabelRu(slot)}» уже ${snapshot.countFor(slot)} '
              'из ${snapshot.totalItems} вещей. Попробуй усилить слабые слоты — '
              'низ, обувь или аксессуары — для баланса.',
          kind: WardrobeInsightKind.balance,
        ),
      );
    }

    final neutralBottoms = snapshot.neutralItemCount;
    if (snapshot.countFor(WardrobeOutfitSlot.bottom) > 0 &&
        neutralBottoms < 2 &&
        snapshot.totalItems >= 5) {
      insights.add(
        WardrobeInsight(
          id: nextId('gap'),
          title: 'Мало базовых нейтральных вещей',
          body:
              'Нейтральный низ или верх (беж, серый, джинс, белый) '
              'связывает образы. Сейчас их мало — это усложняет комбинации.',
          kind: WardrobeInsightKind.gap,
        ),
      );
    }

    if (snapshot.darkToneCount >= (snapshot.totalItems * 0.55).ceil() &&
        snapshot.totalItems >= 4) {
      insights.add(
        WardrobeInsight(
          id: nextId('color'),
          title: 'Преобладают тёмные тона',
          body:
              'Большая часть гардероба в тёмной гамме. Добавь светлый верх '
              'или акцентный аксессуар — контраст оживит повседневные луки.',
          kind: WardrobeInsightKind.color,
        ),
      );
    }

    if (snapshot.formalItemCount == 0 && snapshot.totalItems >= 6) {
      insights.add(
        WardrobeInsight(
          id: nextId('style'),
          title: 'Мало нарядных / formal-вариантов',
          body:
              'Почти нет вещей для офиса, свидания или события. '
              'Один более собранный верх или платье расширят сценарии образов.',
          kind: WardrobeInsightKind.style,
        ),
      );
    }

    final repeatedStyle = _mostRepeatedStyle(snapshot.styleCounts);
    if (repeatedStyle != null && repeatedStyle.value >= 4) {
      insights.add(
        WardrobeInsight(
          id: nextId('style'),
          title: 'Повторяется один стиль',
          body:
              'Стиль «${repeatedStyle.key}» встречается часто. '
              'Попробуй 1–2 вещи в другом направлении — образы перестанут выглядеть однообразно.',
          kind: WardrobeInsightKind.style,
        ),
      );
    }

    if (snapshot.mostUsedSlot != null) {
      insights.add(
        WardrobeInsight(
          id: nextId('highlight'),
          title: 'Самая заполненная категория',
          body:
              'Больше всего вещей в категории «${_slotLabelRu(snapshot.mostUsedSlot!)}» '
              '(${snapshot.countFor(snapshot.mostUsedSlot!)} шт.). '
              'Имеет смысл развивать слабые слоты, а не только эту группу.',
          kind: WardrobeInsightKind.highlight,
        ),
      );
    }

    if (snapshot.mostRepeatedColor != null &&
        (snapshot.colorCounts[snapshot.mostRepeatedColor!] ?? 0) >= 3) {
      final c = snapshot.mostRepeatedColor!;
      final n = snapshot.colorCounts[c]!;
      insights.add(
        WardrobeInsight(
          id: nextId('highlight'),
          title: 'Самый частый цвет',
          body:
              'Оттенок «$c» встречается $n раз. '
              'Добавь контрастный или нейтральный акцент — комбинации станут свежее.',
          kind: WardrobeInsightKind.highlight,
        ),
      );
    }

    final versatile = snapshot.mostVersatileItem;
    if (versatile != null && snapshot.totalItems >= 4) {
      insights.add(
        WardrobeInsight(
          id: nextId('highlight'),
          title: 'Самая универсальная вещь',
          body:
              '«${versatile.title}» — сильный базовый элемент: '
              'её проще всего встроить в разные образы. Строй луки вокруг неё.',
          kind: WardrobeInsightKind.highlight,
        ),
      );
    }

    if (insights.length < 3) {
      insights.add(
        WardrobeInsight(
          id: nextId('tip'),
          title: 'Гардероб в хорошей форме',
          body:
              'Баланс категорий выглядит неплохо. Продолжай добавлять базу '
              'и 1–2 акцента под разные поводы — стилист подберёт образы точнее.',
          kind: WardrobeInsightKind.tip,
        ),
      );
    }

    return insights.take(8).toList();
  }

  static bool _hasBottomCoverage(Map<WardrobeOutfitSlot, int> counts) {
    return (counts[WardrobeOutfitSlot.bottom] ?? 0) > 0 ||
        (counts[WardrobeOutfitSlot.dress] ?? 0) > 0;
  }

  static bool _isSlotExpected(WardrobeOutfitSlot slot, int total) {
    if (total < 4) return false;
    return _essentialSlots.contains(slot) ||
        slot == WardrobeOutfitSlot.outerwear ||
        slot == WardrobeOutfitSlot.accessory;
  }

  static String _normalizeColor(String raw) {
    final c = raw.trim().toLowerCase();
    if (c.isEmpty) return 'не указан';
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
        text.contains('бордо');
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

  static String _slotLabelRu(WardrobeOutfitSlot slot) => switch (slot) {
        WardrobeOutfitSlot.top => 'верх',
        WardrobeOutfitSlot.bottom => 'низ',
        WardrobeOutfitSlot.dress => 'платья',
        WardrobeOutfitSlot.outerwear => 'верхняя одежда',
        WardrobeOutfitSlot.shoes => 'обувь',
        WardrobeOutfitSlot.accessory => 'аксессуары',
        WardrobeOutfitSlot.unknown => 'прочее',
      };

  static String _missingTitle(WardrobeOutfitSlot slot) => switch (slot) {
        WardrobeOutfitSlot.bottom =>
          'Не хватает базового низа',
        WardrobeOutfitSlot.shoes => 'Мало обуви',
        WardrobeOutfitSlot.outerwear => 'Нет верхней одежды',
        WardrobeOutfitSlot.accessory => 'Почти нет аксессуаров',
        WardrobeOutfitSlot.top => 'Мало верхов',
        WardrobeOutfitSlot.dress => 'Нет платьев',
        WardrobeOutfitSlot.unknown => 'Пробел в гардеробе',
      };

  static String _missingBody(
    WardrobeOutfitSlot slot,
    WardrobeAnalysisSnapshot snapshot,
  ) =>
      switch (slot) {
        WardrobeOutfitSlot.bottom =>
          'Без низа или платья сложно собирать цельные образы. '
          'Добавь нейтральные джинсы, брюки или юбку — это быстро расширит комбинации.',
        WardrobeOutfitSlot.shoes =>
          'Обувь задаёт тон всему луку. Хотя бы одна повседневная '
          'и одна чуть наряднее пара сильно увеличат вариативность.',
        WardrobeOutfitSlot.outerwear =>
          'Куртка, пальто или жакет пригодятся в прохладную погоду '
          'и добавят завершённость образу.',
        WardrobeOutfitSlot.accessory =>
          'Сумка, ремень или украшение часто «собирают» образ. '
          'Один универсальный аксессуар даст много новых сочетаний.',
        WardrobeOutfitSlot.top =>
          'Сейчас мало верхов — добавь базовую футболку, рубашку или свитер.',
        WardrobeOutfitSlot.dress =>
          'Платье — готовый образ в одной вещи; одно базовое платье '
          'расширит гардероб без лишних комбинаций.',
        WardrobeOutfitSlot.unknown =>
          'В гардеробе есть нераспределённые вещи — проверь категории при добавлении.',
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
  ];
}
