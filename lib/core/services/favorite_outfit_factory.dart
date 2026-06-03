import '../../data/models/favorite_outfit.dart';
import '../models/stylist_request_context.dart';
import 'outfit_content_hasher.dart';
import 'outfit_title_extractor.dart';
import 'stylist_context_parser.dart';

/// Creates [FavoriteOutfit] from chat messages and parsed context.
abstract final class FavoriteOutfitFactory {
  static FavoriteOutfit fromAiRecommendation({
    required String recommendation,
    String? userPrompt,
    List<String> recommendedItemIds = const [],
  }) {
    final trimmed = recommendation.trim();
    final promptContext = userPrompt != null && userPrompt.trim().isNotEmpty
        ? StylistContextParser.parse(userPrompt)
        : StylistRequestContext.empty;

    final contentContext = StylistContextParser.parse(trimmed);
    final merged = promptContext.merge(contentContext);

    return FavoriteOutfit(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: OutfitTitleExtractor.fromRecommendation(trimmed),
      recommendation: trimmed,
      contentHash: OutfitContentHasher.hash(trimmed),
      createdAt: DateTime.now(),
      moods: merged.moods,
      occasions: merged.occasions,
      weather: merged.weather,
      recommendedItemIds: recommendedItemIds
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList(),
    );
  }
}
