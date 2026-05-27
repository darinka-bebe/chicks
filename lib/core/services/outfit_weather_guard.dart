import '../../data/models/wardrobe_item.dart';
import '../models/body_profile.dart';
import '../models/favorite_preference_profile.dart';
import '../models/outfit_preference_profile.dart';
import '../models/recent_outfit_signals.dart';
import '../models/seasonal_color_type.dart';
import '../models/stylist_request_context.dart';
import '../models/wardrobe_outfit_slot.dart';
import '../models/weather_condition.dart';
import '../models/weather_snapshot.dart';
import '../utils/logger.dart';
import 'outfit_item_scorer.dart';
import 'wardrobe_outfit_fallback.dart';
import 'wardrobe_slot_classifier.dart';

/// Validates and repairs outfits for live weather (comfort-first).
abstract final class OutfitWeatherGuard {
  static List<WardrobeItem> repairOutfit({
    required List<WardrobeItem> current,
    required List<WardrobeItem> wardrobe,
    required WeatherSnapshot weather,
    StylistRequestContext context = StylistRequestContext.empty,
    SeasonalColorType? colorType,
    BodyProfile? bodyProfile,
    OutfitPreferenceProfile preferenceProfile =
        OutfitPreferenceProfile.empty,
    FavoritePreferenceProfile favoriteProfile =
        FavoritePreferenceProfile.empty,
    RecentOutfitSignals recentSignals = RecentOutfitSignals.empty,
  }) {
    if (!weather.isAvailable || current.isEmpty || wardrobe.isEmpty) {
      return current;
    }

    final picked = <WardrobeOutfitSlot, WardrobeItem>{};
    for (final item in current) {
      final slot = WardrobeSlotClassifier.classify(item);
      if (slot == WardrobeOutfitSlot.unknown) continue;
      picked.putIfAbsent(slot, () => item);
    }

    _replaceLightTopIfNeeded(
      picked: picked,
      wardrobe: wardrobe,
      weather: weather,
      context: context,
      colorType: colorType,
      bodyProfile: bodyProfile,
      preferenceProfile: preferenceProfile,
      favoriteProfile: favoriteProfile,
      recentSignals: recentSignals,
    );
    _injectOuterwearIfNeeded(
      picked: picked,
      wardrobe: wardrobe,
      weather: weather,
      context: context,
      colorType: colorType,
      bodyProfile: bodyProfile,
      preferenceProfile: preferenceProfile,
      favoriteProfile: favoriteProfile,
      recentSignals: recentSignals,
    );
    _replaceOpenShoesIfNeeded(
      picked: picked,
      wardrobe: wardrobe,
      weather: weather,
      context: context,
      colorType: colorType,
      bodyProfile: bodyProfile,
      preferenceProfile: preferenceProfile,
      favoriteProfile: favoriteProfile,
      recentSignals: recentSignals,
    );

    var repaired = _orderOutfit(picked);
    final evaluation = evaluateOutfit(repaired, weather);

    AppLogger.info(
      'OutfitWeatherGuard: comfort=${evaluation.comfortScore.toStringAsFixed(2)} '
      'acceptable=${evaluation.isAcceptable} issues=${evaluation.issues.join(',')}',
    );

    if (evaluation.isAcceptable) return repaired;

    AppLogger.info(
      'OutfitWeatherGuard: rejecting unrealistic outfit, rebuilding from wardrobe',
    );

    final fallback = WardrobeOutfitFallback.build(
      wardrobe: wardrobe,
      context: context,
      weather: weather,
      colorType: colorType,
      bodyProfile: bodyProfile,
      preferenceProfile: preferenceProfile,
      favoriteProfile: favoriteProfile,
      recentSignals: recentSignals,
    );

    if (fallback.length >= 2) {
      final fallbackEval = evaluateOutfit(fallback, weather);
      AppLogger.info(
        'OutfitWeatherGuard: fallback comfort='
        '${fallbackEval.comfortScore.toStringAsFixed(2)} '
        'acceptable=${fallbackEval.isAcceptable}',
      );
      return fallback;
    }

    return repaired;
  }

