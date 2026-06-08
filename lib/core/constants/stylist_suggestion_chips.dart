import '../localization/app_locale.dart';
import '../models/stylist_request_context.dart';

/// Quick-pick chips above the stylist chat input.
class StylistSuggestionChip {
  const StylistSuggestionChip({
    required this.emoji,
    required this.label,
    required this.promptSnippet,
    required this.promptSnippetEn,
    this.mood,
    this.weather,
    this.occasion,
  });

  final String emoji;
  final String label;

  /// Phrase inserted into the user message (Russian).
  final String promptSnippet;

  /// English phrase for EN locale devices.
  final String promptSnippetEn;

  String get localizedPromptSnippet =>
      AppLocale.pick(ru: promptSnippet, en: promptSnippetEn);
  final String? mood;
  final String? weather;
  final String? occasion;

  String get displayLabel => '$emoji $label';

  StylistRequestContext get context => StylistRequestContext(
        moods: mood != null ? [mood!] : const [],
        weather: weather != null ? [weather!] : const [],
        occasions: occasion != null ? [occasion!] : const [],
      );
}

/// Supported moods, weather, and occasions for prompt matching.
abstract final class StylistContextCatalog {
  static const moods = [
    'comfy',
    'feminine',
    'confident',
    'cozy',
    'romantic',
    'soft girl',
    'elegant',
  ];

  static const weather = ['hot', 'cold', 'rainy', 'windy'];

  static const occasions = ['school', 'date', 'office', 'walk', 'party'];

  static bool isAllowedMood(String tag) => _isAllowed(tag, moods);

  static bool isAllowedWeather(String tag) => _isAllowed(tag, weather);

  static bool isAllowedOccasion(String tag) => _isAllowed(tag, occasions);

  static List<String> filterMoods(Iterable<String> tags) =>
      _filter(tags, moods);

  static List<String> filterWeather(Iterable<String> tags) =>
      _filter(tags, weather);

  static List<String> filterOccasions(Iterable<String> tags) =>
      _filter(tags, occasions);

  static String displayMood(String tag) => switch (tag.toLowerCase()) {
        'comfy' => AppLocale.pick(ru: 'уютный', en: 'Comfy'),
        'feminine' => AppLocale.pick(ru: 'женственный', en: 'Feminine'),
        'confident' => AppLocale.pick(ru: 'уверенный', en: 'Confident'),
        'cozy' => AppLocale.pick(ru: 'уютный', en: 'Cozy'),
        'romantic' => AppLocale.pick(ru: 'романтичный', en: 'Romantic'),
        'soft girl' => AppLocale.pick(ru: 'soft girl', en: 'Soft girl'),
        'elegant' => AppLocale.pick(ru: 'элегантный', en: 'Elegant'),
        _ => tag,
      };

  static String displayWeather(String tag) => switch (tag.toLowerCase()) {
        'hot' => AppLocale.pick(ru: 'жарко', en: 'Hot'),
        'cold' => AppLocale.pick(ru: 'холодно', en: 'Cold'),
        'rainy' => AppLocale.pick(ru: 'дождь', en: 'Rainy'),
        'windy' => AppLocale.pick(ru: 'ветрено', en: 'Windy'),
        _ => tag,
      };

  static String displayOccasion(String tag) => switch (tag.toLowerCase()) {
        'school' => AppLocale.pick(ru: 'школа', en: 'School'),
        'date' => AppLocale.pick(ru: 'свидание', en: 'Date'),
        'office' => AppLocale.pick(ru: 'офис', en: 'Office'),
        'walk' => AppLocale.pick(ru: 'прогулка', en: 'Walk'),
        'party' => AppLocale.pick(ru: 'вечеринка', en: 'Party'),
        _ => tag,
      };

  static String displayContextTag(String tag) {
    final lower = tag.trim().toLowerCase();
    if (moods.any((m) => m.toLowerCase() == lower)) {
      return displayMood(tag);
    }
    if (weather.any((w) => w.toLowerCase() == lower)) {
      return displayWeather(tag);
    }
    if (occasions.any((o) => o.toLowerCase() == lower)) {
      return displayOccasion(tag);
    }
    return tag;
  }

  static bool _isAllowed(String tag, List<String> allowed) {
    final needle = tag.trim().toLowerCase();
    if (needle.isEmpty) return false;
    return allowed.any((entry) => entry.toLowerCase() == needle);
  }

  static List<String> _filter(Iterable<String> tags, List<String> allowed) {
    final seen = <String>{};
    final result = <String>[];
    for (final tag in tags) {
      final needle = tag.trim().toLowerCase();
      if (needle.isEmpty) continue;
      for (final entry in allowed) {
        if (entry.toLowerCase() != needle) continue;
        if (seen.add(entry)) result.add(entry);
        break;
      }
    }
    return result;
  }

  static const suggestionChips = [
    StylistSuggestionChip(
      emoji: '💖',
      label: 'romantic',
      promptSnippet: 'романтичный образ',
      promptSnippetEn: 'a romantic outfit',
      mood: 'romantic',
    ),
    StylistSuggestionChip(
      emoji: '☁',
      label: 'comfy',
      promptSnippet: 'comfy уютный образ',
      promptSnippetEn: 'a comfy cozy outfit',
      mood: 'comfy',
    ),
    StylistSuggestionChip(
      emoji: '🏫',
      label: 'school',
      promptSnippet: 'образ в школу',
      promptSnippetEn: 'a school outfit',
      occasion: 'school',
    ),
    StylistSuggestionChip(
      emoji: '🌧',
      label: 'rainy',
      promptSnippet: 'на дождливую погоду',
      promptSnippetEn: 'a rainy-day outfit',
      weather: 'rainy',
    ),
    StylistSuggestionChip(
      emoji: '✨',
      label: 'elegant',
      promptSnippet: 'элегантный образ',
      promptSnippetEn: 'an elegant outfit',
      mood: 'elegant',
    ),
  ];
}
