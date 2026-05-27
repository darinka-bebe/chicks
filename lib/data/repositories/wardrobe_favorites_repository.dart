import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/logger.dart';

/// Local favorite wardrobe item ids (not synced to Firestore).
class WardrobeFavoritesRepository {
  WardrobeFavoritesRepository._();

  static final WardrobeFavoritesRepository instance =
      WardrobeFavoritesRepository._();

  static const _key = 'wardrobe_favorite_ids_v1';

  Future<Set<String>> loadFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return {};
      return decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toSet();
    } catch (e) {
      AppLogger.warning('WardrobeFavoritesRepository: corrupt data ($e)');
      return {};
    }
  }

  Future<void> saveFavoriteIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(ids.toList()));
  }

  Future<bool> toggle(String itemId) async {
    final needle = itemId.trim();
    if (needle.isEmpty) return false;

    final ids = await loadFavoriteIds();
    final added = !ids.contains(needle);
    if (added) {
      ids.add(needle);
    } else {
      ids.remove(needle);
    }
    await saveFavoriteIds(ids);
    AppLogger.info(
      'WardrobeFavoritesRepository: toggle id=$needle favorited=$added',
    );
    return added;
  }

  Future<bool> isFavorite(String itemId) async {
    final ids = await loadFavoriteIds();
    return ids.contains(itemId.trim());
  }
}
