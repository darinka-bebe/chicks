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
