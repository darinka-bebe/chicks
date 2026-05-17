import 'dart:convert';

import 'package:hive/hive.dart';

/// Reads/writes JSON list payloads in Hive boxes (string or decoded list).
abstract final class HiveJsonListCodec {
  static List<Map<String, dynamic>> decode(dynamic raw) {
    if (raw == null) return [];

    if (raw is String) {
      if (raw.trim().isEmpty) return [];
      return _decodeJsonString(raw);
    }

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map(_normalizeMap)
          .toList();
    }

    return [];
  }

  static List<Map<String, dynamic>> _decodeJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! List<dynamic>) return [];

    return decoded
        .whereType<Map>()
        .map(_normalizeMap)
        .toList();
  }

  /// Ensures nested maps/lists from Hive are JSON-safe (id fields stay readable).
  static Map<String, dynamic> _normalizeMap(Map map) {
    final normalized = <String, dynamic>{};
    map.forEach((key, value) {
      normalized[key.toString()] = _normalizeValue(value);
    });
    return normalized;
  }

  static dynamic _normalizeValue(dynamic value) {
    if (value is Map) {
      return _normalizeMap(value);
    }
    if (value is List) {
      return value.map(_normalizeValue).toList();
    }
    return value;
  }

  static Future<void> write(
    Box<dynamic> box,
    String key,
    List<Map<String, dynamic>> maps,
  ) async {
    if (maps.isEmpty) {
      await box.delete(key);
      return;
    }
    await box.put(key, maps);
  }

  static int countEntries(Box<dynamic> box, String key) {
    return decode(box.get(key)).length;
  }
}
