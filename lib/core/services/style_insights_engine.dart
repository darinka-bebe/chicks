import '../../data/models/wardrobe_item.dart';
import '../models/body_profile.dart';
import '../models/seasonal_color_type.dart';
import '../models/stylist_defaults.dart';
import '../models/user_preferences_bundle.dart';
import '../models/wardrobe_analysis_snapshot.dart';
import '../models/wardrobe_insight.dart';
import '../models/wardrobe_outfit_slot.dart';
import 'wardrobe_analyzer.dart';

/// Local style analytics — wardrobe + color/body type + taste signals (no AI).
abstract final class StyleInsightsEngine {
  static List<WardrobeInsight> build({
    required List<WardrobeItem> items,
    required UserPreferencesBundle preferences,
    int favoritesCount = 0,
  }) {
    final snapshot = WardrobeAnalyzer.analyze(items);
  final fitCounts = _fitCounts(items);
    final categoryCounts = _categoryCounts(items);
    final vibes = _topVibes(items);

    if (snapshot.totalItems == 0) {
      return _emptyInsights(preferences);
    }

    final insights = <WardrobeInsight>[
      _dominantStyleInsight(snapshot, preferences.stylistDefaults, vibes),
      _colorPaletteInsight(snapshot, preferences.colorType),
      _wardrobeBalanceInsight(snapshot, categoryCounts),
      _silhouetteInsight(snapshot, fitCounts, preferences.bodyProfile),
      _aestheticInsight(preferences, vibes, snapshot),
      ..._recommendationInsight(snapshot, fitCounts, favoritesCount),
    ];

    return insights.where((i) => i.body.trim().isNotEmpty).toList();
  }

  static List<WardrobeInsight> _emptyInsights(UserPreferencesBundle prefs) {
    final colorHint = prefs.colorType != null
        ? ' Цветотип «${prefs.colorType!.displayNameRu}» уже задан — добавь вещи, и я подстрою советы.'
        : '';
    final bodyHint = prefs.bodyProfile != null
        ? ' Силуэт «${prefs.bodyProfile!.shape.displayNameRu}» учту в рекомендациях.'
        : '';

    return [
      WardrobeInsight(
        id: 'empty_style',
        title: 'Гардероб пока пуст',
        body:
            'Добавь несколько любимых вещей — я покажу доминирующий стиль, палитру и пробелы.$colorHint$bodyHint',
        kind: WardrobeInsightKind.tip,
      ),
    ];
  }

  static WardrobeInsight _dominantStyleInsight(
    WardrobeAnalysisSnapshot snapshot,
    StylistDefaults defaults,
    List<String> vibes,
  ) {
    final styleEntries = snapshot.styleCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topStyles = styleEntries.take(3).map((e) => e.key).toList();
    final moods = defaults.topMoods(limit: 2);

    final stylePart = topStyles.isNotEmpty
        ? 'В гардеробе чаще встречаются направления: ${_joinRu(topStyles)}.'
        : 'Стили пока не размечены — отметь mood при добавлении вещей.';

    final moodPart = moods.isNotEmpty
        ? ' В чате ты часто выбираешь настроение: ${_joinRu(moods)}.'
        : '';

    final vibePart = vibes.isNotEmpty ? ' Вайб: ${_joinRu(vibes)}.' : '';

    return WardrobeInsight(
      id: 'dominant_style',
      title: _dominantStyleTitle(topStyles, moods),
      body: '$stylePart$moodPart$vibePart'.trim(),
      kind: WardrobeInsightKind.style,
    );
  }

  static String _dominantStyleTitle(
    List<String> styles,
    List<String> moods,
  ) {
    if (styles.contains('casual') || moods.contains('comfy')) {
      return 'Casual и уютный стиль';
    }
    if (styles.contains('old money') || styles.contains('feminine')) {
      return 'Элегантный повседневный стиль';
    }
    if (styles.contains('sporty')) {
      return 'Спортивный и casual-мix';
    }
    if (styles.isNotEmpty) {
      return 'Доминирует ${_labelStyle(styles.first)}';
    }
    return 'Твой стиль формируется';
  }

