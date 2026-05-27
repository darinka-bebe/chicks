import '../../data/models/wardrobe_item.dart';
import '../models/body_profile.dart';
import '../models/favorite_preference_profile.dart';
import '../models/outfit_preference_profile.dart';
import '../models/recent_outfit_signals.dart';
import '../models/seasonal_color_type.dart';
import '../models/stylist_request_context.dart';
import '../models/wardrobe_outfit_slot.dart';
import 'silhouette_balancer.dart';
import 'outfit_trait_extractor.dart';
import 'wardrobe_slot_classifier.dart';
import '../models/weather_snapshot.dart';
import '../models/weather_condition.dart';

/// Scores how well a wardrobe item fits the current stylist request.
abstract final class OutfitItemScorer {
  static double score({
    required WardrobeItem item,
    StylistRequestContext context = StylistRequestContext.empty,
    WeatherSnapshot? weather,
    SeasonalColorType? colorType,
    BodyProfile? bodyProfile,
    Map<WardrobeOutfitSlot, WardrobeItem>? coSelected,
    OutfitPreferenceProfile preferenceProfile = OutfitPreferenceProfile.empty,
    FavoritePreferenceProfile favoriteProfile = FavoritePreferenceProfile.empty,
    RecentOutfitSignals recentSignals = RecentOutfitSignals.empty,
  }) {
    var total = 0.0;
    final weatherFit = analyzeWeatherFit(
      item: item,
      weather: weather,
      context: context,
    );

    total += _scoreOccasions(item, context.occasions) * 18;
    total += _scoreMoods(item, context.moods) * 16;
    total += _scoreWeatherTags(item, context.weather) * 14;
    total += weatherFit.weatherScore * 34;
    total -= weatherFit.temperaturePenalty * 24;
    total += _scoreStyleCohesion(item, context) * 10;
    total += _scoreNeutralBasics(item) * 4;
    total += _scoreColorType(item, colorType) * 20;
    total += _scoreBodyProfile(item, bodyProfile) * 16;

    if (bodyProfile != null && coSelected != null && coSelected.isNotEmpty) {
      final slot = WardrobeSlotClassifier.classify(item);
      total +=
          SilhouetteBalancer.combinationDelta(
                candidate: item,
                slot: slot,
                selected: coSelected,
                profile: bodyProfile,
              ) *
              12;
    }

    total -= _scoreDislikePenalty(item, coSelected, preferenceProfile);
    total += _scoreFavoriteBoost(
          item,
          context,
          coSelected,
          favoriteProfile,
        ) *
        16;

    total -= _scoreRecentRepeatPenalty(item, coSelected, recentSignals) * 14;

    return total.clamp(0.0, 135.0);
  }

