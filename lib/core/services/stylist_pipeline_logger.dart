import '../../data/models/wardrobe_item.dart';
import '../models/stylist_request_context.dart';
import '../models/wardrobe_outfit_slot.dart';
import '../models/weather_snapshot.dart';
import '../utils/logger.dart';
import 'stylist_pipeline_safety.dart';

/// Debug logging for the AI stylist request pipeline.
abstract final class StylistPipelineLogger {
  static const int _promptPreviewChars = 400;

  static void logRequestStart({
    required String userMessage,
    required StylistRequestContext context,
    required WeatherSnapshot weather,
    required int wardrobeCount,
    required int historyLength,
  }) {
    AppLogger.info(
      'StylistPipeline: start userLen=${userMessage.length} '
      'wardrobe=$wardrobeCount history=$historyLength',
    );
    AppLogger.debug(
      'StylistPipeline: context moods=${context.moods} '
      'weather=${context.weather} occasions=${context.occasions}',
    );
    AppLogger.debug(
      'StylistPipeline: liveWeather available=${weather.isAvailable} '
      'label=${weather.isAvailable ? weather.compactUiLabel : "n/a"} '
      'temp=${weather.temperatureCelsius}',
    );
  }

  static void logSystemMessages(List<Map<String, String>> messages) {
    var totalChars = 0;
    for (var i = 0; i < messages.length; i++) {
      final content = messages[i]['content'] ?? '';
      totalChars += content.length;
      final role = messages[i]['role'] ?? '?';
      AppLogger.debug(
        'StylistPipeline: system[$i] role=$role len=${content.length} '
        'preview=${_preview(content)}',
      );
    }
    final estimatedTokens = (totalChars / 4).ceil();
    AppLogger.info(
      'StylistPipeline: ${messages.length} system message(s), '
      '$totalChars chars, ~$estimatedTokens tokens (estimate)',
    );
  }

  static void logCategorizedWardrobe(List<WardrobeItem> items) {
    final grouped = StylistPipelineSafety.safeGroup(items);
    final parts = <String>[];
    for (final slot in WardrobeOutfitSlotX.outfitOrder) {
      final count =
          StylistPipelineSafety.itemsForSlot(grouped, slot).length;
      if (count > 0) parts.add('${slot.name}=$count');
    }
    final unknown =
        StylistPipelineSafety.itemsForSlot(grouped, WardrobeOutfitSlot.unknown)
            .length;
    if (unknown > 0) parts.add('unknown=$unknown');

    AppLogger.debug('StylistPipeline: categorized slots → ${parts.join(', ')}');

    for (final slot in WardrobeOutfitSlotX.outfitOrder) {
      final slotItems = StylistPipelineSafety.itemsForSlot(grouped, slot);
      if (slotItems.isEmpty) continue;
      final ids = slotItems.map((i) => i.id).take(8).join(', ');
      AppLogger.debug('StylistPipeline: slot ${slot.name} ids=[$ids]');
    }
  }

  static void logWardrobeItems(List<WardrobeItem> items) {
    if (items.isEmpty) {
      AppLogger.debug('StylistPipeline: wardrobe empty');
      return;
    }
    final summary = items
        .take(12)
        .map((i) => '${i.id}:${i.category}:${i.title}')
        .join(' | ');
    AppLogger.debug(
      'StylistPipeline: wardrobe items (first ${items.length.clamp(0, 12)}): $summary',
    );
  }

  static void logApiRequest({
    required int messageCount,
    required int bodyBytes,
    required String model,
  }) {
    AppLogger.info(
      'StylistPipeline: OpenAI POST messages=$messageCount '
      'bodyBytes=$bodyBytes model=$model',
    );
  }

  static void logApiResponse({
    required int statusCode,
    required int bodyBytes,
  }) {
    AppLogger.info(
      'StylistPipeline: OpenAI response status=$statusCode bodyBytes=$bodyBytes',
    );
  }

  static void logRecommendationSource({
    required List<String> sourceIds,
    required List<String> resultIds,
    required int wardrobeCount,
  }) {
    AppLogger.info(
      'StylistPipeline: recommendation source wardrobeCount=$wardrobeCount '
      'raw=${sourceIds.length} result=${resultIds.length}',
    );
    if (sourceIds.isNotEmpty) {
      AppLogger.debug('StylistPipeline: AI raw ids=$sourceIds');
    }
    if (resultIds.isNotEmpty) {
      AppLogger.debug('StylistPipeline: curated ids=$resultIds');
    }
    final dropped = sourceIds.length - resultIds.length;
    if (dropped > 0) {
      AppLogger.info(
        'StylistPipeline: dropped $dropped id(s) not in current wardrobe',
      );
    }
  }

  static void logParsedResponse({
    required int messageLength,
    required List<String> rawIds,
    required List<String> curatedIds,
  }) {
    AppLogger.info(
      'StylistPipeline: parsed messageLen=$messageLength '
      'ids raw=${rawIds.length} curated=${curatedIds.length}',
    );
    if (rawIds.isNotEmpty) {
      AppLogger.debug('StylistPipeline: rawIds=$rawIds');
    }
    if (curatedIds.isNotEmpty) {
      AppLogger.debug('StylistPipeline: curatedIds=$curatedIds');
    }
  }

  static void logFailure(
    String stage,
    Object error,
    StackTrace stackTrace,
  ) {
    AppLogger.error(
      'StylistPipeline: FAILED at $stage',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static String _preview(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= _promptPreviewChars) return normalized;
    return '${normalized.substring(0, _promptPreviewChars)}…';
  }
}
