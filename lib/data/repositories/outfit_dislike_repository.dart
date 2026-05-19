import '../../core/models/outfit_preference_profile.dart';
import '../../core/services/outfit_preference_aggregator.dart';
import '../../core/storage/hive_json_list_codec.dart';
import '../../core/storage/local_hive_storage.dart';
import '../../core/utils/logger.dart';
import '../models/outfit_dislike_entry.dart';

/// Local persistence for disliked outfit recommendations.
class OutfitDislikeRepository {
  OutfitDislikeRepository._();

  static final OutfitDislikeRepository instance = OutfitDislikeRepository._();

  static const _itemsKey = LocalHiveStorage.outfitDislikesItemsKey;
  static const _maxEntries = 80;

  OutfitPreferenceProfile _cachedProfile = OutfitPreferenceProfile.empty;

  OutfitPreferenceProfile get cachedProfile => _cachedProfile;

  Future<List<OutfitDislikeEntry>> loadEntries() async {
    final maps = HiveJsonListCodec.decode(
      LocalHiveStorage.outfitDislikesBox.get(_itemsKey),
    );
    if (maps.isEmpty) {
      _cachedProfile = OutfitPreferenceProfile.empty;
      return [];
    }

    try {
      final items = maps.map(OutfitDislikeEntry.fromJson).toList();
      final deduped = _dedupeByContentHash(items);
      if (deduped.length != items.length) {
        await _writeEntries(deduped);
      }
      deduped.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _cachedProfile = OutfitPreferenceAggregator.fromEntries(deduped);
      return deduped;
    } catch (e, stack) {
      AppLogger.error(
        'OutfitDislikeRepository.loadEntries: corrupt data',
        error: e,
        stackTrace: stack,
      );
      await LocalHiveStorage.outfitDislikesBox.delete(_itemsKey);
      _cachedProfile = OutfitPreferenceProfile.empty;
      return [];
    }
  }

  Future<OutfitPreferenceProfile> loadProfile() async {
    await loadEntries();
    return _cachedProfile;
  }

  bool containsHash(List<OutfitDislikeEntry> entries, String contentHash) {
    return entries.any((entry) => entry.contentHash == contentHash);
  }

  /// Returns `true` if a new dislike was stored.
  Future<bool> addIfNew(OutfitDislikeEntry entry) async {
    final entries = await loadEntries();
    if (containsHash(entries, entry.contentHash)) {
      AppLogger.debug(
        'OutfitDislikeRepository.addIfNew: duplicate ${entry.contentHash}',
      );
      return false;
    }

    final updated = [entry, ...entries];
    final trimmed = updated.length > _maxEntries
        ? updated.take(_maxEntries).toList(growable: false)
        : updated;

    await _writeEntries(trimmed);
    AppLogger.info('OutfitDislikeRepository: dislike saved (${entry.contentHash})');
    return true;
  }

  Future<bool> removeByContentHash(String contentHash) async {
    final entries = await loadEntries();
    final updated =
        entries.where((entry) => entry.contentHash != contentHash).toList();
    if (updated.length == entries.length) return false;
    await _writeEntries(updated);
    AppLogger.info('OutfitDislikeRepository: removed dislike $contentHash');
    return true;
  }

  Future<void> _writeEntries(List<OutfitDislikeEntry> entries) async {
    final deduped = _dedupeByContentHash(entries);
    await HiveJsonListCodec.write(
      LocalHiveStorage.outfitDislikesBox,
      _itemsKey,
      deduped.map((entry) => entry.toJson()).toList(),
    );
    _cachedProfile = OutfitPreferenceAggregator.fromEntries(deduped);
  }

  List<OutfitDislikeEntry> _dedupeByContentHash(List<OutfitDislikeEntry> items) {
    final seen = <String>{};
    final unique = <OutfitDislikeEntry>[];
    for (final item in items) {
      if (item.contentHash.isEmpty) continue;
      if (seen.add(item.contentHash)) {
        unique.add(item);
      }
    }
    return unique;
  }
}