  static WeatherFitAnalysis analyzeWeatherFit({
    required WardrobeItem item,
    WeatherSnapshot? weather,
    StylistRequestContext context = StylistRequestContext.empty,
  }) {
    if (weather == null || !weather.isAvailable) {
      return const WeatherFitAnalysis(weatherScore: 0.5);
    }

    final title = item.title.toLowerCase();
    final category = item.category.toLowerCase();
    final color = item.color.toLowerCase();
    final styles = item.styles.map((e) => e.toLowerCase()).toList();
    final vibes = item.vibes.map((e) => e.toLowerCase()).toList();
    final fit = item.fit.toLowerCase();
    final slot = WardrobeSlotClassifier.classify(item);
    final temp = weather.temperatureCelsius;
    final isCold = temp != null && temp < 12;
    final isVeryCold = temp != null && temp < 12;
    final isChilly = temp != null && temp >= 12 && temp < 16;
    final isRainy = weather.conditions.contains(WeatherCondition.rainy);
    final isSnowy = weather.conditions.contains(WeatherCondition.snowy);
    final isWet = isRainy || isSnowy;

    var score = 0.5;
    var temperaturePenalty = 0.0;
    var shouldReject = false;
    final penalties = <String>[];
    final boosts = <String>[];
    final boostedCategories = <String>{};

    final isLightTop =
        slot == WardrobeOutfitSlot.top &&
        (title.contains('футбол') ||
            title.contains('майк') ||
            title.contains('t-shirt') ||
            title.contains('tee') ||
            title.contains('топ'));
    final isShortsLike =
        slot == WardrobeOutfitSlot.bottom &&
        (title.contains('шорт') ||
            title.contains('short') ||
            title.contains('мини'));
    final isOpenShoes =
        slot == WardrobeOutfitSlot.shoes &&
        (title.contains('сандал') ||
            title.contains('босонож') ||
            title.contains('шлёп') ||
            title.contains('шлеп') ||
            title.contains('сланц') ||
            title.contains('flip'));
    final isWarmTop = title.contains('худи') ||
        title.contains('hoodie') ||
        title.contains('свитер') ||
        title.contains('джемпер') ||
        title.contains('кардиган') ||
        title.contains('knit') ||
        title.contains('толстов');
    final isOuterwear = slot == WardrobeOutfitSlot.outerwear ||
        category.contains('верхняя') ||
        title.contains('куртк') ||
        title.contains('пальт') ||
        title.contains('плащ') ||
        title.contains('тренч') ||
        title.contains('jacket') ||
        title.contains('coat');
    final hasCozySignals = styles.any(
          (s) => s.contains('comfy') || s.contains('cozy') || s.contains('casual'),
        ) ||
        vibes.any((v) => v.contains('уют') || v.contains('тепл')) ||
        fit.contains('oversized') ||
        context.moods.any(
          (m) => m.toLowerCase().contains('comfy') || m.toLowerCase().contains('cozy'),
        );
    final isDarkPalette = color.contains('чёрн') ||
        color.contains('черн') ||
        color.contains('графит') ||
        color.contains('сер') ||
        color.contains('син') ||
        color.contains('бордо') ||
        color.contains('корич');
    final isVeryLightPalette = color.contains('бел') ||
        color.contains('молоч') ||
        color.contains('крем') ||
        color.contains('пастел');
    final isProtectedShoes = slot == WardrobeOutfitSlot.shoes &&
        !isOpenShoes &&
        (title.contains('бот') ||
            title.contains('крос') ||
            title.contains('кед') ||
            title.contains('лофер') ||
            title.contains('boot') ||
            title.contains('sneaker'));

    if (isCold || isVeryCold) {
      if (isLightTop) {
        score -= 0.4;
        temperaturePenalty += 0.45;
        penalties.add('light-top-in-cold');
        if (isVeryCold || isWet) shouldReject = true;
      }
      if (isShortsLike) {
        score -= 0.35;
        temperaturePenalty += 0.4;
        penalties.add('shorts-in-cold');
        if (isVeryCold) shouldReject = true;
      }
      if (isOpenShoes) {
        score -= 0.45;
        temperaturePenalty += 0.5;
        penalties.add('open-shoes-in-cold');
        shouldReject = true;
      }
      if (isWarmTop) {
        score += 0.28;
        boosts.add('warm-top-boost');
        boostedCategories.add('warm-top');
      }
      if (isOuterwear) {
        score += 0.35;
        boosts.add('outerwear-boost');
        boostedCategories.add('outerwear');
      }
    } else if (isChilly) {
      if (isOpenShoes) {
        score -= 0.2;
        temperaturePenalty += 0.18;
        penalties.add('open-shoes-in-chilly');
      }
      if (isWarmTop || isOuterwear) {
        score += 0.18;
        boosts.add('chilly-layer-boost');
        boostedCategories.add(isOuterwear ? 'outerwear' : 'warm-top');
      }
    }

    if (isWet) {
      if (isOpenShoes) {
        score -= 0.45;
        temperaturePenalty += 0.35;
        penalties.add('open-shoes-in-rain');
        shouldReject = true;
      }
      if (isOuterwear) {
        score += 0.25;
        boosts.add('rain-outerwear-boost');
        boostedCategories.add('outerwear');
      }
      if (isProtectedShoes) {
        score += 0.2;
        boosts.add('protected-footwear-boost');
        boostedCategories.add('protected-footwear');
      }
      if (isDarkPalette) {
        score += 0.08;
        boosts.add('rain-dark-palette-boost');
        boostedCategories.add('dark-palette');
      }
      if (isVeryLightPalette) {
        score -= 0.08;
        penalties.add('rain-light-palette-penalty');
      }
      if (hasCozySignals) {
        score += 0.1;
        boosts.add('rain-cozy-style-boost');
        boostedCategories.add('cozy-style');
      }
    }

    if ((isCold || isWet) && hasCozySignals) {
      score += 0.1;
      boosts.add('weather-comfort-style-boost');
      boostedCategories.add('cozy-style');
    }

    return WeatherFitAnalysis(
      weatherScore: score.clamp(0.0, 1.0),
      temperaturePenalty: temperaturePenalty.clamp(0.0, 1.0),
      isRejected: shouldReject,
      penalties: penalties,
      boosts: boosts,
      boostedCategories: boostedCategories.toList(growable: false),
    );
  }

