import '../../data/models/chat_message.dart';
import '../../data/models/wardrobe_item.dart';
import '../../data/repositories/chat_history_repository.dart';
import '../../data/repositories/outfit_history_repository.dart';
import '../../data/repositories/wardrobe_repository.dart';
import '../utils/logger.dart';
import 'wardrobe_ai_context.dart';
import 'wardrobe_recommendation_sanitizer.dart';

/// Keeps AI prompts, chat, and history aligned with the live Hive wardrobe.
abstract final class WardrobeSyncService {
  /// Reads wardrobe straight from Hive (never a stale memory cache).
  static Future<List<WardrobeItem>> loadFreshWardrobeForAi() async {
    final items = await WardrobeRepository.instance.loadItems();
    WardrobeAiContext.instance.publishRepositorySnapshot(items);

    final ids = items.map((item) => item.id).toList();
    AppLogger.info(
      'WardrobeSync: loadFreshWardrobeForAi repositoryCount=${items.length} '
      'revision=${WardrobeAiContext.instance.revision}',
    );
    AppLogger.debug(
      'WardrobeSync: repository ids=[${ids.take(20).join(", ")}'
      '${ids.length > 20 ? ", …" : ""}]',
    );

    return List<WardrobeItem>.from(items);
  }

  /// Call after wardrobe add/update/delete persistence.
  static Future<void> afterWardrobeMutation({
    required String reason,
    String? deletedItemId,
  }) async {
    WardrobeAiContext.instance.invalidate(reason: reason);

    final wardrobe = await loadFreshWardrobeForAi();
    final wardrobeIds = wardrobe.map((item) => item.id).toList();

    AppLogger.info(
      'WardrobeSync: mutation="$reason" wardrobeCount=${wardrobe.length} '
      'revision=${WardrobeAiContext.instance.revision}',
    );
    if (deletedItemId != null && deletedItemId.trim().isNotEmpty) {
      AppLogger.info('WardrobeSync: deletedItemId=$deletedItemId');
    }
    AppLogger.debug(
      'WardrobeSync: current ids=[${wardrobeIds.take(20).join(", ")}'
      '${wardrobeIds.length > 20 ? ", …" : ""}]',
    );

    await _sanitizeChatHistory(wardrobe);
    await _sanitizeOutfitHistory(wardrobe);
  }

  static Future<void> _sanitizeChatHistory(List<WardrobeItem> wardrobe) async {
    final repo = ChatHistoryRepository.instance;
    final messages = await repo.loadMessages();
    if (messages.isEmpty) return;

    final sanitized =
        WardrobeRecommendationSanitizer.sanitizeChatMessages(messages, wardrobe);

    if (!_messagesRecommendationsEqual(sanitized, messages)) {
      await repo.saveMessages(sanitized);
      AppLogger.info(
        'WardrobeSync: chat history recommendations updated '
        '(${messages.length} messages)',
      );
    }
  }

  static Future<void> _sanitizeOutfitHistory(List<WardrobeItem> wardrobe) async {
    final repo = OutfitHistoryRepository.instance;
    final entries = await repo.loadEntries();
    if (entries.isEmpty) return;

    final sanitized =
        WardrobeRecommendationSanitizer.sanitizeHistoryEntries(entries, wardrobe);

    var changed = false;
    for (var i = 0; i < entries.length; i++) {
      if (entries[i].recommendedItemIds.length !=
          sanitized[i].recommendedItemIds.length) {
        changed = true;
        break;
      }
      for (var j = 0; j < entries[i].recommendedItemIds.length; j++) {
        if (!WardrobeRepository.idEquals(
          entries[i].recommendedItemIds[j],
          sanitized[i].recommendedItemIds[j],
        )) {
          changed = true;
          break;
        }
      }
      if (changed) break;
    }

    if (changed) {
      await repo.saveEntries(sanitized);
      AppLogger.info(
        'WardrobeSync: outfit history recommendations updated '
        '(${entries.length} entries)',
      );
    }
  }

  static bool _messagesRecommendationsEqual(
    List<ChatMessage> a,
    List<ChatMessage> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i].recommendedItemIds;
      final right = b[i].recommendedItemIds;
      if (left.length != right.length) return false;
      for (var j = 0; j < left.length; j++) {
        if (!WardrobeRepository.idEquals(left[j], right[j])) return false;
      }
    }
    return true;
  }
}
