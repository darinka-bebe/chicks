/// Aggregated negative taste signals from disliked outfits.
class OutfitPreferenceProfile {
  const OutfitPreferenceProfile({
    this.styleWeights = const {},
    this.colorWeights = const {},
    this.silhouetteWeights = const {},
    this.combinationWeights = const {},
    this.totalDislikes = 0,
  });

  static const empty = OutfitPreferenceProfile();

  final Map<String, int> styleWeights;
  final Map<String, int> colorWeights;
  final Map<String, int> silhouetteWeights;
  final Map<String, int> combinationWeights;
  final int totalDislikes;

  bool get hasSignals => totalDislikes > 0;

  List<String> topStyles({int limit = 4}) => _topKeys(styleWeights, limit);

  List<String> topColors({int limit = 4}) => _topKeys(colorWeights, limit);

  List<String> topSilhouettes({int limit = 3}) =>
      _topKeys(silhouetteWeights, limit);

  static List<String> _topKeys(Map<String, int> map, int limit) {
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).map((e) => e.key).toList();
  }

  /// 0 = neutral, higher = stronger dislike match.
  double dislikePenalty({
    required Iterable<String> styles,
    required Iterable<String> colors,
    required Iterable<String> silhouettes,
    String? combinationKey,
  }) {
    if (!hasSignals) return 0;

    var penalty = 0.0;
    for (final tag in styles) {
      penalty += (styleWeights[tag] ?? 0) * 0.9;
    }
    for (final tag in colors) {
      penalty += (colorWeights[tag] ?? 0) * 0.85;
    }
    for (final tag in silhouettes) {
      penalty += (silhouetteWeights[tag] ?? 0) * 0.8;
    }
    if (combinationKey != null && combinationKey.isNotEmpty) {
      penalty += (combinationWeights[combinationKey] ?? 0) * 1.4;
    }

    if (totalDislikes >= 3) {
      penalty *= 1.0 + (totalDislikes.clamp(0, 12) * 0.04);
    }

    return penalty.clamp(0.0, 28.0);
  }
}