  static double _scoreRecentRepeatPenalty(
    WardrobeItem item,
    Map<WardrobeOutfitSlot, WardrobeItem>? coSelected,
    RecentOutfitSignals signals,
  ) {
    if (!signals.hasSignals) return 0;

    var penalty = signals.repeatPenalty(itemId: item.id);

    if (coSelected != null && coSelected.isNotEmpty) {
      final comboItems = [...coSelected.values, item];
      final combinationKey = OutfitTraitExtractor.combinationKeyFrom(
        itemIds: comboItems.map((i) => i.id).toList(),
        styles: const [],
      );
      penalty = (penalty +
              signals.repeatPenalty(
                itemId: item.id,
                combinationKey: combinationKey,
              ))
          .clamp(0.0, 1.0);
    }

    return penalty;
  }

  static double _scoreFavoriteBoost(
    WardrobeItem item,
    StylistRequestContext context,
    Map<WardrobeOutfitSlot, WardrobeItem>? coSelected,
    FavoritePreferenceProfile profile,
  ) {
    if (!profile.hasSignals) return 0;

    final itemTraits = OutfitTraitExtractor.extract(
      items: [item],
      recommendationText: '',
    );

    var boost = profile.favoriteBoost(
      styles: itemTraits.styles,
      colors: itemTraits.colors,
      silhouettes: itemTraits.silhouettes,
      itemId: item.id,
      moods: context.moods,
      occasions: context.occasions,
    );

    if (coSelected != null && coSelected.isNotEmpty) {
      final comboItems = coSelected.values.toList();
      final comboTraits = OutfitTraitExtractor.extract(
        items: comboItems,
        recommendationText: '',
      );
      final combinationKey = OutfitTraitExtractor.combinationKeyFrom(
        itemIds: [...comboItems.map((i) => i.id), item.id],
        styles: {...comboTraits.styles, ...itemTraits.styles},
      );
      boost = (boost +
              profile.favoriteBoost(
                styles: comboTraits.styles,
                colors: comboTraits.colors,
                silhouettes: comboTraits.silhouettes,
                combinationKey: combinationKey,
                moods: context.moods,
                occasions: context.occasions,
              ))
          .clamp(0.0, 1.0);
    }

    return boost;
  }

  static double _scoreDislikePenalty(
    WardrobeItem item,
    Map<WardrobeOutfitSlot, WardrobeItem>? coSelected,
    OutfitPreferenceProfile profile,
  ) {
    if (!profile.hasSignals) return 0;

    final itemTraits = OutfitTraitExtractor.extract(
      items: [item],
      recommendationText: '',
    );

    var penalty = profile.dislikePenalty(
      styles: itemTraits.styles,
      colors: itemTraits.colors,
      silhouettes: itemTraits.silhouettes,
    );

    if (coSelected != null && coSelected.isNotEmpty) {
      final comboItems = coSelected.values.toList();
      final comboTraits = OutfitTraitExtractor.extract(
        items: comboItems,
        recommendationText: '',
      );
      final combinationKey = OutfitTraitExtractor.combinationKeyFrom(
        itemIds: comboItems.map((i) => i.id).toList(),
        styles: {...comboTraits.styles, ...itemTraits.styles},
      );
      penalty += profile.dislikePenalty(
        styles: comboTraits.styles,
        colors: comboTraits.colors,
        silhouettes: comboTraits.silhouettes,
        combinationKey: combinationKey,
      );
    }

    return penalty;
  }

