import '../../data/models/wardrobe_item.dart';
import '../models/seasonal_color_type.dart';
import '../models/stylist_request_context.dart';
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
  }) {
    return curateItems(
      requestedIds: requestedIds,
      wardrobe: wardrobe,
      context: context,
      weather: weather,
      colorType: colorType,
    ).map((item) => item.id).toList();
  }

  static List<WardrobeItem> curateItems({
    required List<String> requestedIds,
    required List<WardrobeItem> wardrobe,
    StylistRequestContext context = StylistRequestContext.empty,
    WeatherSnapshot? weather,
    SeasonalColorType? colorType,
  }) {
    if (requestedIds.isEmpty || wardrobe.isEmpty) return const [];

    try {
      return _curateItemsUnsafe(
        requestedIds: requestedIds,
        wardrobe: wardrobe,
        context: context,
        weather: weather,
        colorType: colorType,
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

    for (final entry in slotBuckets.entries) {
      final slot = entry.key;
      if (slot == WardrobeOutfitSlot.unknown) continue;

      final candidates = entry.value;
      if (candidates.length == 1) {
        picked[slot] = candidates.first;
      } else {
        picked[slot] = _pickBest(
          candidates,
          context: context,
          weather: weather,
          colorType: colorType,
        );
      }
    }

    _applyDressBaseRule(picked);

    final ordered = _orderOutfit(picked);

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
  }) {
    WardrobeItem? best;
    var bestScore = double.negativeInfinity;

    for (final item in candidates) {
      final score = OutfitItemScorer.score(
        item: item,
        context: context,
        weather: weather,
        colorType: colorType,
      );
      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }

    return best ?? candidates.first;
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
