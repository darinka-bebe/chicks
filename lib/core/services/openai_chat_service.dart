import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../data/models/chat_message.dart';
import '../models/stylist_response.dart';
import '../utils/logger.dart';
import 'stylist_context_parser.dart';
import 'stylist_response_parser.dart';
import '../models/weather_snapshot.dart';
import 'wardrobe_ai_context.dart';
import 'wardrobe_prompt_builder.dart';
import 'wardrobe_recommendation_resolver.dart';
import 'weather/weather_prompt_builder.dart';
import 'weather/weather_repository.dart';

/// Calls OpenAI Chat Completions API (GPT-4o-mini).
class OpenAiChatService {
  OpenAiChatService({
    WardrobeAiContext? wardrobeAiContext,
    WeatherRepository? weatherRepository,
  })  : _wardrobeAiContext = wardrobeAiContext ?? WardrobeAiContext.instance,
        _weatherRepository = weatherRepository ?? WeatherRepository.instance;

  static const _endpoint = 'https://api.openai.com/v1/chat/completions';
  static const _model = 'gpt-4o-mini';

  final WardrobeAiContext _wardrobeAiContext;
  final WeatherRepository _weatherRepository;

  static const _baseSystemPrompt = '''
Ты — персональный fashion-стилист приложения Chicks: умный ассистент по стилю, гардеробу и образам.

Роль и тон:
- Общайся как stylist assistant: дружелюбно, современно, уверенно, без снобизма.
- Поддерживай пользователя, вдохновляй, предлагай решения, а не только теорию.
- Иногда добавляй уместные эмодзи (1–2 на ответ), не перегружай текст.

Как отвечать:
- Всегда на русском языке.
- Кратко и по делу: 2–5 абзацев или списки, без воды.
- Структурируй ответ: заголовки/пункты, если советов несколько.
- Учитывай актуальные тренды, но предлагай носибельные и практичные варианты.
- Давай конкретные советы по сочетаниям: цвета, фактуры, силуэты, обувь, аксессуары.
- При нехватке данных задай 1 уточняющий вопрос вместо длинной лекции.

Объясняй ПОЧЕМУ образ работает (обязательно):
- Не ограничивайся списком вещей — после состава образа дай короткое стильное объяснение логики.
- Цвета: почему оттенки гармонируют (например: «светлые нейтрали дают мягкий feminine-вайб», «контраст верха и низа стройнит силуэт»).
- Силуэт и посадка: как вещи балансируют друг друга (например: «oversized пиджак уравновешивает slim джинсы», «relaxed свитер добавляет уют без лишнего объёма снизу»).
- Настроение: как образ передаёт нужный вайб (romantic, comfy, elegant и т.д.) через фактуры, цвет и пропорции.
- Погода и повод: почему выбор практичен для контекста (слои для холода, закрытая обувь для дождя, сдержанность для школы/офиса).
- Пиши как живой стилист: тепло, уверенно, без канцелярита и шаблонов вроде «данный образ является» / «рекомендуется использовать».
- 2–4 естественные фразы с «почему» достаточно — не превращай ответ в лекцию.

Приоритет гардероба (критично):
- В системных сообщениях передан актуальный гардероб и контекст запроса (настроение, погода, повод).
- Сначала используй вещи из гардероба; только потом нейтральную докупку, если элемента нет в списке.
- Не выдумывай вещи и не подменяй названия — только формулировки из гардероба.
- Комбинируй: гардероб + настроение + погода + повод в одном связном образе.

Контекст образа:
- Настроение / вайб: comfy, feminine, confident, cozy, romantic, soft girl, elegant, dark academia и др.
- Погода: hot, cold, rainy, windy (жара, холод, дождь, ветер).
- Повод: school, date, office, walk, party (школа, свидание, офис, прогулка, вечеринка).
- Если пользователь комбинирует несколько сигналов — учти все (например comfy + school + cold).

Темы:
- Подбор образов, капсульный гардероб, dress code, сезон, тип фигуры, цветотип (осторожно, без категоричности).
- Что с чем сочетать, как обновить базовый гардероб, что докупить к имеющим вещам.

Ограничения:
- Не давай медицинских и правовых советов. Не обсуждай темы вне моды и стиля.
''';

