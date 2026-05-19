import '../../data/models/wardrobe_item.dart';
import '../models/body_profile.dart';
import '../models/seasonal_color_type.dart';
import '../models/stylist_request_context.dart';
import '../models/wardrobe_outfit_slot.dart';
import 'silhouette_balancer.dart';
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
  }) {
    var total = 0.0;

    total += _scoreOccasions(item, context.occasions) * 18;
    total += _scoreMoods(item, context.moods) * 16;
    total += _scoreWeatherTags(item, context.weather) * 14;
    total += _scoreLiveWeather(item, weather) * 20;
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

    return total;
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
      'dark academia' => vibe.contains('элегант') || vibe.contains('минимал'),
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

  static double _scoreLiveWeather(WardrobeItem item, WeatherSnapshot? weather) {
    if (weather == null || !weather.isAvailable) return 0.5;

    final temp = weather.temperatureCelsius;
    final season = item.season.toLowerCase();
    final category = item.category.toLowerCase();
    var score = 0.5;

    if (temp != null) {
      if (temp < 12) {
        if (season.contains('зим') || season.contains('осен')) score += 0.35;
        if (category.contains('верхняя')) score += 0.25;
        if (category == 'обувь' &&
            !item.title.toLowerCase().contains('сандал')) {
          score += 0.15;
        }
      } else if (temp > 22) {
        if (season.contains('лет') || season.contains('весн')) score += 0.35;
        if (category == 'верхняя одежда') score -= 0.2;
      }
    }

    if (weather.conditions.contains(WeatherCondition.rainy)) {
      if (category.contains('верхняя') ||
          item.title.toLowerCase().contains('плащ') ||
          item.title.toLowerCase().contains('тренч')) {
        score += 0.3;
      }
      if (category == 'обувь' &&
          item.title.toLowerCase().contains('сандал')) {
        score -= 0.4;
      }
    }

    if (weather.conditions.contains(WeatherCondition.windy) &&
        category.contains('верхняя')) {
      score += 0.15;
    }

    return score.clamp(0.0, 1.0);
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

class _ColorKeywordSet {
  const _ColorKeywordSet({
    required this.preferred,
    required this.avoid,
  });

  final List<String> preferred;
  final List<String> avoid;
}
