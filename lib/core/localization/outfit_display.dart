import '../../data/models/favorite_outfit.dart';
import '../../data/models/outfit_history_entry.dart';
import '../services/outfit_title_extractor.dart';
import 'app_locale.dart';

/// Display helpers for saved outfit history entries.
abstract final class OutfitDisplay {
  static final _cyrillic = RegExp(r'[А-Яа-яЁё]');

  static bool isGenericTitle(String raw) {
    final t = raw.replaceAll('*', '').trim().toLowerCase();
    if (t.isEmpty) return true;
    const generic = {
      'состав образа',
      'состав образа:',
      'образ',
      'образ:',
      'outfit breakdown',
      'outfit breakdown:',
      'outfit',
      'outfit:',
      'saved look',
      'сохранённый образ',
    };
    return generic.contains(t);
  }

  static String compositionHeading() => AppLocale.pick(
        ru: 'Состав образа',
        en: 'Outfit breakdown',
        kk: 'Образ құрамы',
      );

  /// Title for the home «Outfit of the day» card.
  static String homeTitle(OutfitHistoryEntry entry) {
    final stored = entry.title.trim();
    if (!isGenericTitle(stored) && _matchesLocale(stored)) {
      return stored;
    }

    final extracted = OutfitTitleExtractor.fromRecommendation(entry.aiResponseText);
    if (!isGenericTitle(extracted)) return extracted;

    return AppLocale.pick(
      ru: 'Сохранённый образ',
      en: 'Saved look',
      kk: 'Сақталған образ',
    );
  }

  /// Subtitle for the home card — never raw Russian user text on EN UI.
  static String? homeSubtitle(OutfitHistoryEntry entry) {
    final excerpt = _aiExcerpt(entry.aiResponseText);
    if (excerpt.isNotEmpty && _matchesLocale(excerpt)) return excerpt;

    final prompt = entry.userPrompt.trim();
    if (prompt.isNotEmpty && _matchesLocale(prompt)) return prompt;

    final count = entry.recommendedItemIds.length;
    if (count > 0) {
      return AppLocale.pick(
        ru: '$count ${_itemsLabelRu(count)} из гардероба',
        en: '$count ${_itemsLabelEn(count)} from your wardrobe',
        kk: 'Гардеробтан $count ${_itemsLabelKk(count)}',
      );
    }

    return AppLocale.pick(
      ru: 'Открой чат, чтобы посмотреть образ',
      en: 'Open chat to view your latest look',
      kk: 'Соңғы образды көру үшін чатты ашыңыз',
    );
  }

  static bool _matchesLocale(String text) {
    final hasCyrillic = _cyrillic.hasMatch(text);
    if (AppLocale.isRussian()) return true;
    if (AppLocale.isKazakh()) return !hasCyrillic;
    return !hasCyrillic;
  }

  static String _aiExcerpt(String markdown) {
    final buffer = StringBuffer();
    var skippedComposition = false;

    for (final raw in markdown.split('\n')) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;

      final cleaned = trimmed.replaceAll(RegExp(r'\*+'), '').trim();
      if (!skippedComposition) {
        if (isGenericTitle(cleaned) || trimmed.startsWith('•')) {
          continue;
        }
        skippedComposition = true;
      }

      if (trimmed.startsWith('-') ||
          trimmed.startsWith('•') ||
          isGenericTitle(cleaned)) {
        continue;
      }

      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(cleaned);
      if (buffer.length >= 100) break;
    }

    final text = buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return '';
    if (text.length <= 120) return text;
    return '${text.substring(0, 117).trim()}…';
  }

  static String _itemsLabelRu(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod100 >= 11 && mod100 <= 14) return 'вещей';
    if (mod10 == 1) return 'вещь';
    if (mod10 >= 2 && mod10 <= 4) return 'вещи';
    return 'вещей';
  }

  static String _itemsLabelEn(int count) => count == 1 ? 'item' : 'items';

  static String _itemsLabelKk(int count) => 'зат';

  /// Title for favorite look cards.
  static String favoriteTitle(FavoriteOutfit outfit) {
    final stored = outfit.title.trim();
    if (!isGenericTitle(stored) && _matchesLocale(stored)) {
      return stored;
    }

    final extracted =
        OutfitTitleExtractor.fromRecommendation(outfit.recommendation);
    if (!isGenericTitle(extracted)) return extracted;

    return AppLocale.pick(
      ru: 'Сохранённый образ',
      en: 'Saved look',
      kk: 'Сақталған образ',
    );
  }

  /// Excerpt for favorite look list cards — hides Russian AI text on EN UI.
  static String favoriteExcerpt(FavoriteOutfit outfit) {
    final excerpt = _aiExcerpt(outfit.recommendation);
    if (excerpt.isNotEmpty && _matchesLocale(excerpt)) return excerpt;

    final count = outfit.recommendedItemIds.length;
    if (count > 0) {
      return AppLocale.pick(
        ru: '$count ${_itemsLabelRu(count)} из гардероба',
        en: '$count ${_itemsLabelEn(count)} from your wardrobe',
        kk: 'Гардеробтан $count ${_itemsLabelKk(count)}',
      );
    }

    return AppLocale.pick(
      ru: 'Открой, чтобы прочитать рекомендацию',
      en: 'Open to read the full recommendation',
      kk: 'Толық ұсынысты оқу үшін ашыңыз',
    );
  }
}