  static double _scoreBodyProfile(WardrobeItem item, BodyProfile? profile) {
    if (profile == null) return 0.5;
    return SilhouetteBalancer.scoreItemForBody(item: item, profile: profile);
  }

  static double _scoreColorType(WardrobeItem item, SeasonalColorType? colorType) {
    if (colorType == null) return 0.5;

    final color = '${item.color} ${item.title}'.toLowerCase();
    final match = _colorKeywordsFor(colorType);
    var hits = 0;
    for (final keyword in match.preferred) {
      if (color.contains(keyword)) hits++;
    }
    var misses = 0;
    for (final keyword in match.avoid) {
      if (color.contains(keyword)) misses++;
    }

    if (hits == 0 && misses == 0) return 0.35;
    if (misses > 0 && hits == 0) return 0.15;
    return ((hits * 0.4) - (misses * 0.55) + 0.45).clamp(0.0, 1.0);
  }

  static _ColorKeywordSet _colorKeywordsFor(SeasonalColorType type) {
    return switch (type) {
      SeasonalColorType.lightSpring => const _ColorKeywordSet(
            preferred: [
              'корал',
              'персик',
              'беж',
              'айвори',
              'светл',
              'голуб',
              'мят',
              'жёлт',
              'желт',
              'крем',
            ],
            avoid: ['чёрн', 'черн', 'уголь', 'бордо', 'тёмн', 'темн'],
          ),
      SeasonalColorType.warmAutumn => const _ColorKeywordSet(
            preferred: [
              'терракот',
              'олив',
              'горчиц',
              'карамел',
              'шоколад',
              'хаки',
              'рыж',
              'мед',
              'корич',
              'беж',
              'золот',
            ],
            avoid: ['неон', 'фукси', 'холод', 'ледян', 'пыльн', 'сер'],
          ),
      SeasonalColorType.softSummer => const _ColorKeywordSet(
            preferred: [
              'пыльн',
              'лаванд',
              'роз',
              'голуб',
              'сер',
              'шалфей',
              'приглуш',
              'мят',
              'сирен',
            ],
            avoid: ['оранж', 'неон', 'чёрн', 'черн', 'кислот', 'жёлт', 'желт'],
          ),
      SeasonalColorType.coolWinter => const _ColorKeywordSet(
            preferred: [
              'чёрн',
              'черн',
              'бел',
              'фукси',
              'изумруд',
              'син',
              'бордо',
              'сереб',
              'холод',
              'контраст',
            ],
            avoid: ['оранж', 'золот', 'беж', 'персик', 'горчиц', 'олив'],
          ),
    };
  }

  static double _scoreOccasions(WardrobeItem item, List<String> occasions) {
    if (occasions.isEmpty) return 0.5;
    var hits = 0;
    final itemOcc = item.occasions.map((e) => e.toLowerCase()).toList();
    final title = item.title.toLowerCase();

    for (final occasion in occasions) {
      final key = occasion.toLowerCase();
      if (itemOcc.any((o) => o.contains(key) || key.contains(o))) {
        hits++;
        continue;
      }
      if (_occasionTitleMatch(key, title)) hits++;
    }
    return hits / occasions.length;
  }

  static bool _occasionTitleMatch(String occasion, String title) {
    return switch (occasion) {
      'school' => title.contains('школ') || title.contains('school'),
      'date' => title.contains('свидан') || title.contains('date'),
      'office' =>
        title.contains('офис') || title.contains('office') || title.contains('делов'),
      'walk' => title.contains('прогул'),
      'party' => title.contains('вечер') || title.contains('party'),
      _ => false,
    };
  }

