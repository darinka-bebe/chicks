import '../../data/models/chat_message.dart';
import '../../data/models/outfit_history_entry.dart';
import '../../data/models/wardrobe_item.dart';
import '../../data/repositories/wardrobe_repository.dart';
import '../utils/logger.dart';
import 'wardrobe_recommendation_resolver.dart';

/// Strips deleted wardrobe ids from persisted recommendations.
abstract final class WardrobeRecommendationSanitizer {
  static List<String> filterIds({
    required List<String> ids,
    required List<WardrobeItem> wardrobe,
  }) {
    if (ids.isEmpty || wardrobe.isEmpty) return const [];

    final filtered = WardrobeRecommendationResolver.resolveItems(
      requestedIds: ids,
      wardrobe: wardrobe,
    ).map((item) => item.id).toList();

    if (filtered.length != ids.length) {
      final removed = <String>[];
      for (final raw in ids) {
        final kept = filtered.any(
          (id) => WardrobeRepository.idEquals(id, raw),
        );
        if (!kept) removed.add(raw);
      }
      AppLogger.info(
        'WardrobeRecommendationSanitizer: removed ${removed.length} '
        'unknown id(s) (wardrobe=${wardrobe.length})',
      );
      if (removed.isNotEmpty) {
        AppLogger.debug('WardrobeRecommendationSanitizer: removed ids=$removed');
      }
    }

    return filtered;
  }

  static List<ChatMessage> sanitizeChatMessages(
    List<ChatMessage> messages,
    List<WardrobeItem> wardrobe,
  ) {
    if (messages.isEmpty) return messages;

    var changed = false;
    final result = <ChatMessage>[];

    for (final message in messages) {
      if (message.role != ChatRole.assistant ||
          message.recommendedItemIds.isEmpty) {
        result.add(message);
        continue;
      }

      final filtered = filterIds(
        ids: message.recommendedItemIds,
        wardrobe: wardrobe,
      );

      if (!_idsEqual(filtered, message.recommendedItemIds)) {
        changed = true;
        result.add(
          ChatMessage(
            id: message.id,
            role: message.role,
            content: message.content,
            createdAt: message.createdAt,
            recommendedItemIds: filtered,
            weatherLabel: message.weatherLabel,
          ),
        );
      } else {
        result.add(message);
      }
    }

    if (changed) {
      AppLogger.info(
        'WardrobeRecommendationSanitizer: cleaned chat message recommendations',
      );
    }

    return result;
  }

  static List<OutfitHistoryEntry> sanitizeHistoryEntries(
    List<OutfitHistoryEntry> entries,
    List<WardrobeItem> wardrobe,
  ) {
    if (entries.isEmpty) return entries;

    var changed = false;
    final result = <OutfitHistoryEntry>[];

    for (final entry in entries) {
      if (entry.recommendedItemIds.isEmpty) {
        result.add(entry);
        continue;
      }

      final filtered = filterIds(
        ids: entry.recommendedItemIds,
        wardrobe: wardrobe,
      );

      if (!_idsEqual(filtered, entry.recommendedItemIds)) {
        changed = true;
        result.add(
          OutfitHistoryEntry(
            id: entry.id,
            createdAt: entry.createdAt,
            title: entry.title,
            userPrompt: entry.userPrompt,
            aiResponseText: entry.aiResponseText,
            recommendedItemIds: filtered,
            weatherLabel: entry.weatherLabel,
            moods: entry.moods,
            occasions: entry.occasions,
            weather: entry.weather,
          ),
        );
      } else {
        result.add(entry);
      }
    }

    if (changed) {
      AppLogger.info(
        'WardrobeRecommendationSanitizer: cleaned outfit history recommendations',
      );
    }

    return result;
  }

  static bool _idsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!WardrobeRepository.idEquals(a[i], b[i])) return false;
    }
    return true;
  }
}
