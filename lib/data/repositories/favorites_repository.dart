import '../../core/storage/hive_json_list_codec.dart';
import '../../core/storage/local_hive_storage.dart';
import '../../core/utils/logger.dart';
import '../models/favorite_outfit.dart';

/// Local persistence for saved outfit recommendations (Hive).
class FavoritesRepository {
  FavoritesRepository._();

  static final FavoritesRepository instance = FavoritesRepository._();

  static const _itemsKey = LocalHiveStorage.favoritesItemsKey;

  /// Lightweight count for dashboards — no dedupe/sort side effects.
  Future<int> countOutfits() async {
    return HiveJsonListCodec.countEntries(
      LocalHiveStorage.favoritesBox,
      _itemsKey,
    );
  }

  Future<List<FavoriteOutfit>> loadOutfits() async {
    final maps = HiveJsonListCodec.decode(
      LocalHiveStorage.favoritesBox.get(_itemsKey),
    );
    if (maps.isEmpty) return [];

    try {
      final items = maps.map(FavoriteOutfit.fromJson).toList();
      final deduped = _dedupeByContentHash(items);
      if (deduped.length != items.length) {
        await saveOutfits(deduped);
        AppLogger.info(
          'FavoritesRepository: removed ${items.length - deduped.length} duplicate(s)',
        );
      }
      deduped.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return deduped;
    } catch (e, stack) {
      AppLogger.error(
        'FavoritesRepository.loadOutfits: corrupt data',
        error: e,
        stackTrace: stack,
      );
      await LocalHiveStorage.favoritesBox.delete(_itemsKey);
      return [];
    }
  }

  List<FavoriteOutfit> _dedupeByContentHash(List<FavoriteOutfit> items) {
    final seen = <String>{};
    final unique = <FavoriteOutfit>[];

    for (final item in items) {
      if (seen.add(item.contentHash)) {
        unique.add(item);
      }
    }

    return unique;
  }

  Future<void> saveOutfits(List<FavoriteOutfit> outfits) async {
    final deduped = _dedupeByContentHash(outfits);
    await HiveJsonListCodec.write(
      LocalHiveStorage.favoritesBox,
      _itemsKey,
      deduped.map((item) => item.toJson()).toList(),
    );
  }

  bool containsHash(List<FavoriteOutfit> outfits, String contentHash) {
    return outfits.any((item) => item.contentHash == contentHash);
  }

  /// Adds outfit only if [contentHash] is not already saved. Returns null if duplicate.
  Future<FavoriteOutfit?> addOutfitIfNew(FavoriteOutfit outfit) async {
    final outfits = await loadOutfits();
    if (containsHash(outfits, outfit.contentHash)) {
      AppLogger.debug(
        'FavoritesRepository.addOutfitIfNew: duplicate hash ${outfit.contentHash}',
      );
      return null;
    }

    final updated = [outfit, ...outfits];
    await saveOutfits(updated);
    AppLogger.debug('FavoritesRepository.addOutfitIfNew: "${outfit.title}"');
    return outfit;
  }

  Future<bool> deleteOutfit(String id) async {
    final outfits = await loadOutfits();
    final updated = outfits.where((item) => item.id != id).toList();
    if (updated.length == outfits.length) return false;
    await saveOutfits(updated);
    AppLogger.info('FavoritesRepository.deleteOutfit: $id');
    return true;
  }

  Future<bool> deleteByContentHash(String contentHash) async {
    final outfits = await loadOutfits();
    final updated =
        outfits.where((item) => item.contentHash != contentHash).toList();
    if (updated.length == outfits.length) return false;
    await saveOutfits(updated);
    AppLogger.info('FavoritesRepository.deleteByContentHash: $contentHash');
    return true;
  }

  Future<FavoriteOutfit?> findByContentHash(String contentHash) async {
    final outfits = await loadOutfits();
    for (final item in outfits) {
      if (item.contentHash == contentHash) return item;
    }
    return null;
  }
}
