import '../../core/storage/hive_json_list_codec.dart';
import '../../core/storage/local_hive_storage.dart';
import '../../core/utils/logger.dart';
import '../models/outfit_history_entry.dart';

/// Local persistence for AI outfit recommendation history (Hive).
class OutfitHistoryRepository {
  OutfitHistoryRepository._();

  static final OutfitHistoryRepository instance = OutfitHistoryRepository._();

  static const _itemsKey = LocalHiveStorage.outfitHistoryItemsKey;

  Future<int> countEntries() async {
    return HiveJsonListCodec.countEntries(
      LocalHiveStorage.outfitHistoryBox,
      _itemsKey,
    );
  }

  Future<List<OutfitHistoryEntry>> loadEntries() async {
    final maps = HiveJsonListCodec.decode(
      LocalHiveStorage.outfitHistoryBox.get(_itemsKey),
    );
    if (maps.isEmpty) return [];

    try {
      final items = maps
          .map(OutfitHistoryEntry.fromJson)
          .where((item) => item.aiResponseText.trim().isNotEmpty)
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (e, stack) {
      AppLogger.error(
        'OutfitHistoryRepository.loadEntries: corrupt data',
        error: e,
        stackTrace: stack,
      );
      await LocalHiveStorage.outfitHistoryBox.delete(_itemsKey);
      return [];
    }
  }

  Future<void> saveEntries(List<OutfitHistoryEntry> entries) async {
    final sorted = [...entries]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await HiveJsonListCodec.write(
      LocalHiveStorage.outfitHistoryBox,
      _itemsKey,
      sorted.map((item) => item.toJson()).toList(),
    );
  }

  Future<OutfitHistoryEntry> addEntry(OutfitHistoryEntry entry) async {
    final entries = await loadEntries();
    final updated = [entry, ...entries];
    await saveEntries(updated);
    AppLogger.debug('OutfitHistoryRepository.addEntry: "${entry.title}"');
    return entry;
  }

  Future<bool> deleteEntry(String id) async {
    final entries = await loadEntries();
    final updated = entries.where((item) => item.id != id).toList();
    if (updated.length == entries.length) return false;
    await saveEntries(updated);
    AppLogger.info('OutfitHistoryRepository.deleteEntry: $id');
    return true;
  }

  Future<OutfitHistoryEntry?> findById(String id) async {
    final entries = await loadEntries();
    for (final item in entries) {
      if (item.id == id) return item;
    }
    return null;
  }
}
