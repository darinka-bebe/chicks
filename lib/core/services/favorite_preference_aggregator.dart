import '../../data/models/favorite_outfit.dart';
import '../../data/models/wardrobe_item.dart';
import '../models/favorite_preference_profile.dart';
import 'outfit_trait_extractor.dart';

/// Builds a lightweight positive-taste profile from saved favorites.
abstract final class FavoritePreferenceAggregator {
  static const _repeatBoost = 2;
  static final _quotedTitlePattern = RegExp(r'«([^»]+)»');

  static FavoritePreferenceProfile fromOutfits(
    List<FavoriteOutfit> outfits, {
    List<WardrobeItem> wardrobe = const [],
  }) {
    if (outfits.isEmpty) return FavoritePreferenceProfile.empty;

    final styles = <String, int>{};
    final colors = <String, int>{};
    final silhouettes = <String, int>{};
    final combinations = <String, int>{};
    final items = <String, int>{};
    final moods = <String, int>{};
    final occasions = <String, int>{};

    for (final outfit in outfits) {
      final traits = OutfitTraitExtractor.extract(
        items: const [],
        recommendationText: outfit.recommendation,
      );

      _bumpAll(styles, traits.styles);
      _bumpAll(colors, traits.colors);
      _bumpAll(silhouettes, traits.silhouettes);
      _bumpAll(moods, outfit.moods.map(_normalizeTag));
      _bumpAll(occasions, outfit.occasions.map(_normalizeTag));

      if (traits.combinationKey.isNotEmpty) {
        combinations.update(
          traits.combinationKey,
          (v) => v + _repeatBoost,
          ifAbsent: () => _repeatBoost,
        );
      }

      _bumpWardrobeItemsFromText(
        outfit.recommendation,
        wardrobe,
        items,
      );
    }

    return FavoritePreferenceProfile(
      styleWeights: styles,
      colorWeights: colors,
      silhouetteWeights: silhouettes,
      combinationWeights: combinations,
      itemWeights: items,
      moodWeights: moods,
      occasionWeights: occasions,
      totalFavorites: outfits.length,
    );
  }

  static void _bumpWardrobeItemsFromText(
    String recommendation,
    List<WardrobeItem> wardrobe,
    Map<String, int> itemWeights,
  ) {
    if (wardrobe.isEmpty) return;

    for (final match in _quotedTitlePattern.allMatches(recommendation)) {
      final quoted = match.group(1)?.trim().toLowerCase() ?? '';
      if (quoted.isEmpty) continue;

      for (final item in wardrobe) {
        final title = item.title.trim().toLowerCase();
        if (title.isEmpty) continue;
        if (title == quoted || title.contains(quoted) || quoted.contains(title)) {
          itemWeights.update(item.id, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }
  }

  static void _bumpAll(Map<String, int> map, Iterable<String> tags) {
    for (final tag in tags) {
      final key = _normalizeTag(tag);
      if (key.isEmpty) continue;
      map.update(key, (v) => v + 1, ifAbsent: () => 1);
    }
  }

  static String _normalizeTag(String raw) {
    return raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }
}