  static OutfitWeatherEvaluation evaluateOutfit(
    List<WardrobeItem> items,
    WeatherSnapshot weather,
  ) {
    if (!weather.isAvailable || items.isEmpty) {
      return const OutfitWeatherEvaluation(
        comfortScore: 1,
        isAcceptable: true,
      );
    }

    final temp = weather.temperatureCelsius;
    final isCold = temp != null && temp < 12;
    final isRainy = weather.conditions.contains(WeatherCondition.rainy);
    final isSnowy = weather.conditions.contains(WeatherCondition.snowy);
    final needsProtection = isCold || isRainy || isSnowy;

    if (!needsProtection) {
      return const OutfitWeatherEvaluation(
        comfortScore: 1,
        isAcceptable: true,
      );
    }

    final issues = <String>[];
    var comfort = 1.0;

    WardrobeItem? top;
    WardrobeItem? outerwear;
    WardrobeItem? shoes;

    for (final item in items) {
      final slot = WardrobeSlotClassifier.classify(item);
      switch (slot) {
        case WardrobeOutfitSlot.top:
          top = item;
        case WardrobeOutfitSlot.outerwear:
          outerwear = item;
        case WardrobeOutfitSlot.shoes:
          shoes = item;
        default:
          break;
      }

      final fit = OutfitItemScorer.analyzeWeatherFit(
        item: item,
        weather: weather,
      );
      comfort -= fit.temperaturePenalty * 0.2;
      if (fit.isRejected) {
        issues.add('rejected-item:${item.title}');
        comfort -= 0.35;
      }
    }

    final hasWarmLayer = outerwear != null ||
        (top != null && (isWarmTop(top) || !isLightTop(top)));
    if (!hasWarmLayer) {
      issues.add('missing-warm-layer');
      comfort -= 0.55;
    } else if (top != null && isLightTop(top) && outerwear == null) {
      issues.add('light-top-without-outerwear');
      comfort -= 0.35;
    }

    if (shoes != null && isOpenShoes(shoes.title)) {
      issues.add('open-shoes');
      comfort -= 0.45;
    }

    for (final item in items) {
      if (isShortsLike(item)) {
        issues.add('shorts-in-cold-rain');
        comfort -= 0.4;
        break;
      }
    }

    comfort = comfort.clamp(0.0, 1.0);
    final acceptable = comfort >= 0.55 && !issues.contains('missing-warm-layer');

    if (!acceptable) {
      AppLogger.info(
        'OutfitWeatherGuard: outfit rejected '
        '[temp=${temp?.round()} issues=${issues.join(',')}]',
      );
    }

    return OutfitWeatherEvaluation(
      comfortScore: comfort,
      isAcceptable: acceptable,
      issues: issues,
    );
  }

  static void _replaceLightTopIfNeeded({
    required Map<WardrobeOutfitSlot, WardrobeItem> picked,
    required List<WardrobeItem> wardrobe,
    required WeatherSnapshot weather,
    required StylistRequestContext context,
    SeasonalColorType? colorType,
    BodyProfile? bodyProfile,
    required OutfitPreferenceProfile preferenceProfile,
    required FavoritePreferenceProfile favoriteProfile,
    required RecentOutfitSignals recentSignals,
  }) {
    if (!_needsWarmLayer(weather)) return;

    final top = picked[WardrobeOutfitSlot.top];
    if (top == null || !isLightTop(top)) return;
    if (picked.containsKey(WardrobeOutfitSlot.outerwear)) return;

    final replacement = _bestFromWardrobe(
      wardrobe: wardrobe,
      slot: WardrobeOutfitSlot.top,
      weather: weather,
      context: context,
      colorType: colorType,
      bodyProfile: bodyProfile,
      coSelected: picked,
      preferenceProfile: preferenceProfile,
      favoriteProfile: favoriteProfile,
      recentSignals: recentSignals,
      predicate: (item) => isWarmTop(item) || !isLightTop(item),
    );

    if (replacement != null && replacement.id != top.id) {
      picked[WardrobeOutfitSlot.top] = replacement;
      AppLogger.info(
        'OutfitWeatherGuard: replaced light top '
        '"${top.title}" → "${replacement.title}"',
      );
    }
  }

