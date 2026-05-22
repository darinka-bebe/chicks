import '../../data/models/clothing_vision_analysis.dart';
import '../../data/models/wardrobe_item.dart';
import '../../data/repositories/wardrobe_repository.dart';
import '../utils/logger.dart';

/// Match between a draft item and an existing wardrobe row.
class WardrobeDuplicateMatch {
  const WardrobeDuplicateMatch({
    required this.existing,
    required this.score,
    required this.source,
  });

  final WardrobeItem existing;
  final double score;
  final String source;

  String get label =>
      '«${existing.title}» (${existing.category}, ${existing.color})';
}

/// Detects when the user re-photos the same wardrobe row (not similar items).
abstract final class WardrobeDuplicateDetector {
  /// Near-exact title match only (same category).
  static const double strictTitleThreshold = 0.94;

  /// Vision hint must align this closely with a listed title.
  static const double visionTitleThreshold = 0.92;

  /// Evaluates duplicate using strict rules + optional Vision flag.
  static WardrobeDuplicateMatch? evaluate({
    required String title,
    required String category,
    required String color,
    required List<WardrobeItem> wardrobe,
    ClothingVisionAnalysis? vision,
  }) {
    final local = _findStrictLocal(
      title: title,
      category: category,
      color: color,
      wardrobe: wardrobe,
    );

    if (vision == null || !vision.isDuplicate) {
      return local;
    }

    final visionMatch = _matchVisionHint(
      duplicateMatchTitle: vision.duplicateMatchTitle,
      draftTitle: title,
      draftCategory: category,
      wardrobe: wardrobe,
    );

    if (visionMatch == null) {
      AppLogger.info(
        'WardrobeDuplicateDetector: vision isDuplicate ignored (weak title match)',
      );
      return local;
    }

    if (local != null &&
        WardrobeRepository.idEquals(
          visionMatch.existing.id,
          local.existing.id,
        )) {
      return WardrobeDuplicateMatch(
        existing: visionMatch.existing,
        score: ((visionMatch.score + local.score) / 2).clamp(0.0, 1.0),
        source: 'vision+local',
      );
    }

    if (visionMatch.score >= 0.98) {
      return visionMatch;
    }

    AppLogger.info(
      'WardrobeDuplicateDetector: vision-only duplicate rejected '
      '(score=${visionMatch.score.toStringAsFixed(2)})',
    );
    return local;
  }

  static WardrobeDuplicateMatch? _findStrictLocal({
    required String title,
    required String category,
    required String color,
    required List<WardrobeItem> wardrobe,
  }) {
    final draftCategory = _norm(category);
    final draftTitle = _norm(title);
    if (draftTitle.isEmpty || draftCategory.isEmpty || wardrobe.isEmpty) {
      return null;
    }

    final draftTokens = _titleTokens(draftTitle);
    if (_isOnlyGenericTokens(draftTokens)) {
      return null;
    }

    WardrobeDuplicateMatch? best;

    for (final item in wardrobe) {
      if (_norm(item.category) != draftCategory) continue;

      final itemTitle = _norm(item.title);
      final itemTokens = _titleTokens(itemTitle);
      final titleScore = _tokenSimilarity(draftTokens, itemTokens);

      if (titleScore < strictTitleThreshold) continue;
      if (_isOnlyGenericTokens(itemTokens)) continue;
      if (_isGenericOnlyOverlap(draftTokens, itemTokens)) continue;

      if (draftTitle != itemTitle && titleScore < 0.98) continue;

      if (best == null || titleScore > best.score) {
        best = WardrobeDuplicateMatch(
          existing: item,
          score: titleScore,
          source: 'local',
        );
      }
    }

    if (best != null) {
      AppLogger.info(
        'WardrobeDuplicateDetector: strict local ${best.score.toStringAsFixed(2)} '
        '→ ${best.existing.id} "${best.existing.title}"',
      );
    }

    return best;
  }

  static WardrobeDuplicateMatch? _matchVisionHint({
    required String duplicateMatchTitle,
    required String draftTitle,
    required String draftCategory,
    required List<WardrobeItem> wardrobe,
  }) {
    final hint = duplicateMatchTitle.trim();
    if (hint.isEmpty) return null;

    final hintNorm = _norm(hint);
    final hintTokens = _titleTokens(hintNorm);
    if (_isOnlyGenericTokens(hintTokens)) return null;

    WardrobeItem? bestItem;
    var bestScore = 0.0;

    for (final item in wardrobe) {
      if (_norm(item.category) != _norm(draftCategory)) continue;

      final titleScore = _tokenSimilarity(
        hintTokens,
        _titleTokens(_norm(item.title)),
      );
      if (titleScore > bestScore) {
        bestScore = titleScore;
        bestItem = item;
      }
    }

    if (bestItem == null || bestScore < visionTitleThreshold) return null;

    final draftNorm = _norm(draftTitle);
    final itemNorm = _norm(bestItem.title);
    final draftVsItem = _tokenSimilarity(
      _titleTokens(draftNorm),
      _titleTokens(itemNorm),
    );

    if (hintNorm != itemNorm && bestScore < 0.98) return null;
    if (draftVsItem < 0.85 && hintNorm != draftNorm) return null;

    return WardrobeDuplicateMatch(
      existing: bestItem,
      score: bestScore,
      source: 'vision',
    );
  }

  static const Set<String> _genericTokens = {
    'джинсы',
    'jeans',
    'брюки',
    'штаны',
    'рубашка',
    'футболка',
    'платье',
    'юбка',
    'свитер',
    'худи',
    'куртка',
    'пальто',
    'пиджак',
    'жилет',
    'сарафан',
    'топ',
    'блуза',
    'свитшот',
    'кардиган',
    'шорты',
    'обувь',
    'кроссовки',
    'ботинки',
    'лоферы',
    'сумка',
    'широкие',
    'узкие',
    'прямые',
    'оверсайз',
    'классические',
    'повседневные',
    'синий',
    'синяя',
    'синие',
    'черный',
    'черная',
    'белый',
    'белая',
    'серый',
    'серая',
    'красный',
    'зеленый',
    'бежевый',
  };

  static bool _isOnlyGenericTokens(Set<String> tokens) {
    if (tokens.isEmpty) return true;
    return tokens.every(_genericTokens.contains);
  }

  static bool _isGenericOnlyOverlap(Set<String> a, Set<String> b) {
    final shared = a.intersection(b);
    if (shared.isEmpty) return false;
    return shared.every(_genericTokens.contains);
  }

  static String _norm(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ё', 'е')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static Set<String> _titleTokens(String normalizedTitle) {
    const stop = {'и', 'в', 'на', 'с', 'из', 'the', 'a', 'an'};
    return normalizedTitle
        .split(RegExp(r'[^a-zа-я0-9]+'))
        .where((w) => w.length >= 2 && !stop.contains(w))
        .toSet();
  }

  static double _tokenSimilarity(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1;

    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    return intersection / union;
  }
}