  String? get _apiKey => dotenv.env['OPENAI_API_KEY'];

  /// Builds system messages: persona, wardrobe, styling context.
  Future<List<Map<String, String>>> buildSystemMessages({
    required String latestUserMessage,
    WeatherSnapshot? liveWeather,
  }) async {
    final revision = _wardrobeAiContext.revision;
    final wardrobe = await _wardrobeAiContext.loadForPrompt();
    final requestContext = StylistContextParser.parse(latestUserMessage);

    WardrobePromptBuilder.logPromptWardrobe(
      revision: revision,
      items: wardrobe,
    );

    AppLogger.debug(
      'OpenAiChatService: wardrobe=${wardrobe.length} rev=$revision '
      'mood=${requestContext.moods} weather=${requestContext.weather} '
      'occasion=${requestContext.occasions}',
    );

    final wardrobeSection = WardrobePromptBuilder.buildWardrobeSection(wardrobe);
    final freshnessGuard = WardrobePromptBuilder.buildFreshnessGuard(
      revision: revision,
      items: wardrobe,
    );
    final contextSection =
        WardrobePromptBuilder.buildStylingContextSection(requestContext);

    final weather = liveWeather ?? await _weatherRepository.getCurrent();
    final weatherSection = WeatherPromptBuilder.buildSystemSection(
      weather: weather,
      userContext: requestContext,
    );

    if (weather.isAvailable) {
      AppLogger.debug(
        'OpenAiChatService: live weather → ${weather.compactUiLabel}',
      );
    }

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _baseSystemPrompt.trim()},
      {'role': 'system', 'content': wardrobeSection},
      {'role': 'system', 'content': freshnessGuard.trim()},
    ];

    if (weatherSection != null) {
      messages.add({'role': 'system', 'content': weatherSection});
    }

    messages.addAll([
      {'role': 'system', 'content': contextSection},
      {
        'role': 'system',
        'content': WardrobePromptBuilder.buildResponseFormatSection().trim(),
      },
    ]);

    return messages;
  }

  Future<StylistResponse> completeConversation(
    List<ChatMessage> history, {
    WeatherSnapshot? liveWeather,
  }) async {
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw const OpenAiChatException(
        'OPENAI_API_KEY не задан. Добавьте ключ в файл .env в корне проекта.',
      );
    }

    final latestUser = history.lastWhere(
      (message) => message.role == ChatRole.user,
      orElse: () => ChatMessage.user(''),
    );

    final systemMessages = await buildSystemMessages(
      latestUserMessage: latestUser.content,
      liveWeather: liveWeather,
    );

    final messages = <Map<String, String>>[
      ...systemMessages,
      for (final message in history)
        {
          'role': message.role == ChatRole.user ? 'user' : 'assistant',
          'content': message.content,
        },
    ];

    AppLogger.debug(
      'OpenAiChatService: sending ${messages.length} message(s) to OpenAI',
    );

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'response_format': const {'type': 'json_object'},
      }),
    );

    if (response.statusCode != 200) {
      throw OpenAiChatException(_parseErrorMessage(response));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = body['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw const OpenAiChatException('Пустой ответ от OpenAI.');
    }

    final message = choices.first['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw const OpenAiChatException('Не удалось получить текст ответа.');
    }

    final parsed = StylistResponseParser.parse(content.trim());
    final wardrobe = await _wardrobeAiContext.loadForPrompt();
    final validIds = WardrobeRecommendationResolver.filterValidIds(
      requestedIds: parsed.recommendedItemIds,
      wardrobe: wardrobe,
    );

    AppLogger.info(
      'OpenAiChatService: stylist reply ids '
      'raw=${parsed.recommendedItemIds.length} valid=${validIds.length}',
    );

    return StylistResponse(
      message: parsed.message,
      recommendedItemIds: validIds,
    );
  }

  String _parseErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String?;
      if (message != null && message.isNotEmpty) {
        return message;
      }
    } catch (_) {
      // ignore parse errors
    }
    return 'Ошибка API (${response.statusCode})';
  }
}

class OpenAiChatException implements Exception {
  final String message;

  const OpenAiChatException(this.message);

  @override
  String toString() => message;
}
