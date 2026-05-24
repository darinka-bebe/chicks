import '../utils/logger.dart';
import 'sync_document.dart';

/// Result of merging local and remote sync documents.
class SyncMergeResult<T> {
  const SyncMergeResult({
    required this.items,
    required this.restoredCount,
    required this.conflictCount,
    required this.removedCount,
  });

  final List<T> items;
  final int restoredCount;
  final int conflictCount;
  final int removedCount;
}

/// Last-write-wins merge for entity lists keyed by [idField].
abstract final class SyncMergeEngine {
  static SyncMergeResult<T> mergeMaps<T>({
    required List<T> localItems,
    required List<SyncDocument> remoteDocs,
    required String idField,
    required Map<String, DateTime> localUpdatedAt,
    required T Function(Map<String, dynamic> json) fromJson,
    required Map<String, dynamic> Function(T item) toJson,
    String? dedupeField,
  }) {
    final mergedById = <String, _MergeCandidate<T>>{};
    var restoredCount = 0;
    var conflictCount = 0;
    var removedCount = 0;

    for (final item in localItems) {
      final json = toJson(item);
      final id = _readId(json[idField]);
      if (id == null) continue;

      mergedById[id] = _MergeCandidate(
        id: id,
        item: item,
        updatedAt: localUpdatedAt[id] ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        deleted: false,
        source: _MergeSource.local,
      );
    }

    for (final doc in remoteDocs) {
      final id = doc.id.trim();
      if (id.isEmpty) continue;

      final existing = mergedById[id];
      if (existing == null) {
        if (doc.deleted) {
          removedCount++;
          continue;
        }

        final parsed = fromJson(doc.payload);
        mergedById[id] = _MergeCandidate(
          id: id,
          item: parsed,
          updatedAt: doc.updatedAt,
          deleted: false,
          source: _MergeSource.remote,
        );
        restoredCount++;
        continue;
      }

      if (doc.deleted && !existing.deleted) {
        if (doc.updatedAt.isAfter(existing.updatedAt)) {
          mergedById.remove(id);
          removedCount++;
          conflictCount++;
          AppLogger.warning(
            'SyncMergeEngine: remote delete wins for id=$id '
            '(remote=${doc.updatedAt.toIso8601String()}, '
            'local=${existing.updatedAt.toIso8601String()})',
          );
        } else {
          conflictCount++;
          AppLogger.warning(
            'SyncMergeEngine: local item kept over stale remote delete id=$id',
          );
        }
        continue;
      }

      if (doc.deleted) {
        mergedById.remove(id);
        removedCount++;
        continue;
      }

      if (doc.updatedAt.isAfter(existing.updatedAt)) {
        final parsed = fromJson(doc.payload);
        mergedById[id] = _MergeCandidate(
          id: id,
          item: parsed,
          updatedAt: doc.updatedAt,
          deleted: false,
          source: _MergeSource.remote,
        );
        if (existing.source == _MergeSource.local) {
          conflictCount++;
          AppLogger.warning(
            'SyncMergeEngine: remote wins conflict id=$id '
            '(remote=${doc.updatedAt.toIso8601String()}, '
            'local=${existing.updatedAt.toIso8601String()})',
          );
        } else {
          restoredCount++;
        }
      } else if (doc.updatedAt.isBefore(existing.updatedAt)) {
        conflictCount++;
        AppLogger.debug(
          'SyncMergeEngine: local wins conflict id=$id '
          '(local=${existing.updatedAt.toIso8601String()}, '
          'remote=${doc.updatedAt.toIso8601String()})',
        );
      }
    }

    var items = mergedById.values.map((entry) => entry.item).toList();

    if (dedupeField != null && dedupeField.isNotEmpty) {
      final before = items.length;
      items = _dedupeByField(items, dedupeField, toJson);
      final removedDupes = before - items.length;
      if (removedDupes > 0) {
        AppLogger.info(
          'SyncMergeEngine: removed $removedDupes duplicate(s) by $dedupeField',
        );
      }
    }

    return SyncMergeResult(
      items: items,
      restoredCount: restoredCount,
      conflictCount: conflictCount,
      removedCount: removedCount,
    );
  }

  static List<T> _dedupeByField<T>(
    List<T> items,
    String field,
    Map<String, dynamic> Function(T item) toJson,
  ) {
    final seen = <String>{};
    final unique = <T>[];

    for (final item in items) {
      final value = toJson(item)[field]?.toString().trim() ?? '';
      if (value.isEmpty) {
        unique.add(item);
        continue;
      }
      if (seen.add(value)) {
        unique.add(item);
      }
    }

    return unique;
  }

  static String? _readId(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}

enum _MergeSource { local, remote }

class _MergeCandidate<T> {
  const _MergeCandidate({
    required this.id,
    required this.item,
    required this.updatedAt,
    required this.deleted,
    required this.source,
  });

  final String id;
  final T item;
  final DateTime updatedAt;
  final bool deleted;
  final _MergeSource source;
}
