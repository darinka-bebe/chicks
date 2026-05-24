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
      WardrobeOutfitSlot.top,
      WardrobeOutfitSlot.dress,
      WardrobeOutfitSlot.bottom,
      WardrobeOutfitSlot.outerwear,
      WardrobeOutfitSlot.shoes,
      WardrobeOutfitSlot.accessory,
    ];

    for (final slot in pickOrder) {
      final candidates = slotBuckets[slot];
      if (candidates == null || candidates.isEmpty) continue;

      picked[slot] = candidates.length == 1
          ? candidates.first
          : _pickBest(
              candidates,
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
      picked[slot] = candidates.length == 1
          ? candidates.first
          : _pickBest(
              candidates,
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

    _applyDressBaseRule(picked);

    var ordered = _orderOutfit(picked);

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
    for (final item in candidates) {
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

    if (scored.isEmpty) return candidates.first;

    scored.sort((a, b) => b.score.compareTo(a.score));
    final topScore = scored.first.score;
    final topCandidates = scored
        .where((row) => row.score >= topScore - varietyWindow)
        .map((row) => row.item)
        .toList();

    for (final item in topCandidates) {
      if (!recentSignals.recentItemIds.contains(item.id)) {
        return item;
      }
    }

    return topCandidates.first;
  }

  /// Dress replaces separate top + bottom in the same look.
  static void _applyDressBaseRule(Map<WardrobeOutfitSlot, WardrobeItem> picked) {
    if (!picked.containsKey(WardrobeOutfitSlot.dress)) return;
    picked.remove(WardrobeOutfitSlot.top);
    picked.remove(WardrobeOutfitSlot.bottom);
  }

  static List<WardrobeItem> _orderOutfit(
    Map<WardrobeOutfitSlot, WardrobeItem> picked,
  ) {
    final result = <WardrobeItem>[];

    void addSlot(WardrobeOutfitSlot slot) {
      final item = picked[slot];
      if (item != null) result.add(item);
    }

    if (picked.containsKey(WardrobeOutfitSlot.dress)) {
      addSlot(WardrobeOutfitSlot.dress);
    } else {
      addSlot(WardrobeOutfitSlot.top);
      addSlot(WardrobeOutfitSlot.bottom);
    }

    addSlot(WardrobeOutfitSlot.outerwear);
    addSlot(WardrobeOutfitSlot.shoes);
    addSlot(WardrobeOutfitSlot.accessory);

    if (result.length > _maxOutfitItems) {
      return result.take(_maxOutfitItems).toList();
    }

    return result;
  }
}
