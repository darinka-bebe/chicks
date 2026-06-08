import '../../data/models/wardrobe_item.dart';
import '../models/body_profile.dart';
import '../models/favorite_preference_profile.dart';
import '../models/outfit_preference_profile.dart';
import '../models/recent_outfit_signals.dart';
import '../models/seasonal_color_type.dart';
import '../models/stylist_request_context.dart';
import 'silhouette_balancer.dart';
import '../models/wardrobe_outfit_slot.dart';
import '../models/weather_snapshot.dart';
import '../utils/logger.dart';
import 'outfit_item_scorer.dart';
import 'outfit_weather_guard.dart';
import 'outfit_base_slot_rules.dart';
import 'wardrobe_recommendation_resolver.dart';
import 'wardrobe_slot_classifier.dart';

/// Post-processes AI outfit picks: one item per slot, cohesive order, best fit.
abstract final class OutfitRecommendationCurator {
  static const _maxOutfitItems = 6;

  /// Validates, deduplicates by slot, and orders items like a stylist would.
  static List<String> curateIds({
    required List<String> requestedIds,
    required List<WardrobeItem> wardrobe,
    StylistRequestContext context = StylistRequestContext.empty,
    WeatherSnapshot? weather,
    SeasonalColorType? colorType,
    BodyProfile? bodyProfile,
    OutfitPreferenceProfile preferenceProfile = OutfitPreferenceProfile.empty,
    FavoritePreferenceProfile favoriteProfile = FavoritePreferenceProfile.empty,
    RecentOutfitSignals recentSignals = RecentOutfitSignals.empty,
  }) {
    return curateItems(
      requestedIds: requestedIds,
      wardrobe: wardrobe,
      context: context,
      weather: weather,
      colorType: colorType,
      bodyProfile: bodyProfile,
      preferenceProfile: preferenceProfile,
      favoriteProfile: favoriteProfile,
      recentSignals: recentSignals,
    ).map((item) => item.id).toList();
  }

  static List<WardrobeItem> curateItems({
    required List<String> requestedIds,
    required List<WardrobeItem> wardrobe,
    StylistRequestContext context = StylistRequestContext.empty,
    WeatherSnapshot? weather,
    SeasonalColorType? colorType,
    BodyProfile? bodyProfile,
    OutfitPreferenceProfile preferenceProfile = OutfitPreferenceProfile.empty,
    FavoritePreferenceProfile favoriteProfile = FavoritePreferenceProfile.empty,
    RecentOutfitSignals recentSignals = RecentOutfitSignals.empty,
  }) {
    if (requestedIds.isEmpty || wardrobe.isEmpty) return const [];

    try {
      return _curateItemsUnsafe(
        requestedIds: requestedIds,
        wardrobe: wardrobe,
        context: context,
        weather: weather,
        colorType: colorType,
        bodyProfile: bodyProfile,
        preferenceProfile: preferenceProfile,
        favoriteProfile: favoriteProfile,
        recentSignals: recentSignals,
      );
    } catch (e, stack) {
      AppLogger.error(
        'OutfitRecommendationCurator: curate failed',
        error: e,
        stackTrace: stack,
      );
      return WardrobeRecommendationResolver.resolveItems(
        requestedIds: requestedIds,
        wardrobe: wardrobe,
      );
    }
  }