  static void _injectOuterwearIfNeeded({
    required Map<WardrobeOutfitSlot, WardrobeItem> picked,
    required List<WardrobeItem> wardrobe,
    required WeatherSnapshot weather,
    required StylistRequestContext context,
    SeasonalColorType? colorType,
    BodyProfile? bodyProfile,
    required OutfitPreferenceProfile preferenceProfile,
    required FavoritePreferenceProfile favoriteProfile,
    required RecentOutfitSignals recentSignals,
  }) {
    if (!_needsOuterwear(weather)) return;
    if (picked.containsKey(WardrobeOutfitSlot.outerwear)) return;

    final top = picked[WardrobeOutfitSlot.top];
    if (top != null && isWarmTop(top) && !_needsOuterwearStrict(weather)) {
      return;
    }

    final outerwear = _bestFromWardrobe(
      wardrobe: wardrobe,
      slot: WardrobeOutfitSlot.outerwear,
      weather: weather,
      context: context,
      colorType: colorType,
      bodyProfile: bodyProfile,
      coSelected: picked,
      preferenceProfile: preferenceProfile,
      favoriteProfile: favoriteProfile,
      recentSignals: recentSignals,
    );

    if (outerwear != null) {
      picked[WardrobeOutfitSlot.outerwear] = outerwear;
      AppLogger.info(
        'OutfitWeatherGuard: injected outerwear "${outerwear.title}"',
      );
    }
  }

  static void _replaceOpenShoesIfNeeded({
    required Map<WardrobeOutfitSlot, WardrobeItem> picked,
    required List<WardrobeItem> wardrobe,
    required WeatherSnapshot weather,
    required StylistRequestContext context,
    SeasonalColorType? colorType,
    BodyProfile? bodyProfile,
    required OutfitPreferenceProfile preferenceProfile,
    required FavoritePreferenceProfile favoriteProfile,
    required RecentOutfitSignals recentSignals,
  }) {
    if (!_needsClosedShoes(weather)) return;

    final shoes = picked[WardrobeOutfitSlot.shoes];
    if (shoes == null || !isOpenShoes(shoes.title)) return;

    final replacement = _bestFromWardrobe(
      wardrobe: wardrobe,
      slot: WardrobeOutfitSlot.shoes,
      weather: weather,
      context: context,
      colorType: colorType,
      bodyProfile: bodyProfile,
      coSelected: picked,
      preferenceProfile: preferenceProfile,
      favoriteProfile: favoriteProfile,
      recentSignals: recentSignals,
      predicate: (item) => !isOpenShoes(item.title),
    );

    if (replacement != null) {
      picked[WardrobeOutfitSlot.shoes] = replacement;
      AppLogger.info(
        'OutfitWeatherGuard: replaced open shoes → "${replacement.title}"',
      );
    }
  }

  static WardrobeItem? _bestFromWardrobe({
    required List<WardrobeItem> wardrobe,
    required WardrobeOutfitSlot slot,
    required WeatherSnapshot weather,
    required StylistRequestContext context,
    SeasonalColorType? colorType,
    BodyProfile? bodyProfile,
    required Map<WardrobeOutfitSlot, WardrobeItem> coSelected,
    required OutfitPreferenceProfile preferenceProfile,
    required FavoritePreferenceProfile favoriteProfile,
    required RecentOutfitSignals recentSignals,
    bool Function(WardrobeItem item)? predicate,
  }) {
    WardrobeItem? best;
    var bestScore = -1.0;

    for (final item in wardrobe) {
      if (WardrobeSlotClassifier.classify(item) != slot) continue;
      if (predicate != null && !predicate(item)) continue;

      final weatherFit = OutfitItemScorer.analyzeWeatherFit(
        item: item,
        weather: weather,
        context: context,
      );
      if (weatherFit.isRejected) continue;

      final score = OutfitItemScorer.score(
        item: item,
        context: context,
        weather: weather,
        colorType: colorType,
        bodyProfile: bodyProfile,
        coSelected: coSelected,
        preferenceProfile: preferenceProfile,
        favoriteProfile: favoriteProfile,
        recentSignals: recentSignals,
      );

      if (score > bestScore) {
        bestScore = score;
        best = item;
        if (weatherFit.boostedCategories.isNotEmpty) {
          AppLogger.info(
            'OutfitWeatherGuard: boosted ${weatherFit.boostedCategories.join(',')} '
            'for ${item.title}',
          );
        }
      }
    }

    return best;
  }

