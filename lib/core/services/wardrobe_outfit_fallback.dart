import '../../data/models/wardrobe_item.dart';
import '../models/body_profile.dart';
import '../models/favorite_preference_profile.dart';
import '../models/outfit_preference_profile.dart';
import '../models/recent_outfit_signals.dart';
import '../models/seasonal_color_type.dart';
import '../models/stylist_request_context.dart';
import '../models/wardrobe_outfit_slot.dart';
import '../models/weather_snapshot.dart';
import '../utils/logger.dart';
import 'outfit_item_scorer.dart';
import 'wardrobe_slot_classifier.dart';

/// Builds a complete outfit from the wardrobe when the model omits or botches ids.
abstract final class WardrobeOutfitFallback {
  static List<WardrobeItem> build({
    required List<WardrobeItem> wardrobe,
    StylistRequestContext context = StylistRequestContext.empty,
    WeatherSnapshot? weather,
    SeasonalColorType? colorType,
    BodyProfile? bodyProfile,
    OutfitPreferenceProfile preferenceProfile =
        OutfitPreferenceProfile.empty,
    FavoritePreferenceProfile favoriteProfile = FavoritePreferenceProfile.empty,
    RecentOutfitSignals recentSignals = RecentOutfitSignals.empty,
  }) {
    if (wardrobe.isEmpty) return const [];

    final buckets = <WardrobeOutfitSlot, List<WardrobeItem>>{};
    for (final item in wardrobe) {
      final slot = WardrobeSlotClassifier.classify(item);
      if (slot == WardrobeOutfitSlot.unknown) continue;
      buckets.putIfAbsent(slot, () => []).add(item);
    }

    final picked = <WardrobeOutfitSlot, WardrobeItem>{};
    final order = [
      WardrobeOutfitSlot.dress,
      WardrobeOutfitSlot.top,
      WardrobeOutfitSlot.bottom,
      WardrobeOutfitSlot.outerwear,
      WardrobeOutfitSlot.shoes,
      WardrobeOutfitSlot.accessory,
    ];

    for (final slot in order) {
      if (slot == WardrobeOutfitSlot.top &&
          picked.containsKey(WardrobeOutfitSlot.dress)) {
        continue;
      }
      if ((slot == WardrobeOutfitSlot.top ||
              slot == WardrobeOutfitSlot.bottom) &&
          picked.containsKey(WardrobeOutfitSlot.dress)) {
        continue;
      }

      final candidates = buckets[slot];
      if (candidates == null || candidates.isEmpty) continue;

      picked[slot] = _pickBest(
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

    if (result.length >= 2) {
      AppLogger.info(
        'WardrobeOutfitFallback: built ${result.length} item(s) '
        'for context=${context.moods}',
      );
    }

    return result.length >= 2 ? result.take(6).toList() : const [];
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

  /// Injects «Состав образа» when the model left the section empty.
  static String enrichMessage({
    required String message,
    required List<WardrobeItem> items,
  }) {
    if (items.isEmpty) return message;

    final hasQuotedItems = RegExp(r'«[^»]+»').hasMatch(message);
    if (hasQuotedItems) return message;

    final lines = items.map((item) {
      final slot = WardrobeSlotClassifier.classify(item);
      final label = _slotLabelRu(slot);
      return '• $label: «${item.title}»';
    }).join('\n');

    final block = '**Состав образа:**\n$lines';

    if (message.contains('Состав образа') || message.contains('Образ:')) {
      return message.replaceFirst(
        RegExp(r'(Состав образа|Образ)\s*:?\s*\n?'),
        '$block\n\n',
      );
    }

    return '$block\n\n$message';
  }

  static String _slotLabelRu(WardrobeOutfitSlot slot) => switch (slot) {
        WardrobeOutfitSlot.top => 'Верх',
        WardrobeOutfitSlot.bottom => 'Низ',
        WardrobeOutfitSlot.dress => 'Платье',
        WardrobeOutfitSlot.outerwear => 'Верхняя одежда',
        WardrobeOutfitSlot.shoes => 'Обувь',
        WardrobeOutfitSlot.accessory => 'Аксессуар',
        WardrobeOutfitSlot.unknown => 'Вещь',
      };
}
