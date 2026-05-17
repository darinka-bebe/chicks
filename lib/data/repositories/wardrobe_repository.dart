import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/logger.dart';
import '../../features/wardrobe/data/mock_wardrobe_data.dart';
import '../models/wardrobe_item.dart';

/// Local wardrobe persistence (SharedPreferences JSON).
class WardrobeRepository {
  WardrobeRepository._();

  static final WardrobeRepository instance = WardrobeRepository._();

  static const _storageKey = 'wardrobe_items_v1';

  Future<List<WardrobeItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.trim().isEmpty) {
      final seeded = List<WardrobeItem>.from(MockWardrobeData.items);
      await saveItems(seeded);
      return seeded;
    }

    try {
      return WardrobeItem.listFromJsonString(raw);
    } catch (_) {
      await prefs.remove(_storageKey);
      return loadItems();
    }
  }

  Future<void> saveItems(List<WardrobeItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, WardrobeItem.listToJsonString(items));
  }

  Future<WardrobeItem> addItem(WardrobeItem item) async {
    AppLogger.debug('WardrobeRepository.addItem: "${item.title}" (${item.id})');
    final items = await loadItems();
    final updated = [...items, item];
    await saveItems(updated);
    AppLogger.info(
      'WardrobeRepository.addItem: persisted ${updated.length} item(s)',
    );
    return item;
  }

  Future<bool> deleteItem(String id) async {
    final items = await loadItems();
    final updated = items.where((item) => item.id != id).toList();
    if (updated.length == items.length) return false;
    await saveItems(updated);
    return true;
  }
}
