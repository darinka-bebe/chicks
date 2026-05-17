import '../../data/models/wardrobe_item.dart';
import '../../data/repositories/wardrobe_repository.dart';
import '../utils/logger.dart';

/// Resolves AI-referenced wardrobe ids against the current in-storage wardrobe.
abstract final class WardrobeRecommendationResolver {
  /// Keeps only ids that exist in [wardrobe], preserving AI order.
  static List<WardrobeItem> resolveItems({
    required List<String> requestedIds,
    required List<WardrobeItem> wardrobe,
  }) {
    if (requestedIds.isEmpty || wardrobe.isEmpty) return const [];

    final byId = <String, WardrobeItem>{};
    for (final item in wardrobe) {
      byId[item.id.trim()] = item;
    }

    final resolved = <WardrobeItem>[];
    final seen = <String>{};

    for (final rawId in requestedIds) {
      final id = rawId.trim();
      if (id.isEmpty || seen.contains(id)) continue;

      WardrobeItem? match = byId[id];
      if (match == null) {
        for (final item in wardrobe) {
          if (WardrobeRepository.idEquals(item.id, id)) {
            match = item;
            break;
          }
        }
      }

      if (match != null) {
        seen.add(id);
        resolved.add(match);
      }
    }

    if (requestedIds.isNotEmpty) {
      AppLogger.debug(
        'WardrobeRecommendationResolver: requested=${requestedIds.length} '
        'resolved=${resolved.length}',
      );
    }

    return resolved;
  }

  /// Filters id list to those still in wardrobe (for persistence sanitization).
  static List<String> filterValidIds({
    required List<String> requestedIds,
    required List<WardrobeItem> wardrobe,
  }) {
    return resolveItems(requestedIds: requestedIds, wardrobe: wardrobe)
        .map((item) => item.id)
        .toList();
  }
}