  static double _scoreMoods(WardrobeItem item, List<String> moods) {
    if (moods.isEmpty) return 0.5;
    var hits = 0;
    final styles = item.styles.map((e) => e.toLowerCase()).toList();
    final vibes = item.vibes.map((e) => e.toLowerCase()).toList();
    final fit = item.fit.toLowerCase();

    for (final mood in moods) {
      final key = mood.toLowerCase();
      if (styles.any((s) => s.contains(key) || key.contains(s))) {
        hits++;
        continue;
      }
      if (vibes.any((v) => _vibeMatchesMood(key, v))) {
        hits++;
        continue;
      }
      if (_moodFitMatch(key, fit)) hits++;
    }
    return hits / moods.length;
  }

  static bool _vibeMatchesMood(String mood, String vibe) {
    if (vibe.contains(mood) || mood.contains(vibe)) return true;
    return switch (mood) {
      'romantic' => vibe.contains('романт'),
      'comfy' || 'cozy' => vibe.contains('уют'),
      'elegant' => vibe.contains('элегант'),
      'confident' => vibe.contains('дерз'),
      'feminine' => vibe.contains('романт') || vibe.contains('элегант'),
      'soft girl' => vibe.contains('игрив') || vibe.contains('романт'),
      _ => false,
    };
  }

  static bool _moodFitMatch(String mood, String fit) {
    return switch (mood) {
      'comfy' || 'cozy' => fit.contains('relaxed') || fit.contains('oversized'),
      'confident' => fit.contains('slim') || fit.contains('regular'),
      _ => false,
    };
  }

  static double _scoreWeatherTags(WardrobeItem item, List<String> weatherTags) {
    if (weatherTags.isEmpty) return 0.5;
    var hits = 0;
    final season = item.season.toLowerCase();

    for (final tag in weatherTags) {
      if (_seasonMatchesWeatherTag(season, tag)) hits++;
    }
    return hits / weatherTags.length;
  }

  static bool _seasonMatchesWeatherTag(String season, String tag) {
    final key = tag.toLowerCase();
    if (key == 'hot') {
      return season.contains('лет') || season.contains('весн');
    }
    if (key == 'cold') {
      return season.contains('зим') || season.contains('осен');
    }
    if (key == 'rainy') {
      return season.contains('весн') ||
          season.contains('осен') ||
          season.contains('всесезон');
    }
    if (key == 'windy') {
      return season.contains('осен') || season.contains('весн');
    }
    return false;
  }

  static double _scoreStyleCohesion(
    WardrobeItem item,
    StylistRequestContext context,
  ) {
    if (context.moods.isEmpty && context.occasions.isEmpty) return 0.5;

    final styleHints = <String>{
      ...context.moods,
      ...context.occasions,
    }.map((e) => e.toLowerCase()).toSet();

    if (styleHints.contains('streetwear') &&
        item.styles.any((s) => s.toLowerCase().contains('streetwear'))) {
      return 1.0;
    }
    if ((styleHints.contains('school') || styleHints.contains('walk')) &&
        item.styles.any((s) {
          final sLower = s.toLowerCase();
          return sLower.contains('casual') || sLower.contains('clean');
        })) {
      return 0.9;
    }
    if (styleHints.contains('romantic') &&
        (item.vibes.any((v) => v.contains('романт')) ||
            item.styles.any((s) => s.contains('feminine')))) {
      return 1.0;
    }

    return 0.5;
  }

  static double _scoreNeutralBasics(WardrobeItem item) {
    final color = item.color.toLowerCase();
    if (color.contains('бел') ||
        color.contains('чёрн') ||
        color.contains('черн') ||
        color.contains('сер') ||
        color.contains('беж') ||
        color.contains('нейтрал')) {
      return 0.6;
    }
    return 0.3;
  }
}

class WeatherFitAnalysis {
  const WeatherFitAnalysis({
    required this.weatherScore,
    this.temperaturePenalty = 0,
    this.isRejected = false,
    this.penalties = const [],
    this.boosts = const [],
    this.boostedCategories = const [],
  });

  final double weatherScore;
  final double temperaturePenalty;
  final bool isRejected;
  final List<String> penalties;
  final List<String> boosts;
  final List<String> boostedCategories;
}

class _ColorKeywordSet {
  const _ColorKeywordSet({
    required this.preferred,
    required this.avoid,
  });

  final List<String> preferred;
  final List<String> avoid;
}
