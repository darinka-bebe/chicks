import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/outfit_history_repository.dart';
import '../models/recent_outfit_signals.dart';
import 'outfit_trait_extractor.dart';

/// Builds anti-repeat signals from saved history and favorites.
abstract final class RecentOutfitMemoryLoader {
  static const _historyLimit = 12;

  static Future<RecentOutfitSignals> load() async {
    final itemIds = <String>{};
    final combinationKeys = <String>{};

    final history = await OutfitHistoryRepository.instance.loadEntries();
    for (final entry in history.take(_historyLimit)) {
      itemIds.addAll(entry.recommendedItemIds.map((id) => id.trim()));
      if (entry.recommendedItemIds.isNotEmpty) {
        combinationKeys.add(
          OutfitTraitExtractor.combinationKeyFrom(
            itemIds: entry.recommendedItemIds,
            styles: const [],
          ),
        );
      }
    }

    final favorites = await FavoritesRepository.instance.loadOutfits();
    for (final outfit in favorites.take(8)) {
      final traits = OutfitTraitExtractor.extract(
        items: const [],
        recommendationText: outfit.recommendation,
      );
      if (traits.combinationKey.isNotEmpty) {
        combinationKeys.add(traits.combinationKey);
      }
    }

    return RecentOutfitSignals(
      recentItemIds: itemIds.where((id) => id.isNotEmpty).toSet(),
      recentCombinationKeys:
          combinationKeys.where((key) => key.isNotEmpty).toSet(),
    );
  }
}
