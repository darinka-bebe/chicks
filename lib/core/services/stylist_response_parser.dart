import 'dart:convert';

import '../models/stylist_response.dart';
import '../utils/logger.dart';

/// Parses OpenAI JSON stylist replies; falls back to plain text on failure.
abstract final class StylistResponseParser {
  static const _messageKeys = ['message', 'text', 'reply', 'content'];
  static const _idListKeys = [
    'recommendedItemIds',
    'recommendedItems',
    'itemIds',
    'wardrobeItemIds',
  ];

  static StylistResponse parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const StylistResponse(message: '');
    }

    final jsonPayload = _extractJsonObject(trimmed);
    if (jsonPayload == null) {
      AppLogger.debug(
        'StylistResponseParser: no JSON — using plain text (${trimmed.length} chars)',
      );
      return StylistResponse(message: trimmed);
    }

    try {
      final map = jsonDecode(jsonPayload) as Map<String, dynamic>;
      final message = _readMessage(map);
      final ids = _readItemIds(map);

      if (message.isEmpty) {
        AppLogger.warning(
          'StylistResponseParser: JSON missing message — fallback to raw',
        );
        return StylistResponse(message: trimmed);
      }

      AppLogger.info(
        'StylistResponseParser: parsed message=${message.length} chars '
        'recommendedIds=${ids.length}',
      );
      return StylistResponse(message: message, recommendedItemIds: ids);
    } catch (e) {
      AppLogger.warning(
        'StylistResponseParser: JSON parse failed ($e) — plain text fallback',
      );
      return StylistResponse(message: trimmed);
    }
  }

  static String? _extractJsonObject(String text) {
    if (text.startsWith('{') && text.endsWith('}')) return text;

    final fenceMatch = RegExp(
      r'```(?:json)?\s*(\{[\s\S]*?\})\s*```',
      multiLine: true,
    ).firstMatch(text);
    if (fenceMatch != null) return fenceMatch.group(1);

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return text.substring(start, end + 1);
    }
    return null;
  }

  static String _readMessage(Map<String, dynamic> map) {
    for (final key in _messageKeys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  static List<String> _readItemIds(Map<String, dynamic> map) {
    for (final key in _idListKeys) {
      final value = map[key];
      if (value is List<dynamic>) {
        return _normalizeIds(value);
      }
    }
    return const [];
  }

  static List<String> _normalizeIds(List<dynamic> raw) {
    final ids = <String>[];
    for (final entry in raw) {
      if (entry == null) continue;
      if (entry is Map) {
        final fromMap = entry['id'] ?? entry['itemId'] ?? entry['wardrobeItemId'];
        if (fromMap != null) {
          final id = fromMap.toString().trim();
          if (id.isNotEmpty) ids.add(id);
        }
        continue;
      }
      final id = entry.toString().trim();
      if (id.isNotEmpty) ids.add(_normalizeIdToken(id));
    }
    return ids;
  }

  /// Maps prompt examples like "id1" → "1".
  static String _normalizeIdToken(String raw) {
    final trimmed = raw.trim();
    final match = RegExp(r'^id[_-]?(\d+)$', caseSensitive: false)
        .firstMatch(trimmed);
    if (match != null) return match.group(1)!;
    return trimmed;
  }
}