  static List<WardrobeItem> _curateItemsUnsafe({
    required List<String> requestedIds,
    required List<WardrobeItem> wardrobe,
    required StylistRequestContext context,
    WeatherSnapshot? weather,
    SeasonalColorType? colorType,
    BodyProfile? bodyProfile,
    OutfitPreferenceProfile preferenceProfile = OutfitPreferenceProfile.empty,
    FavoritePreferenceProfile favoriteProfile = FavoritePreferenceProfile.empty,
    RecentOutfitSignals recentSignals = RecentOutfitSignals.empty,
  }) {
    final resolved = WardrobeRecommendationResolver.resolveItems(
      requestedIds: requestedIds,
      wardrobe: wardrobe,
    );

    if (resolved.isEmpty) return const [];

    final slotBuckets = <WardrobeOutfitSlot, List<WardrobeItem>>{};

    for (final item in resolved) {
      final slot = WardrobeSlotClassifier.classify(item);
      slotBuckets.putIfAbsent(slot, () => []).add(item);
    }

    final picked = <WardrobeOutfitSlot, WardrobeItem>{};
    final pickOrder = [
      WardrobeOutfitSlot.set,
      WardrobeOutfitSlot.dress,
      WardrobeOutfitSlot.top,
      WardrobeOutfitSlot.bottom,
      WardrobeOutfitSlot.outerwear,
      WardrobeOutfitSlot.shoes,
      WardrobeOutfitSlot.accessory,
    ];

    for (final slot in pickOrder) {
      final candidates = slotBuckets[slot];
      if (candidates == null || candidates.isEmpty) continue;

      picked[slot] = _pickForSlot(
        candidates: candidates,
        slot: slot,
        wardrobe: wardrobe,
        context: context,
        weather: weather,
        colorType: colorType,
        bodyProfile: bodyProfile,
        coSelected: picked,
        preferenceProfile: preferenceProfile,
        favoriteProfile: favoriteProfile,
        recentSignals: recentSignals,
      );
    }

    for (final entry in slotBuckets.entries) {
      final slot = entry.key;
      if (slot == WardrobeOutfitSlot.unknown || picked.containsKey(slot)) {
        continue;
      }
      final candidates = entry.value;
      picked[slot] = _pickForSlot(
        candidates: candidates,
        slot: slot,
        wardrobe: wardrobe,
        context: context,
        weather: weather,
        colorType: colorType,
        bodyProfile: bodyProfile,
        coSelected: picked,
        preferenceProfile: preferenceProfile,
        favoriteProfile: favoriteProfile,
        recentSignals: recentSignals,
      );
    }

    OutfitBaseSlotRules.resolveBaseConflicts(picked);

    var ordered = _orderOutfit(picked);

    if (weather != null && weather.isAvailable) {
      ordered = OutfitWeatherGuard.repairOutfit(
        current: ordered,
        wardrobe: wardrobe,
        weather: weather,
        context: context,
        colorType: colorType,
        bodyProfile: bodyProfile,
        preferenceProfile: preferenceProfile,
        favoriteProfile: favoriteProfile,
        recentSignals: recentSignals,
      );
    }

    if (bodyProfile != null && ordered.length >= 2) {
      final harmony =
          SilhouetteBalancer.outfitHarmonyScore(picked, bodyProfile);
      if (harmony < 0.45) {
        AppLogger.info(
          'OutfitRecommendationCurator: low silhouette harmony=${harmony.toStringAsFixed(2)} '
          'for ${bodyProfile.shape.englishLabel}',
        );
      }
    }

    if (requestedIds.length != ordered.length) {
      AppLogger.info(
        'OutfitRecommendationCurator: ${requestedIds.length} → ${ordered.length} '
        '(removed duplicate/conflicting slots)',
      );
    }

    return ordered;
  }

  static WardrobeItem _pickForSlot({
    required List<WardrobeItem> candidates,
    required WardrobeOutfitSlot slot,
    required List<WardrobeItem> wardrobe,
    required StylistRequestContext context,
    WeatherSnapshot? weather,
    SeasonalColorType? colorType,
    BodyProfile? bodyProfile,
    required Map<WardrobeOutfitSlot, WardrobeItem> coSelected,
    required OutfitPreferenceProfile preferenceProfile,
    required FavoritePreferenceProfile favoriteProfile,
    required RecentOutfitSignals recentSignals,
  }) {
    final picked = candidates.length == 1
        ? candidates.first
        : _pickBest(
            candidates,
            context: context,
            weather: weather,
            colorType: colorType,
            bodyProfile: bodyProfile,
            coSelected: coSelected,
            preferenceProfile: preferenceProfile,
            favoriteProfile: favoriteProfile,
            recentSignals: recentSignals,
          );

    if (weather == null || !weather.isAvailable) return picked;

    final fit = OutfitItemScorer.analyzeWeatherFit(
      item: picked,
      weather: weather,
      context: context,
    );
    if (!fit.isRejected) return picked;

    AppLogger.info(
      'OutfitRecommendationCurator: AI slot pick rejected for weather '
      '${picked.title}, searching wardrobe',
    );

    final replacement = _bestBySlotFromWardrobe(
      wardrobe: wardrobe,
      slot: slot,
      context: context,
      weather: weather,
      colorType: colorType,
      bodyProfile: bodyProfile,
      coSelected: coSelected,
      preferenceProfile: preferenceProfile,
      favoriteProfile: favoriteProfile,
      recentSignals: recentSignals,
      predicate: (item) {
        final candidateFit = OutfitItemScorer.analyzeWeatherFit(
          item: item,
          weather: weather,
          context: context,
        );
        return !candidateFit.isRejected;
      },
    );

    return replacement ?? picked;
  }

  static WardrobeItem? _bestBySlotFromWardrobe({
    required List<WardrobeItem> wardrobe,
    required WardrobeOutfitSlot slot,
    required StylistRequestContext context,
    required WeatherSnapshot weather,
    SeasonalColorType? colorType,
    BodyProfile? bodyProfile,
    required Map<WardrobeOutfitSlot, WardrobeItem> coSelected,
    required OutfitPreferenceProfile preferenceProfile,
    required FavoritePreferenceProfile favoriteProfile,
    required RecentOutfitSignals recentSignals,
    bool Function(WardrobeItem item)? predicate,
  }) {
    final candidates = wardrobe.where((item) {
      if (WardrobeSlotClassifier.classify(item) != slot) return false;
      return predicate == null || predicate(item);
    }).toList();
    if (candidates.isEmpty) return null;
    return _pickBest(
      candidates,
      context: context,
      weather: weather,
      colorType: colorType,
      bodyProfile: bodyProfile,
      coSelected: coSelected,
      preferenceProfile: preferenceProfile,
      favoriteProfile: favoriteProfile,
      recentSignals: recentSignals,
    );
  }

