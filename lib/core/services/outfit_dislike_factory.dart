import '../../data/models/outfit_dislike_entry.dart';
import '../../data/models/wardrobe_item.dart';
import 'outfit_content_hasher.dart';
import 'outfit_trait_extractor.dart';

/// Builds [OutfitDislikeEntry] from a stylist recommendation.
abstract final class OutfitDislikeFactory {
  static OutfitDislikeEntry create({
    required String recommendationText,
    required List<WardrobeItem> wardrobeItems,
    required List<String> recommendedItemIds,
    String? userPrompt,
  }) {
    final trimmed = recommendationText.trim();
    final resolved = _resolveItems(wardrobeItems, recommendedItemIds);
    final traits = OutfitTraitExtractor.extract(
      items: resolved,
      recommendationText: trimmed,
      userPrompt: userPrompt,
    );

    return OutfitDislikeEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      contentHash: OutfitContentHasher.hash(trimmed),
      createdAt: DateTime.now(),
      recommendationText: trimmed,
      recommendedItemIds: recommendedItemIds,
      styles: traits.styles,
      colors: traits.colors,
      silhouettes: traits.silhouettes,
      combinationKey: traits.combinationKey,
      moods: traits.moods,
      occasions: traits.occasions,
    );
  }

  static List<WardrobeItem> _resolveItems(
    List<WardrobeItem> wardrobe,
    List<String> ids,
  ) {
    if (ids.isEmpty) return const [];
    final byId = {for (final item in wardrobe) item.id: item};
    return ids
        .map((id) => byId[id])
        .whereType<WardrobeItem>()
        .toList(growable: false);
  }
}
