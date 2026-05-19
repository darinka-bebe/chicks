import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';

/// Opens Hive boxes and migrates legacy SharedPreferences data once.
abstract final class LocalHiveStorage {
  static const wardrobeBoxName = 'chicks_wardrobe_v1';
  static const favoritesBoxName = 'chicks_favorites_v1';
  static const chatBoxName = 'chicks_chat_v1';
  static const outfitHistoryBoxName = 'chicks_outfit_history_v1';
  static const outfitDislikesBoxName = 'chicks_outfit_dislikes_v1';
  static const metaBoxName = 'chicks_meta_v1';

  static const wardrobeItemsKey = 'items';
  static const favoritesItemsKey = 'items';
  static const chatMessagesKey = 'messages';
  static const outfitHistoryItemsKey = 'items';
  static const outfitDislikesItemsKey = 'items';
  static const migrationDoneKey = 'hive_data_migrated_v1';

  static const _legacyWardrobeKey = 'wardrobe_items_v1';
  static const _legacyFavoritesKey = 'favorite_outfits_v1';
  static const _legacyChatKey = 'stylist_chat_history_v1';

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(wardrobeBoxName),
      Hive.openBox(favoritesBoxName),
      Hive.openBox(chatBoxName),
      Hive.openBox(outfitHistoryBoxName),
      Hive.openBox(outfitDislikesBoxName),
      Hive.openBox(metaBoxName),
    ]);

    await _migrateFromSharedPreferences();
    _initialized = true;
    AppLogger.info('LocalHiveStorage: initialized');
  }

  static Box<dynamic> get wardrobeBox => Hive.box(wardrobeBoxName);
  static Box<dynamic> get favoritesBox => Hive.box(favoritesBoxName);
  static Box<dynamic> get chatBox => Hive.box(chatBoxName);
  static Box<dynamic> get outfitHistoryBox => Hive.box(outfitHistoryBoxName);
  static Box<dynamic> get outfitDislikesBox => Hive.box(outfitDislikesBoxName);
  static Box<dynamic> get metaBox => Hive.box(metaBoxName);

  static Future<void> _migrateFromSharedPreferences() async {
    if (metaBox.get(migrationDoneKey) == true) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    var migratedAny = false;

    if (wardrobeBox.get(wardrobeItemsKey) == null) {
      final legacy = prefs.getString(_legacyWardrobeKey);
      if (legacy != null && legacy.trim().isNotEmpty) {
        await wardrobeBox.put(wardrobeItemsKey, legacy);
        migratedAny = true;
        AppLogger.info('LocalHiveStorage: migrated wardrobe from SharedPreferences');
      }
    }

    if (favoritesBox.get(favoritesItemsKey) == null) {
      final legacy = prefs.getString(_legacyFavoritesKey);
      if (legacy != null && legacy.trim().isNotEmpty) {
        await favoritesBox.put(favoritesItemsKey, legacy);
        migratedAny = true;
        AppLogger.info('LocalHiveStorage: migrated favorites from SharedPreferences');
      }
    }

    if (chatBox.get(chatMessagesKey) == null) {
      final legacy = prefs.getString(_legacyChatKey);
      if (legacy != null && legacy.trim().isNotEmpty) {
        await chatBox.put(chatMessagesKey, legacy);
        migratedAny = true;
        AppLogger.info('LocalHiveStorage: migrated chat history from SharedPreferences');
      }
    }

    if (migratedAny) {
      await prefs.remove(_legacyWardrobeKey);
      await prefs.remove(_legacyFavoritesKey);
      await prefs.remove(_legacyChatKey);
    }

    await metaBox.put(migrationDoneKey, true);
  }
}