  static WardrobeItem _pickBest(
    List<WardrobeItem> candidates, {
    required StylistRequestContext context,
    WeatherSnapshot? weather,
    SeasonalColorType? colorType,
    BodyProfile? bodyProfile,
    Map<WardrobeOutfitSlot, WardrobeItem>? coSelected,
    OutfitPreferenceProfile preferenceProfile = OutfitPreferenceProfile.empty,
    FavoritePreferenceProfile favoriteProfile = FavoritePreferenceProfile.empty,
    RecentOutfitSignals recentSignals = RecentOutfitSignals.empty,
  }) {
    const varietyWindow = 3.0;

    final scored = <({WardrobeItem item, double score})>[];
    final weatherAnalyses = <String, WeatherFitAnalysis>{};
    for (final item in candidates) {
      final weatherFit = OutfitItemScorer.analyzeWeatherFit(
        item: item,
        weather: weather,
        context: context,
      );
      weatherAnalyses[item.id] = weatherFit;
      if (weatherFit.isRejected) {
        AppLogger.info(
          'OutfitRecommendationCurator: rejected weather-unrealistic item '
          '${item.title} [penalties=${weatherFit.penalties.join(',')}]',
        );
        continue;
      }
      scored.add((
        item: item,
        score: OutfitItemScorer.score(
          item: item,
          context: context,
          weather: weather,
          colorType: colorType,
          bodyProfile: bodyProfile,
          coSelected: coSelected,
          preferenceProfile: preferenceProfile,
          favoriteProfile: favoriteProfile,
          recentSignals: recentSignals,
        ),
      ));
    }

    if (scored.isEmpty) {
      final softScored = <({WardrobeItem item, double score})>[];
      for (final item in candidates) {
        softScored.add((
          item: item,
          score: OutfitItemScorer.score(
            item: item,
            context: context,
            weather: weather,
            colorType: colorType,
            bodyProfile: bodyProfile,
            coSelected: coSelected,
            preferenceProfile: preferenceProfile,
            favoriteProfile: favoriteProfile,
            recentSignals: recentSignals,
          ),
        ));
      }
      if (softScored.isEmpty) return candidates.first;
      softScored.sort((a, b) => b.score.compareTo(a.score));
      AppLogger.info(
        'OutfitRecommendationCurator: all candidates hard-rejected, '
        'using soft fallback ${softScored.first.item.title}',
      );
      return softScored.first.item;
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final topScore = scored.first.score;
    final topCandidates = scored
        .where((row) => row.score >= topScore - varietyWindow)
        .map((row) => row.item)
        .toList();

    for (final item in topCandidates) {
      if (!recentSignals.recentItemIds.contains(item.id)) {
        _logPickedWeatherDiagnostics(item, weatherAnalyses[item.id]);
        return item;
      }
    }

    _logPickedWeatherDiagnostics(topCandidates.first, weatherAnalyses[topCandidates.first.id]);
    return topCandidates.first;
  }

  static void _logPickedWeatherDiagnostics(
    WardrobeItem item,
    WeatherFitAnalysis? weatherFit,
  ) {
    if (weatherFit == null) return;
    AppLogger.info(
      'OutfitRecommendationCurator: weather score=${weatherFit.weatherScore.toStringAsFixed(2)} '
      'temp_penalty=${weatherFit.temperaturePenalty.toStringAsFixed(2)} '
      'item=${item.title}',
    );
    if (weatherFit.boostedCategories.isNotEmpty) {
      AppLogger.info(
        'OutfitRecommendationCurator: boosted categories '
        '${weatherFit.boostedCategories.join(', ')}',
      );
    }
  }

  /// Dress replaces separate top + bottom in the same look.
  static List<WardrobeItem> _orderOutfit(
    Map<WardrobeOutfitSlot, WardrobeItem> picked,
  ) {
    final result = <WardrobeItem>[];

    void addSlot(WardrobeOutfitSlot slot) {
      final item = picked[slot];
      if (item != null) result.add(item);
    }

    OutfitBaseSlotRules.appendBaseItems(picked, addSlot);

    addSlot(WardrobeOutfitSlot.outerwear);
    addSlot(WardrobeOutfitSlot.shoes);
    addSlot(WardrobeOutfitSlot.accessory);

    if (result.length > _maxOutfitItems) {
      return result.take(_maxOutfitItems).toList();
    }

    return result;
  }
}
