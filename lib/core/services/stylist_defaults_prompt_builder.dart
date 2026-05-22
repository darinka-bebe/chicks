import '../models/stylist_defaults.dart';

/// Injects learned mood/occasion habits into the stylist system prompt.
abstract final class StylistDefaultsPromptBuilder {
  static String buildSystemSection(StylistDefaults defaults) {
    if (!defaults.hasSignals) return '';

    final parts = <String>[];

    final moods = defaults.topMoods();
    if (moods.isNotEmpty) {
      parts.add('частые настроения: ${moods.join(', ')}');
    }

    final occasions = defaults.topOccasions();
    if (occasions.isNotEmpty) {
      parts.add('частые поводы: ${occasions.join(', ')}');
    }

    final weather = defaults.topWeather();
    if (weather.isNotEmpty) {
      parts.add('погодные запросы: ${weather.join(', ')}');
    }

    final notes = defaults.styleNotes.trim();
    if (notes.isNotEmpty) {
      parts.add('заметки пользователя: $notes');
    }

    if (parts.isEmpty) return '';

    return '''
ПРЕДПОЧТЕНИЯ ИЗ ЧАТА (учитывай при подборе):
${parts.map((p) => '• $p').join('\n')}
'''.trim();
  }
}
