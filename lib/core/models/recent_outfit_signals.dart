/// Recent outfits from history/favorites — used to avoid repeating looks.
class RecentOutfitSignals {
  const RecentOutfitSignals({
    this.recentItemIds = const {},
    this.recentCombinationKeys = const {},
  });

  static const empty = RecentOutfitSignals();

  final Set<String> recentItemIds;
  final Set<String> recentCombinationKeys;

  bool get hasSignals =>
      recentItemIds.isNotEmpty || recentCombinationKeys.isNotEmpty;

  /// Normalized penalty 0..1 — higher means stronger repeat match.
  double repeatPenalty({
    required String itemId,
    String? combinationKey,
  }) {
    if (!hasSignals) return 0;

    var raw = 0.0;
    if (itemId.isNotEmpty && recentItemIds.contains(itemId.trim())) {
      raw += 2.2;
    }
    if (combinationKey != null &&
        combinationKey.isNotEmpty &&
        recentCombinationKeys.contains(combinationKey)) {
      raw += 3.0;
    }

    return (raw / 4.0).clamp(0.0, 1.0);
  }
}