  static bool _needsWarmLayer(WeatherSnapshot weather) {
    final temp = weather.temperatureCelsius;
    if (temp != null && temp < 14) return true;
    return weather.conditions.contains(WeatherCondition.rainy) ||
        weather.conditions.contains(WeatherCondition.snowy);
  }

  static bool _needsOuterwear(WeatherSnapshot weather) => _needsOuterwearStrict(weather);

  static bool _needsOuterwearStrict(WeatherSnapshot weather) {
    final temp = weather.temperatureCelsius;
    if (temp != null && temp < 12) return true;
    return weather.conditions.contains(WeatherCondition.rainy) ||
        weather.conditions.contains(WeatherCondition.snowy) ||
        weather.conditions.contains(WeatherCondition.windy);
  }

  static bool _needsClosedShoes(WeatherSnapshot weather) {
    final temp = weather.temperatureCelsius;
    if (temp != null && temp < 14) return true;
    return weather.conditions.contains(WeatherCondition.rainy) ||
        weather.conditions.contains(WeatherCondition.snowy);
  }

  static bool isLightTop(WardrobeItem item) {
    if (WardrobeSlotClassifier.classify(item) != WardrobeOutfitSlot.top) {
      return false;
    }
    final title = item.title.toLowerCase();
    return title.contains('футбол') ||
        title.contains('майк') ||
        title.contains('t-shirt') ||
        title.contains('tee') ||
        (title.contains('топ') && !title.contains('толстов'));
  }

  static bool isWarmTop(WardrobeItem item) {
    final title = item.title.toLowerCase();
    final category = item.category.toLowerCase();
    return title.contains('худи') ||
        title.contains('hoodie') ||
        title.contains('свитер') ||
        title.contains('джемпер') ||
        title.contains('толстов') ||
        title.contains('водолаз') ||
        title.contains('лонгслив') ||
        title.contains('knit') ||
        category.contains('верхняя');
  }

  static bool isShortsLike(WardrobeItem item) {
    if (WardrobeSlotClassifier.classify(item) != WardrobeOutfitSlot.bottom) {
      return false;
    }
    final title = item.title.toLowerCase();
    return title.contains('шорт') || title.contains('short');
  }

  static bool isOpenShoes(String title) {
    final text = title.toLowerCase();
    return text.contains('сандал') ||
        text.contains('босонож') ||
        text.contains('шлёп') ||
        text.contains('шлеп') ||
        text.contains('сланц') ||
        text.contains('flip') ||
        text.contains('open');
  }

  static List<WardrobeItem> _orderOutfit(
    Map<WardrobeOutfitSlot, WardrobeItem> picked,
  ) {
    final result = <WardrobeItem>[];

    void add(WardrobeOutfitSlot slot) {
      final item = picked[slot];
      if (item != null) result.add(item);
    }

    if (picked.containsKey(WardrobeOutfitSlot.dress)) {
      add(WardrobeOutfitSlot.dress);
    } else {
      add(WardrobeOutfitSlot.top);
      add(WardrobeOutfitSlot.bottom);
    }
    add(WardrobeOutfitSlot.outerwear);
    add(WardrobeOutfitSlot.shoes);
    add(WardrobeOutfitSlot.accessory);

    return result.take(6).toList();
  }
}

class OutfitWeatherEvaluation {
  const OutfitWeatherEvaluation({
    required this.comfortScore,
    required this.isAcceptable,
    this.issues = const [],
  });

  final double comfortScore;
  final bool isAcceptable;
  final List<String> issues;
}
