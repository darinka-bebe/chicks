import '../../data/models/outfit_history_entry.dart';
import '../models/stylist_request_context.dart';
import 'outfit_title_extractor.dart';
import 'stylist_context_parser.dart';

/// Builds [OutfitHistoryEntry] from a successful stylist exchange.
abstract final class OutfitHistoryFactory {
  static OutfitHistoryEntry fromStylistExchange({
    required String assistantMessageId,
    required String userPrompt,
    required String aiResponseText,
    List<String> recommendedItemIds = const [],
    String? weatherLabel,
    DateTime? createdAt,
  }) {
    final trimmedResponse = aiResponseText.trim();
    final trimmedPrompt = userPrompt.trim();

    final promptContext = trimmedPrompt.isNotEmpty
        ? StylistContextParser.parse(trimmedPrompt)
        : StylistRequestContext.empty;
    final responseContext = StylistContextParser.parse(trimmedResponse);
    final merged = promptContext.merge(responseContext);

    return OutfitHistoryEntry(
      id: assistantMessageId,
      createdAt: createdAt ?? DateTime.now(),
      title: OutfitTitleExtractor.fromRecommendation(trimmedResponse),
      userPrompt: trimmedPrompt,
      aiResponseText: trimmedResponse,
      recommendedItemIds: recommendedItemIds,
      weatherLabel: weatherLabel?.trim().isNotEmpty == true
          ? weatherLabel!.trim()
          : null,
      moods: merged.moods,
      occasions: merged.occasions,
      weather: merged.weather,
    );
  }
}