  static WardrobeInsight _colorPaletteInsight(
    WardrobeAnalysisSnapshot snapshot,
    SeasonalColorType? colorType,
  ) {
    final neutralRatio = snapshot.neutralItemCount / snapshot.totalItems;
    final colorEntries = snapshot.colorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topColors = colorEntries.take(3).map((e) => e.key).toList();

    final palettePart = neutralRatio >= 0.45
        ? 'В гардеробе много нейтральных и тёплых базовых оттенков — это упрощает сочетания.'
        : topColors.isNotEmpty
            ? 'Чаще всего встречаются: ${_joinRu(topColors)}.'
            : 'Палитра пока разнообразная без явного лидера.';

    final darkPart = snapshot.darkToneCount >=
            (snapshot.totalItems * 0.5).ceil()
        ? ' Преобладают тёмные тона — добавь светлый акцент для контраста.'
        : '';

    final colorTypePart = colorType != null
        ? ' Цветотип «${colorType.displayNameRu}» — опирайся на его рекомендованную гамму.'
        : '';

    return WardrobeInsight(
      id: 'color_palette',
      title: neutralRatio >= 0.45
          ? 'Тёплые нейтралы в основе'
          : 'Твоя цветовая палитра',
      body: '$palettePart$darkPart$colorTypePart'.trim(),
      kind: WardrobeInsightKind.color,
    );
  }

  static WardrobeInsight _wardrobeBalanceInsight(
    WardrobeAnalysisSnapshot snapshot,
    Map<String, int> categoryCounts,
  ) {
    final topCategory = categoryCounts.entries.isEmpty
        ? null
        : categoryCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);

    if (snapshot.missingSlots.isNotEmpty) {
      final missing = snapshot.missingSlots
          .take(2)
          .map(_slotLabelRu)
          .join(' и ');
      return WardrobeInsight(
        id: 'balance_gap',
        title: 'Гардероб не сбалансирован',
        body:
            'Не хватает категорий: $missing. '
            'Сейчас ${snapshot.totalItems} вещей — усили слабые слоты, чтобы образы собирались легче.',
        kind: WardrobeInsightKind.balance,
      );
    }

    if (snapshot.overloadedSlots.isNotEmpty) {
      final slot = snapshot.overloadedSlots.first;
      return WardrobeInsight(
        id: 'balance_overload',
        title: 'Перекос по категориям',
        body:
            'Много вещей в категории «${_slotLabelRu(slot)}» '
            '(${snapshot.countFor(slot)} из ${snapshot.totalItems}). '
            'Разбавь другими слотами — низ, обувь или аксессуары.',
        kind: WardrobeInsightKind.balance,
      );
    }

    final catPart = topCategory != null
        ? ' Больше всего — «${topCategory.key}» (${topCategory.value} шт.).'
        : '';

