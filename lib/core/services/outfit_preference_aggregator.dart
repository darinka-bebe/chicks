import '../../data/models/outfit_dislike_entry.dart';
import '../models/outfit_preference_profile.dart';

/// Builds a lightweight preference profile from stored dislikes.
abstract final class OutfitPreferenceAggregator {
  static const _repeatBoost = 2;

  static OutfitPreferenceProfile fromEntries(List<OutfitDislikeEntry> entries) {
    if (entries.isEmpty) return OutfitPreferenceProfile.empty;

    final styles = <String, int>{};
    final colors = <String, int>{};
    final silhouettes = <String, int>{};
    final combinations = <String, int>{};

    for (final entry in entries) {
      _bumpAll(styles, entry.styles);
      _bumpAll(colors, entry.colors);
      _bumpAll(silhouettes, entry.silhouettes);
      if (entry.combinationKey.isNotEmpty) {
        combinations.update(
          entry.combinationKey,
          (v) => v + _repeatBoost,
          ifAbsent: () => _repeatBoost,
        );
      }
    }

    return OutfitPreferenceProfile(
      styleWeights: styles,
      colorWeights: colors,
      silhouetteWeights: silhouettes,
      combinationWeights: combinations,
      totalDislikes: entries.length,
    );
  }

  static void _bumpAll(Map<String, int> map, List<String> tags) {
    for (final tag in tags) {
      if (tag.isEmpty) continue;
      map.update(tag, (v) => v + 1, ifAbsent: () => 1);
    }
  }
}
