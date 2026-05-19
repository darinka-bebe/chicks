import '../../data/models/wardrobe_item.dart';
import '../models/stylist_request_context.dart';
import '../models/stylist_response.dart';
import '../models/wardrobe_outfit_slot.dart';
import '../models/weather_snapshot.dart';
import '../utils/logger.dart';
import 'wardrobe_outfit_grouper.dart';

/// Defensive helpers — keeps the stylist pipeline from crashing on bad data.
abstract final class StylistPipelineSafety {
  static const String fallbackAssistantMessage =
      'Сейчас не получилось собрать ответ 😔 '
      'Попробуй отправить запрос ещё раз через пару секунд — я на связи!';

  static const String emptyWardrobeSection = '''
ГАРДЕРОБ ПОЛЬЗОВАТЕЛЯ:
Список вещей пуст. Дай универсальные советы по стилю.
recommendedItemIds: [].''';

  /// Drops invalid wardrobe rows and normalizes text fields.
  static List<WardrobeItem> sanitizeWardrobe(List<WardrobeItem> items) {
    final result = <WardrobeItem>[];
    for (final item in items) {
      try {
        final id = item.id.trim();
        final title = item.title.trim();
        if (id.isEmpty || title.isEmpty) continue;

        result.add(
          WardrobeItem(
            id: id,
            title: title,
            category: _orDefault(item.category, 'Верх'),
            color: _orDefault(item.color, 'не указан'),
            season: _orDefault(item.season, 'Всесезон'),
            fit: item.fit.trim(),
            styles: _cleanList(item.styles),
            occasions: _cleanList(item.occasions),
            vibes: _cleanList(item.vibes),
            imagePath: item.imagePath,
          ),
        );
      } catch (e) {
        AppLogger.warning(
          'StylistPipelineSafety: skipped corrupt wardrobe item ($e)',
        );
      }
    }
    return result;
  }

  static String _orDefault(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  static List<String> _cleanList(List<String> values) {
    return values.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  /// Never throws — returns empty buckets on failure.
  static Map<WardrobeOutfitSlot, List<WardrobeItem>> safeGroup(
    List<WardrobeItem> items,
  ) {
    try {
      return WardrobeOutfitGrouper.group(sanitizeWardrobe(items));
    } catch (e, stack) {
      AppLogger.error(
        'StylistPipelineSafety: safeGroup failed',
        error: e,
        stackTrace: stack,
      );
      return WardrobeOutfitGrouper.emptyGrouped();
    }
  }

  static List<WardrobeItem> itemsForSlot(
    Map<WardrobeOutfitSlot, List<WardrobeItem>> grouped,
    WardrobeOutfitSlot slot,
  ) {
    return grouped[slot] ?? const [];
  }

  /// OpenAI rejects empty message content — ensure valid roles and text.
  static List<Map<String, String>> sanitizeApiMessages(
    List<Map<String, String>> messages,
  ) {
    final sanitized = <Map<String, String>>[];

    for (final message in messages) {
      final role = message['role']?.trim() ?? 'user';
      if (role != 'system' && role != 'user' && role != 'assistant') {
        continue;
      }

      var content = message['content']?.trim() ?? '';
      if (content.isEmpty) {
        content = role == 'system' ? ' ' : '…';
      }

      sanitized.add({'role': role, 'content': content});
    }

    return sanitized;
  }

  static StylistResponse fallbackResponse({
    List<String> recommendedItemIds = const [],
  }) {
    return StylistResponse(
      message: fallbackAssistantMessage,
      recommendedItemIds: recommendedItemIds,
    );
  }

  static WeatherSnapshot safeWeather(WeatherSnapshot? weather) {
    return weather ?? WeatherSnapshot.unavailable;
  }

  static StylistRequestContext safeContext(StylistRequestContext? context) {
    return context ?? StylistRequestContext.empty;
  }
}