    return WardrobeInsight(
      id: 'balance_ok',
      title: 'Сбалансированный гардероб',
      body:
          'Категории распределены ровно — можно смело комбинировать вещи без «дырок» в образе.$catPart',
      kind: WardrobeInsightKind.balance,
    );
  }

  static WardrobeInsight _silhouetteInsight(
    WardrobeAnalysisSnapshot snapshot,
    Map<String, int> fitCounts,
    BodyProfile? bodyProfile,
  ) {
    final dominantFit = _dominantFit(fitCounts);
    final oversized = fitCounts['oversized'] ?? 0;
    final fitted = (fitCounts['slim'] ?? 0) + (fitCounts['fitted'] ?? 0);

    var body = '';
    if (dominantFit == 'oversized' || oversized >= 2) {
      body =
          'Ты часто выбираешь oversize и свободную посадку — образы выглядят расслабленно и современно.';
    } else if (dominantFit == 'slim' || fitted >= 2) {
      body =
          'В гардеробе больше приталенных силуэтов — линия фигуры читается чётче.';
    } else {
      body =
          'Посадка в гардеробе сбалансирована: есть и свободные, и более структурные вещи.';
    }

    if (bodyProfile != null) {
      body +=
          ' Силуэт «${bodyProfile.shape.displayNameRu}»: ${bodyProfile.shape.shortDescriptionRu}';
      if (bodyProfile.prefersOversized) {
        body += ' Ты отмечала любовь к oversize — это совпадает с гардеробом.';
      }
    }

    return WardrobeInsight(
      id: 'silhouette',
      title: dominantFit == 'oversized'
          ? 'Свободные силуэты'
          : 'Твои силуэты',
      body: body.trim(),
      kind: WardrobeInsightKind.silhouette,
    );
  }

  static WardrobeInsight _aestheticInsight(
    UserPreferencesBundle preferences,
    List<String> vibes,
    WardrobeAnalysisSnapshot snapshot,
  ) {
    final moods = preferences.stylistDefaults.topMoods(limit: 3);
    final aesthetic = _inferAesthetic(moods, vibes, snapshot);

    return WardrobeInsight(
      id: 'aesthetic',
      title: 'Твоя эстетика',
      body: aesthetic,
      kind: WardrobeInsightKind.highlight,
    );
  }

  static List<WardrobeInsight> _recommendationInsight(
    WardrobeAnalysisSnapshot snapshot,
    Map<String, int> fitCounts,
    int favoritesCount,
  ) {
    final cards = <WardrobeInsight>[];

    if (snapshot.neutralItemCount < 2 && snapshot.totalItems >= 4) {
      cards.add(
        const WardrobeInsight(
          id: 'rec_basics',
          title: 'Не хватает базовых вещей',
          body:
              'Добавь нейтральный верх и универсальный низ (белая футболка, джинсы, бежевые брюки) — с ними образы собираются за минуту.',
          kind: WardrobeInsightKind.recommendation,
        ),
      );
    }

    if (snapshot.darkToneCount >= (snapshot.totalItems * 0.5).ceil() &&
        snapshot.totalItems >= 3) {
      cards.add(
        const WardrobeInsight(
          id: 'rec_dark_colors',
          title: 'Слишком много тёмных оттенков',
          body:
              'В гардеробе доминируют тёмные цвета — добавь светлый верх или акцент (беж, молочный, пастель), чтобы луки не выглядели тяжёлыми.',
          kind: WardrobeInsightKind.recommendation,
        ),
      );
    }

    if (snapshot.countFor(WardrobeOutfitSlot.shoes) == 0 &&
        snapshot.totalItems >= 3) {
      cards.add(
        const WardrobeInsight(
          id: 'rec_shoes',
          title: 'Мало обуви',
          body:
              'Добавь хотя бы одну пару базовой обуви (кроссовки или лоферы) — без неё образы в чате часто выглядят незавершёнными.',
          kind: WardrobeInsightKind.recommendation,
        ),
      );
    }

    final tips = <String>[];

    if (snapshot.neutralItemCount < 2 && snapshot.totalItems >= 4) {
      tips.add('Добавь нейтральные базы — белый верх, джинсы или бежевый низ.');
    }

    if (snapshot.countFor(WardrobeOutfitSlot.outerwear) == 0 &&
        snapshot.totalItems >= 5) {
      tips.add('Не хватает слоя — жакет, кардigan или trench оживят комбинации.');
    }

    if (snapshot.formalItemCount == 0 && snapshot.totalItems >= 6) {
      tips.add('Почти нет formal-вещей — одна более собранная позиция расширит поводы.');
    }

    final oversized = fitCounts['oversized'] ?? 0;
    final slim = (fitCounts['slim'] ?? 0) + (fitCounts['fitted'] ?? 0);
    if (oversized >= 2 && slim == 0) {
      tips.add('Попробуй контраст: oversize-верх + более структурный низ.');
    } else if (slim >= 2 && oversized == 0) {
      tips.add('Добавь один oversize-слой — образ станет актуальнее.');
    }

    if (snapshot.countFor(WardrobeOutfitSlot.accessory) <= 1 &&
        snapshot.totalItems >= 5) {
      tips.add('Аксессуар (сумка, ремень) часто «собирает» готовый лук.');
    }

    if (tips.isEmpty) {
      tips.add(
        favoritesCount > 0
            ? 'Продолжай сохранять понравившиеся образы — я точнее пойму твой вкус.'
            : 'Сохраняй удачные образы в избранное — стилист будет точнее.',
      );
    }

    cards.add(
      WardrobeInsight(
        id: 'recommendation',
        title: 'Рекомендация стилиста',
        body: tips.first,
        kind: WardrobeInsightKind.recommendation,
      ),
    );

    return cards;
  }

  static Map<String, int> _fitCounts(List<WardrobeItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      final fit = item.fit.trim().toLowerCase();
      if (fit.isEmpty) continue;
      counts[fit] = (counts[fit] ?? 0) + 1;
    }
    return counts;
  }

  static Map<String, int> _categoryCounts(List<WardrobeItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      final cat = item.category.trim();
      if (cat.isEmpty) continue;
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    return counts;
  }

  static List<String> _topVibes(List<WardrobeItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      for (final vibe in item.vibes) {
        final key = vibe.trim().toLowerCase();
        if (key.isEmpty) continue;
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).map((e) => e.key).toList();
  }

  static String? _dominantFit(Map<String, int> fitCounts) {
    if (fitCounts.isEmpty) return null;
    return fitCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static String _inferAesthetic(
    List<String> moods,
    List<String> vibes,
    WardrobeAnalysisSnapshot snapshot,
  ) {
    final casual = snapshot.styleCounts['casual'] ?? 0;
    final clean = snapshot.styleCounts['clean girl'] ?? 0;
    final minimal = vibes.any((v) => v.contains('миним'));

    if (moods.contains('comfy') || moods.contains('cozy')) {
      return 'Твой стиль ближе к comfy minimal — уют, мягкие формы и практичные сочетания.';
    }
    if (clean >= 2 || minimal) {
      return 'Эстетика clean girl / minimal: нейтралы, аккуратные линии, без перегруза.';
    }
    if (casual >= 3) {
      return 'Гардероб в духе casual streetwear — расслабленно, но собранно.';
    }
    if (snapshot.formalItemCount >= 2) {
      return 'Есть smart-casual и более dressy вещи — стиль гибкий под разные поводы.';
    }
    return 'Стиль формируется из повседневных вещей — добавляй mood в чате, и картина станет точнее.';
  }

  static String _joinRu(List<String> items) =>
      items.map(_labelStyle).join(', ');

  static String _labelStyle(String raw) => switch (raw.toLowerCase()) {
        'casual' => 'casual',
        'clean girl' => 'clean girl',
        'old money' => 'old money',
        'feminine' => 'feminine',
        'sporty' => 'sporty',
        'comfy' => 'comfy',
        'cozy' => 'cozy',
        'romantic' => 'romantic',
        'минимализм' => 'минимализм',
        _ => raw,
      };

  static String _slotLabelRu(WardrobeOutfitSlot slot) => switch (slot) {
        WardrobeOutfitSlot.top => 'верх',
        WardrobeOutfitSlot.bottom => 'низ',
        WardrobeOutfitSlot.dress => 'платья',
        WardrobeOutfitSlot.outerwear => 'верхняя одежда',
        WardrobeOutfitSlot.shoes => 'обувь',
        WardrobeOutfitSlot.accessory => 'аксессуары',
        WardrobeOutfitSlot.unknown => 'прочее',
      };
}
