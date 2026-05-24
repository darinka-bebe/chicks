/// Aggregated positive taste signals from saved favorite outfits.
class FavoritePreferenceProfile {
  const FavoritePreferenceProfile({
    this.styleWeights = const {},
    this.colorWeights = const {},
    this.silhouetteWeights = const {},
    this.combinationWeights = const {},
    this.itemWeights = const {},
    this.moodWeights = const {},
    this.occasionWeights = const {},
    this.totalFavorites = 0,
  });

  static const empty = FavoritePreferenceProfile();

  final Map<String, int> styleWeights;
  final Map<String, int> colorWeights;
  final Map<String, int> silhouetteWeights;
  final Map<String, int> combinationWeights;
  final Map<String, int> itemWeights;
  final Map<String, int> moodWeights;
  final Map<String, int> occasionWeights;
  final int totalFavorites;

  bool get hasSignals =>
      totalFavorites > 0 &&
      (styleWeights.isNotEmpty ||
          colorWeights.isNotEmpty ||
          silhouetteWeights.isNotEmpty ||
          itemWeights.isNotEmpty);

  List<String> topStyles({int limit = 4}) => _topKeys(styleWeights, limit);

  List<String> topColors({int limit = 4}) => _topKeys(colorWeights, limit);

  List<String> topSilhouettes({int limit = 3}) =>
      _topKeys(silhouetteWeights, limit);

  /// Normalized boost 0..1 for scoring (higher = stronger favorite match).
  double favoriteBoost({
    required Iterable<String> styles,
    required Iterable<String> colors,
    required Iterable<String> silhouettes,
    String? itemId,
    String? combinationKey,
    Iterable<String> moods = const [],
    Iterable<String> occasions = const [],
  }) {
    if (!hasSignals) return 0;

    var raw = 0.0;
    for (final tag in styles) {
      raw += (styleWeights[tag] ?? 0) * 0.9;
    }
    for (final tag in colors) {
      raw += (colorWeights[tag] ?? 0) * 0.85;
    }
    for (final tag in silhouettes) {
      raw += (silhouetteWeights[tag] ?? 0) * 0.8;
    }
    for (final tag in moods) {
      raw += (moodWeights[tag] ?? 0) * 0.55;
    }
    for (final tag in occasions) {
      raw += (occasionWeights[tag] ?? 0) * 0.5;
    }

    if (itemId != null && itemId.isNotEmpty) {
      raw += (itemWeights[itemId] ?? 0) * 2.4;
    }

    if (combinationKey != null && combinationKey.isNotEmpty) {
      raw += (combinationWeights[combinationKey] ?? 0) * 1.2;
    }

    if (totalFavorites >= 2) {
      raw *= 1.0 + (totalFavorites.clamp(0, 10) * 0.03);
    }

    return (raw / 12.0).clamp(0.0, 1.0);
  }

  static List<String> _topKeys(Map<String, int> map, int limit) {
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).map((e) => e.key).toList();
  }
}
