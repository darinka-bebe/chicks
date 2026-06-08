import '../localization/app_locale.dart';

/// Derives a display title from an AI outfit recommendation.
abstract final class OutfitTitleExtractor {
  static String fromRecommendation(String markdown) {
    for (final line in markdown.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('#')) {
        return _clean(trimmed.replaceFirst(RegExp(r'^#+\s*'), ''));
      }
    }

    for (final line in markdown.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty ||
          trimmed.startsWith('-') ||
          trimmed.startsWith('•')) {
        continue;
      }
      final cleaned = _clean(trimmed);
      if (cleaned.isEmpty || _isGenericTitle(cleaned)) continue;
      return _truncate(cleaned);
    }

    return AppLocale.pick(ru: 'Сохранённый образ', en: 'Saved look');
  }

  static String _clean(String value) {
    return value.replaceAll(RegExp(r'\*+'), '').trim();
  }

  static bool _isGenericTitle(String raw) {
    final t = raw.trim().toLowerCase();
    return t.isEmpty ||
        t == 'состав образа' ||
        t == 'состав образа:' ||
        t == 'образ' ||
        t == 'образ:' ||
        t == 'outfit breakdown' ||
        t == 'outfit breakdown:' ||
        t == 'outfit' ||
        t == 'outfit:';
  }

  static String _truncate(String value, [int max = 56]) {
    if (value.length <= max) return value;
    return '${value.substring(0, max - 1).trim()}…';
  }
}
