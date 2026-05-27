import '../models/stylist_request_context.dart';

/// Quick-pick chips above the stylist chat input.
class StylistSuggestionChip {
  const StylistSuggestionChip({
    required this.emoji,
    required this.label,
    required this.promptSnippet,
    this.mood,
    this.weather,
    this.occasion,
  });

  final String emoji;
  final String label;

  /// Russian phrase inserted into the user message.
  final String promptSnippet;
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
      mood: 'romantic',
    ),
    StylistSuggestionChip(
      emoji: '☁',
      label: 'comfy',
      promptSnippet: 'comfy уютный образ',
      mood: 'comfy',
    ),
    StylistSuggestionChip(
      emoji: '🏫',
      label: 'school',
      promptSnippet: 'образ в школу',
      occasion: 'school',
    ),
    StylistSuggestionChip(
      emoji: '🌧',
      label: 'rainy',
      promptSnippet: 'на дождливую погоду',
      weather: 'rainy',
    ),
    StylistSuggestionChip(
      emoji: '✨',
      label: 'elegant',
      promptSnippet: 'элегантный образ',
      mood: 'elegant',
    ),
  ];
}
