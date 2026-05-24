import 'dart:convert';

import '../storage/local_hive_storage.dart';
import '../utils/logger.dart';
import 'sync_scope.dart';

/// Tracks per-entity local mutation timestamps for last-write-wins merge.
abstract final class SyncMetaStorage {
  static const _timestampPrefix = 'sync_local_ts_';
  static const _pendingDeletesPrefix = 'sync_pending_deletes_';

  static String _timestampKey(SyncScope scope) =>
      '$_timestampPrefix${scope.name}';

  static String _pendingDeletesKey(SyncScope scope) =>
      '$_pendingDeletesPrefix${scope.name}';

  static Map<String, int> readTimestamps(SyncScope scope) {
    final raw = LocalHiveStorage.metaBox.get(_timestampKey(scope));
  if (raw is! String || raw.trim().isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map(
        (key, value) => MapEntry(
          key.toString(),
          value is int ? value : int.tryParse('$value') ?? 0,
        ),
      );
    } catch (e) {
      AppLogger.warning('SyncMetaStorage: corrupt timestamps for $scope ($e)');
      return {};
    }
  }

  static Future<void> writeTimestamps(
    SyncScope scope,
    Map<String, int> timestamps,
  ) async {
    await LocalHiveStorage.metaBox.put(
      _timestampKey(scope),
      jsonEncode(timestamps),
    );
  }

  static Future<void> removeTimestamp(SyncScope scope, String id) async {
    final needle = id.trim();
    if (needle.isEmpty) return;

    final timestamps = readTimestamps(scope);
    if (!timestamps.containsKey(needle)) return;

    timestamps.remove(needle);
    await writeTimestamps(scope, timestamps);
  }

  static Future<void> touch(SyncScope scope, String id) async {
    final needle = id.trim();
    if (needle.isEmpty) return;

    final timestamps = readTimestamps(scope);
    timestamps[needle] = DateTime.now().toUtc().millisecondsSinceEpoch;
    await writeTimestamps(scope, timestamps);
  }

  static Future<void> touchAll(SyncScope scope, Iterable<String> ids) async {
    final timestamps = readTimestamps(scope);
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    for (final id in ids) {
      final needle = id.trim();
      if (needle.isEmpty) continue;
      timestamps[needle] = now;
    }
    await writeTimestamps(scope, timestamps);
  }

  static DateTime timestampFor(SyncScope scope, String id) {
    final millis = readTimestamps(scope)[id.trim()] ?? 0;
    if (millis <= 0) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }

  static Set<String> readPendingDeletes(SyncScope scope) {
    final raw = LocalHiveStorage.metaBox.get(_pendingDeletesKey(scope));
    if (raw is! List) return {};
    return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toSet();
  }

  static Future<void> addPendingDelete(SyncScope scope, String id) async {
    final needle = id.trim();
    if (needle.isEmpty) return;

    final pending = readPendingDeletes(scope)..add(needle);
    await LocalHiveStorage.metaBox.put(
      _pendingDeletesKey(scope),
      pending.toList(),
    );
  }

  static Future<void> clearPendingDelete(SyncScope scope, String id) async {
    final pending = readPendingDeletes(scope)..remove(id.trim());
    await LocalHiveStorage.metaBox.put(
      _pendingDeletesKey(scope),
      pending.toList(),
    );
  }

  static Future<void> clearPendingDeletes(SyncScope scope) async {
    await LocalHiveStorage.metaBox.delete(_pendingDeletesKey(scope));
  }
}
