import '../../data/models/wardrobe_item.dart';
import '../models/stylist_request_context.dart';

/// Builds readable wardrobe and styling context for the AI stylist system prompt.
abstract final class WardrobePromptBuilder {
  /// Full wardrobe block for OpenAI `system` message.
  static String buildWardrobeSection(List<WardrobeItem> items) {
    if (items.isEmpty) {
      return _emptyWardrobePrompt;
    }

    final sorted = List<WardrobeItem>.from(items)
      ..sort((a, b) => a.category.compareTo(b.category));

    final buffer = StringBuffer()
      ..writeln('ГАРДЕРОБ ПОЛЬЗОВАТЕЛЯ (${sorted.length} вещей)')
      ..writeln()
      ..writeln(
        'Названия вещей (в ответе используй ТОЧНО эти формулировки в кавычках «…»):',
      );

    for (final item in sorted) {
      buffer.writeln('- ${item.title}');
    }

    buffer
      ..writeln()
      ..writeln('Детали по каждой вещи:');

    for (var i = 0; i < sorted.length; i++) {
      buffer.writeln('${i + 1}. ${formatItemLine(sorted[i])}');
    }

    buffer.writeln(_wardrobeRecommendationRules);
    return buffer.toString().trim();
  }

  /// Mood / weather / occasion guidance for the current user message.
  static String buildStylingContextSection(StylistRequestContext context) {
    final buffer = StringBuffer()
      ..writeln('КОНТЕКСТ ЗАПРОСА (настроение / погода / повод):');

    if (context.isEmpty) {
      buffer.writeln(
        'Явные теги в сообщении не распознаны — выведи настроение, погоду и повод '
        'из формулировки пользователя и сопоставь с тегами вещей в гардеробе.',
      );
    } else {
      if (context.moods.isNotEmpty) {
        buffer.writeln('- Настроение / вайб: ${context.moods.join(', ')}');
      }
      if (context.weather.isNotEmpty) {
        buffer.writeln('- Погода: ${context.weather.join(', ')}');
      }
      if (context.occasions.isNotEmpty) {
        buffer.writeln('- Повод: ${context.occasions.join(', ')}');
      }
    }

    buffer.writeln(_contextMatchingGuide);
    return buffer.toString().trim();
  }

  /// Single-line wardrobe entry for the prompt.
  static String formatItemLine(WardrobeItem item) {
    final parts = <String>[
      '«${item.title}»',
      'категория: ${item.category}',
      'цвет: ${item.color}',
      'сезон: ${item.season}',
    ];

    if (item.fit.isNotEmpty) {
      parts.add('посадка: ${item.fit}');
    }
    if (item.styles.isNotEmpty) {
      parts.add('стиль: ${item.styles.join(', ')}');
    }
    if (item.occasions.isNotEmpty) {
      parts.add('повод: ${item.occasions.join(', ')}');
    }
    if (item.vibes.isNotEmpty) {
      parts.add('вайб: ${item.vibes.join(', ')}');
    }

    return parts.join(' | ');
  }

  static const _emptyWardrobePrompt = '''
ГАРДЕРОБ ПОЛЬЗОВАТЕЛЯ:
Список вещей пуст. Дай универсальные советы по стилю и мягко предложи добавить вещи в раздел «Твой гардероб» в приложении.
Не называй конкретные вещи пользователя, которых нет в данных.''';

  static const _wardrobeRecommendationRules = '''

Правила персональных рекомендаций:
- Собирай образы ТОЛЬКО из списка выше. В ответе обязательно называй вещи точными названиями в кавычках «…».
- Сочетай гардероб с настроением, погодой и поводом из контекста запроса (следующее системное сообщение).
- Сначала подбери максимум вещей из гардероба; докупку предлагай только если элемента нет в списке.
- Учитывай теги «повод», «стиль», «сезон», «посадка», «вайб» на каждой вещи.
- Отвечай на русском, живо и по делу (2–4 абзаца или список).''';

  static const _contextMatchingGuide = '''

Как сопоставлять контекст с гардеробом:
- Настроение (comfy, feminine, confident, cozy, romantic, soft girl, elegant, dark academia):
  ищи вещи с похожими тегами «стиль» / «вайб»; для romantic/elegant — более утончённые сочетания.
- Погода:
  • hot — лёгкие ткани, сезон «Лето» / «Весна»;
  • cold — слои, «Зима» / «Осень», верхняя одежда;
  • rainy — закрытая обувь, плащ/тренч, не холодные открытые сандалии;
  • windy — устойчивые силуэты, не слишком объёмные юбки без слоёв.
- Повод:
  • school — повод «школа», casual/clean girl, без слишком яркого party-лукa;
  • date — romantic/feminine, аккуратные сочетания;
  • office — office в тегах, сдержанные цвета;
  • walk — прогулка, comfy/casual;
  • party — ярче, смелее, но из гардероба.

Пример: «Подбери comfy образ в школу на холодную погоду»
→ comfy + school + cold: «Белая рубашка» + «Джинсы straight» + «Кашемировый свитер» + обувь из гардероба; объясни слоями для холода.''';
}
