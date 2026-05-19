import '../constants/stylist_suggestion_chips.dart';
import '../models/stylist_request_context.dart';

/// Extracts mood, weather, and occasion from a user chat message.
abstract final class StylistContextParser {
  static final _moodKeywords = <String, List<String>>{
    'comfy': ['comfy', 'комфи', 'удобн', 'уютн'],
    'feminine': ['feminine', 'фемин', 'женствен'],
    'confident': ['confident', 'уверен', 'смел'],
    'cozy': ['cozy', 'кози', 'уютн', 'тепл'],
    'romantic': ['romantic', 'романт'],
    'soft girl': ['soft girl', 'софт гёрл', 'софт girl'],
    'elegant': ['elegant', 'элегант', 'изыскан'],
    'dark academia': ['dark academia', 'дарк академ', 'тёмн академ'],
    'streetwear': ['streetwear', 'стритвир', 'стрит', 'urban'],
  };

  static final _weatherKeywords = <String, List<String>>{
    'hot': ['hot', 'жар', 'тепл', 'лет'],
    'cold': ['cold', 'холод', 'мороз', 'зим'],
    'rainy': ['rainy', 'дожд', 'мокр'],
    'windy': ['windy', 'ветер', 'ветрен'],
  };

  static final _occasionKeywords = <String, List<String>>{
    'school': ['school', 'школ', 'учёб', 'учеб'],
    'date': ['date', 'свидан', 'романт вечер'],
    'office': ['office', 'офис', 'работ', 'делов'],
    'walk': ['walk', 'прогул', 'гуля'],
    'party': ['party', 'вечерин', 'праздн', 'клуб'],
  };

  static StylistRequestContext parse(String message) {
    final normalized = message.toLowerCase();

    return StylistRequestContext(
      moods: _matchKeys(normalized, _moodKeywords),
      weather: _matchKeys(normalized, _weatherKeywords),
      occasions: _matchKeys(normalized, _occasionKeywords),
    );
  }

  static List<String> _matchKeys(
    String normalized,
    Map<String, List<String>> keywordMap,
  ) {
    final matches = <String>[];
    for (final entry in keywordMap.entries) {
      if (entry.value.any(normalized.contains)) {
        matches.add(entry.key);
      }
    }
    return matches;
  }

  /// Builds a Russian prompt snippet from selected chip contexts.
  static String buildPromptFromChips(List<StylistSuggestionChip> chips) {
    if (chips.isEmpty) return '';

    final snippets = chips.map((chip) => chip.promptSnippet).toList();
    if (snippets.length == 1) {
      return 'Подбери ${snippets.first}';
    }
    return 'Подбери образ: ${snippets.join(', ')}';
  }
}
