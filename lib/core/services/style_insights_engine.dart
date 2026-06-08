import '../../data/models/wardrobe_item.dart';
import '../constants/wardrobe_catalog.dart';
import '../localization/app_locale.dart';
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
  static String _l(String ru, String en) => AppLocale.pick(ru: ru, en: en);

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
        ? _l(
            ' Цветотип «${prefs.colorType!.displayName}» уже задан — добавь вещи, и я подстрою советы.',
            ' Color type «${prefs.colorType!.displayName}» is set — add items and I will tailor tips.',
          )
        : '';
    final bodyHint = prefs.bodyProfile != null
        ? _l(
            ' Силуэт «${prefs.bodyProfile!.shape.displayName}» учту в рекомендациях.',
            ' Body shape «${prefs.bodyProfile!.shape.displayName}» will shape recommendations.',
          )
        : '';

    return [
      WardrobeInsight(
        id: 'empty_style',
        title: _l('Гардероб пока пуст', 'Wardrobe is empty'),
        body: _l(
          'Добавь несколько любимых вещей — я покажу доминирующий стиль, палитру и пробелы.$colorHint$bodyHint',
          'Add a few favorite pieces — I will show your dominant style, palette, and gaps.$colorHint$bodyHint',
        ),
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
        ? _l(
            'В гардеробе чаще встречаются направления: ${_joinStyles(topStyles)}.',
            'Your wardrobe leans toward: ${_joinStyles(topStyles)}.',
          )
        : _l(
            'Стили пока не размечены — отметь mood при добавлении вещей.',
            'Styles are not tagged yet — add a mood when you save items.',
          );

    final moodPart = moods.isNotEmpty
        ? _l(
            ' В чате ты часто выбираешь настроение: ${_joinStyles(moods)}.',
            ' In chat you often pick mood: ${_joinStyles(moods)}.',
          )
        : '';

    final vibePart = vibes.isNotEmpty
        ? _l(' Вайб: ${_joinStyles(vibes)}.', ' Vibe: ${_joinStyles(vibes)}.')
        : '';

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
      return _l('Casual и уютный стиль', 'Casual and cozy style');
    }
    if (styles.contains('old money') || styles.contains('feminine')) {
      return _l('Элегантный повседневный стиль', 'Elegant everyday style');
    }
    if (styles.contains('sporty')) {
      return _l('Спортивный и casual-мix', 'Sporty casual mix');
    }
    if (styles.isNotEmpty) {
      return _l(
        'Доминирует ${_labelStyle(styles.first)}',
        'Dominant: ${_labelStyle(styles.first)}',
      );
    }
    return _l('Твой стиль формируется', 'Your style is taking shape');
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
        ? _l(
            'В гардеробе много нейтральных и тёплых базовых оттенков — это упрощает сочетания.',
            'Lots of neutral and warm base shades — easy to mix and match.',
          )
        : topColors.isNotEmpty
            ? _l(
                'Чаще всего встречаются: ${_joinColors(topColors)}.',
                'Most common colors: ${_joinColors(topColors)}.',
              )
            : _l(
                'Палитра пока разнообразная без явного лидера.',
                'Your palette is varied with no clear leader yet.',
              );

    final darkPart = snapshot.darkToneCount >=
            (snapshot.totalItems * 0.5).ceil()
        ? _l(
            ' Преобладают тёмные тона — добавь светлый акцент для контраста.',
            ' Dark tones dominate — add a light accent for contrast.',
          )
        : '';

    final colorTypePart = colorType != null
        ? _l(
            ' Цветотип «${colorType.displayName}» — опирайся на его рекомендованную гамму.',
            ' Color type «${colorType.displayName}» — lean on its recommended palette.',
          )
        : '';

    return WardrobeInsight(
      id: 'color_palette',
      title: neutralRatio >= 0.45
          ? _l('Тёплые нейтралы в основе', 'Warm neutrals at the core')
          : _l('Твоя цветовая палитра', 'Your color palette'),
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
          .map(_slotLabel)
          .join(_l(' и ', ' and '));
      return WardrobeInsight(
        id: 'balance_gap',
        title: _l('Гардероб не сбалансирован', 'Wardrobe is unbalanced'),
        body: _l(
          'Не хватает категорий: $missing. '
          'Сейчас ${snapshot.totalItems} вещей — усили слабые слоты, чтобы образы собирались легче.',
          'Missing categories: $missing. '
          'You have ${snapshot.totalItems} items — fill weak slots to build looks faster.',
        ),
        kind: WardrobeInsightKind.balance,
      );
    }

    if (snapshot.overloadedSlots.isNotEmpty) {
      final slot = snapshot.overloadedSlots.first;
      return WardrobeInsight(
        id: 'balance_overload',
        title: _l('Перекос по категориям', 'Category imbalance'),
        body: _l(
          'Много вещей в категории «${_slotLabel(slot)}» '
          '(${snapshot.countFor(slot)} из ${snapshot.totalItems}). '
          'Разбавь другими слотами — низ, обувь или аксессуары.',
          'Many items in «${_slotLabel(slot)}» '
          '(${snapshot.countFor(slot)} of ${snapshot.totalItems}). '
          'Balance with bottoms, shoes, or accessories.',
        ),
        kind: WardrobeInsightKind.balance,
      );
    }

    final catPart = topCategory != null
        ? _l(
            ' Больше всего — «${_displayCategory(topCategory.key)}» (${topCategory.value} шт.).',
            ' Most items: «${_displayCategory(topCategory.key)}» (${topCategory.value}).',
          )
        : '';

    return WardrobeInsight(
      id: 'balance_ok',
      title: _l('Сбалансированный гардероб', 'Balanced wardrobe'),
      body: _l(
        'Категории распределены ровно — можно смело комбинировать вещи без «дырок» в образе.$catPart',
        'Categories are evenly spread — mix freely without gaps in your looks.$catPart',
      ),
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
      body = _l(
        'Ты часто выбираешь oversize и свободную посадку — образы выглядят расслабленно и современно.',
        'You often pick oversized and relaxed fits — looks feel easy and modern.',
      );
    } else if (dominantFit == 'slim' || fitted >= 2) {
      body = _l(
        'В гардеробе больше приталенных силуэтов — линия фигуры читается чётче.',
        'More fitted silhouettes — your shape reads more clearly.',
      );
    } else {
      body = _l(
        'Посадка в гардеробе сбалансирована: есть и свободные, и более структурные вещи.',
        'Fit is balanced: relaxed pieces and more structured ones.',
      );
    }

    if (bodyProfile != null) {
      body += _l(
        ' Силуэт «${bodyProfile.shape.displayName}»: ${bodyProfile.shape.shortDescription}',
        ' Shape «${bodyProfile.shape.displayName}»: ${bodyProfile.shape.shortDescription}',
      );
      if (bodyProfile.prefersOversized) {
        body += _l(
          ' Ты отмечала любовь к oversize — это совпадает с гардеробом.',
          ' You prefer oversized fits — that matches your wardrobe.',
        );
      }
    }

    return WardrobeInsight(
      id: 'silhouette',
      title: dominantFit == 'oversized'
          ? _l('Свободные силуэты', 'Relaxed silhouettes')
          : _l('Твои силуэты', 'Your silhouettes'),
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
      title: _l('Твоя эстетика', 'Your aesthetic'),
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
        WardrobeInsight(
          id: 'rec_basics',
          title: _l('Не хватает базовых вещей', 'Missing wardrobe basics'),
          body: _l(
            'Добавь нейтральный верх и универсальный низ (белая футболка, джинсы, бежевые брюки) — с ними образы собираются за минуту.',
            'Add a neutral top and versatile bottom (white tee, jeans, beige trousers) — looks come together fast.',
          ),
          kind: WardrobeInsightKind.recommendation,
        ),
      );
    }

    if (snapshot.darkToneCount >= (snapshot.totalItems * 0.5).ceil() &&
        snapshot.totalItems >= 3) {
      cards.add(
        WardrobeInsight(
          id: 'rec_dark_colors',
          title: _l('Слишком много тёмных оттенков', 'Too many dark shades'),
          body: _l(
            'В гардеробе доминируют тёмные цвета — добавь светлый верх или акцент (беж, молочный, пастель), чтобы луки не выглядели тяжёлыми.',
            'Dark colors dominate — add a light top or accent (beige, cream, pastel) so looks feel lighter.',
          ),
          kind: WardrobeInsightKind.recommendation,
        ),
      );
    }

    if (snapshot.countFor(WardrobeOutfitSlot.shoes) == 0 &&
        snapshot.totalItems >= 3) {
      cards.add(
        WardrobeInsight(
          id: 'rec_shoes',
          title: _l('Мало обуви', 'Not enough shoes'),
          body: _l(
            'Добавь хотя бы одну пару базовой обуви (кроссовки или лоферы) — без неё образы в чате часто выглядят незавершёнными.',
            'Add at least one basic pair (sneakers or loafers) — looks in chat often feel unfinished without shoes.',
          ),
          kind: WardrobeInsightKind.recommendation,
        ),
      );
    }

    final tips = <String>[];

    if (snapshot.neutralItemCount < 2 && snapshot.totalItems >= 4) {
      tips.add(_l(
        'Добавь нейтральные базы — белый верх, джинсы или бежевый низ.',
        'Add neutral basics — white top, jeans, or beige bottoms.',
      ));
    }

    if (snapshot.countFor(WardrobeOutfitSlot.outerwear) == 0 &&
        snapshot.totalItems >= 5) {
      tips.add(_l(
        'Не хватает слоя — жакет, кардigan или trench оживят комбинации.',
        'Add a layer — blazer, cardigan, or trench will refresh combos.',
      ));
    }

    if (snapshot.formalItemCount == 0 && snapshot.totalItems >= 6) {
      tips.add(_l(
        'Почти нет formal-вещей — одна более собранная позиция расширит поводы.',
        'Few dressy pieces — one polished item opens more occasions.',
      ));
    }

    final oversized = fitCounts['oversized'] ?? 0;
    final slim = (fitCounts['slim'] ?? 0) + (fitCounts['fitted'] ?? 0);
    if (oversized >= 2 && slim == 0) {
      tips.add(_l(
        'Попробуй контраст: oversize-верх + более структурный низ.',
        'Try contrast: oversized top + a more structured bottom.',
      ));
    } else if (slim >= 2 && oversized == 0) {
      tips.add(_l(
        'Добавь один oversize-слой — образ станет актуальнее.',
        'Add one oversized layer — the look will feel more current.',
      ));
    }

    if (snapshot.countFor(WardrobeOutfitSlot.accessory) <= 1 &&
        snapshot.totalItems >= 5) {
      tips.add(_l(
        'Аксессуар (сумка, ремень) часто «собирает» готовый лук.',
        'An accessory (bag, belt) often finishes the look.',
      ));
    }

    if (tips.isEmpty) {
      tips.add(
        favoritesCount > 0
            ? _l(
                'Продолжай сохранять понравившиеся образы — я точнее пойму твой вкус.',
                'Keep saving looks you like — I will learn your taste better.',
              )
            : _l(
                'Сохраняй удачные образы в избранное — стилист будет точнее.',
                'Save great looks to favorites — the stylist will improve.',
              ),
      );
    }

    cards.add(
      WardrobeInsight(
        id: 'recommendation',
        title: _l('Рекомендация стилиста', 'Stylist recommendation'),
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
    final minimal = vibes.any((v) => v.contains('миним') || v.contains('minimal'));

    if (moods.contains('comfy') || moods.contains('cozy')) {
      return _l(
        'Твой стиль ближе к comfy minimal — уют, мягкие формы и практичные сочетания.',
        'Your style leans comfy minimal — cozy shapes and practical pairings.',
      );
    }
    if (clean >= 2 || minimal) {
      return _l(
        'Эстетика clean girl / minimal: нейтралы, аккуратные линии, без перегруза.',
        'Clean girl / minimal aesthetic: neutrals, neat lines, no clutter.',
      );
    }
    if (casual >= 3) {
      return _l(
        'Гардероб в духе casual streetwear — расслабленно, но собранно.',
        'Casual streetwear wardrobe — relaxed but put together.',
      );
    }
    if (snapshot.formalItemCount >= 2) {
      return _l(
        'Есть smart-casual и более dressy вещи — стиль гибкий под разные поводы.',
        'Smart-casual and dressier pieces — flexible for different occasions.',
      );
    }
    return _l(
      'Стиль формируется из повседневных вещей — добавляй mood в чате, и картина станет точнее.',
      'Style is built from everyday pieces — pick moods in chat for sharper insights.',
    );
  }

  static String _joinStyles(List<String> items) =>
      items.map(_labelStyle).join(', ');

  static String _joinColors(List<String> items) =>
      items.map(_displayColor).join(', ');

  static String _displayColor(String raw) => WardrobeCatalog.displayColor(raw);

  static String _displayCategory(String raw) =>
      WardrobeCatalog.displayCategory(raw);

  static String _labelStyle(String raw) {
    if (WardrobeCatalog.vibes.contains(raw)) {
      return WardrobeCatalog.displayVibe(raw);
    }

    final color = WardrobeCatalog.displayColor(raw);
    if (color != raw) return color;

    return switch (raw.toLowerCase()) {
      'casual' => 'casual',
      'clean girl' => 'clean girl',
      'old money' => 'old money',
      'feminine' => 'feminine',
      'sporty' => 'sporty',
      'comfy' => 'comfy',
      'cozy' => 'cozy',
      'romantic' => 'romantic',
      'streetwear' => 'streetwear',
      'минимализм' => _l('минимализм', 'minimalism'),
      'романтичный' => WardrobeCatalog.displayVibe('романтичный'),
      'уютный' => WardrobeCatalog.displayVibe('уютный'),
      'дерзкий' => WardrobeCatalog.displayVibe('дерзкий'),
      'элегантный' => WardrobeCatalog.displayVibe('элегантный'),
      'игривый' => WardrobeCatalog.displayVibe('игривый'),
      _ => raw,
    };
  }

  static String _slotLabel(WardrobeOutfitSlot slot) => switch (slot) {
        WardrobeOutfitSlot.top => _l('верх', 'tops'),
        WardrobeOutfitSlot.bottom => _l('низ', 'bottoms'),
        WardrobeOutfitSlot.dress => _l('платья', 'dresses'),
        WardrobeOutfitSlot.set => _l('комплекты', 'sets'),
        WardrobeOutfitSlot.outerwear => _l('верхняя одежда', 'outerwear'),
        WardrobeOutfitSlot.shoes => _l('обувь', 'shoes'),
        WardrobeOutfitSlot.accessory => _l('аксессуары', 'accessories'),
        WardrobeOutfitSlot.unknown => _l('прочее', 'other'),
      };
}
