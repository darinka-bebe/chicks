import '../../data/models/wardrobe_item.dart';
import '../utils/logger.dart';

/// Removes mentions of wardrobe items that are not in the current recommendation.
abstract final class WardrobeMessageContentSanitizer {
  /// Keeps only lines that do not reference unknown «…» item names.
  static String alignWithValidItems({
    required String message,
    required List<WardrobeItem> validItems,
    Iterable<String> extraRemovedTitles = const [],
  }) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return trimmed;

    final validTitles = validItems
        .map((item) => _norm(item.title))
        .where((t) => t.isNotEmpty)
        .toList();

    final removedTitles = extraRemovedTitles
        .map(_norm)
        .where((t) => t.isNotEmpty)
        .toList();

    final lines = trimmed.split('\n');
    final kept = <String>[];
    var dropped = 0;

    for (final line in lines) {
      if (_shouldDropLine(
        line,
        validTitles: validTitles,
        removedTitles: removedTitles,
        hasValidAccessory: validItems.any(_isAccessory),
      )) {
        dropped++;
        continue;
      }
      kept.add(line);
    }

    if (dropped > 0) {
      AppLogger.info(
        'WardrobeMessageContentSanitizer: removed $dropped line(s) '
        'with deleted/unknown items',
      );
    }

    var result = kept.join('\n').trim();
    result = _collapseBlankLines(result);
    return result.isEmpty ? trimmed : result;
  }

  static bool _shouldDropLine(
    String line, {
    required List<String> validTitles,
    required List<String> removedTitles,
    required bool hasValidAccessory,
  }) {
    final lineNorm = _norm(line);
    if (lineNorm.isEmpty) return false;

    for (final removed in removedTitles) {
      if (_mentionsTitle(lineNorm, removed)) return true;
    }

    for (final match in RegExp(r'«([^»]+)»').allMatches(line)) {
      final quoted = _norm(match.group(1) ?? '');
      if (quoted.isEmpty) continue;
      if (!_matchesAnyTitle(quoted, validTitles)) {
        return true;
      }
    }

    if (!hasValidAccessory && _mentionsBag(lineNorm)) {
      return true;
    }

    return false;
  }

  static bool _mentionsBag(String lineNorm) {
    return RegExp(r'\b(сумк\w*|tote|шоппер)\b').hasMatch(lineNorm);
  }

  static bool _isAccessory(WardrobeItem item) {
    final c = item.category.trim().toLowerCase();
    return c.contains('аксессуар');
  }

  static bool _mentionsTitle(String lineNorm, String titleNorm) {
    if (titleNorm.isEmpty) return false;
    if (lineNorm.contains(titleNorm)) return true;

    final lineTokens = _tokens(lineNorm);
    final titleTokens = _tokens(titleNorm);
    if (titleTokens.isEmpty) return false;

    final overlap = lineTokens.intersection(titleTokens).length;
    return overlap >= (titleTokens.length * 0.6).ceil();
  }

  static bool _matchesAnyTitle(String quoted, List<String> validTitles) {
    if (validTitles.isEmpty) return false;
    for (final title in validTitles) {
      if (quoted == title) return true;
      if (quoted.contains(title) || title.contains(quoted)) return true;
      final q = _tokens(quoted);
      final t = _tokens(title);
      if (q.isEmpty || t.isEmpty) continue;
      final overlap = q.intersection(t).length;
      if (overlap >= (t.length * 0.55).ceil()) return true;
    }
    return false;
  }

  static Set<String> _tokens(String normalized) {
    return normalized
        .split(RegExp(r'[^a-zа-я0-9]+'))
        .where((w) => w.length >= 3)
        .toSet();
  }

  static String _norm(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('ё', 'е')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _collapseBlankLines(String text) {
    return text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }
}
