import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../data/models/chat_message.dart';
import '../../data/models/wardrobe_item.dart';
import '../models/stylist_request_context.dart';
import '../models/stylist_response.dart';
import '../utils/logger.dart';
import 'stylist_context_parser.dart';
import 'stylist_response_parser.dart';
import '../models/weather_snapshot.dart';
import 'body_type_prompt_builder.dart';
import 'color_type_prompt_builder.dart';
import 'user_style_profile_loader.dart';
import 'wardrobe_ai_context.dart';
import 'wardrobe_sync_service.dart';
import 'wardrobe_prompt_builder.dart';
import 'wardrobe_prompt_selector.dart';
import 'outfit_preference_prompt_builder.dart';
import 'favorite_preference_prompt_builder.dart';
import 'recent_outfit_prompt_builder.dart';
import 'recent_outfit_memory_loader.dart';
import 'chat_history_limiter.dart';
import 'stylist_system_prompt_merger.dart';
import '../models/user_style_profile.dart';
import '../models/recent_outfit_signals.dart';
import 'stylist_defaults_prompt_builder.dart';
import 'style_insights_loader.dart';
import 'style_insights_prompt_builder.dart';
import 'outfit_recommendation_curator.dart';
import 'outfit_weather_guard.dart';
import 'openai_cost_logger.dart';
import 'stylist_pipeline_logger.dart';
import 'stylist_pipeline_safety.dart';
import 'wardrobe_message_content_sanitizer.dart';
import 'wardrobe_outfit_fallback.dart';
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
  static const _requestTimeout = Duration(seconds: 90);

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
- Цвета: почему оттенки гармонируют.
- Силуэт и посадка: как вещи балансируют друг друга.
- Настроение: как образ передаёт нужный вайб.
- Погода и повод: почему выбор практичен для контекста.
- 2–4 естественные фразы с «почему» достаточно.

Приоритет гардероба (критично):
- В системных сообщениях передан актуальный гардероб, сгруппированный по слотам образа.
- Собирай ЦЕЛОСТНЫЙ лук: максимум 1 вещь на слот (верх ИЛИ платье, низ, верхняя одежда, обувь, аксессуар).
- НИКОГДА не рекомендуй две вещи одной категории.
- Если слота нет — пропусти, не подставляй дубликат.
- Не выдумывай вещи — только id из списка.

Ограничения:
- Не давай медицинских и правовых советов. Не обсуждай темы вне моды и стиля.
''';

  String? get _apiKey => dotenv.env['OPENAI_API_KEY'];

  /// Builds system messages: persona, wardrobe, styling context. Never throws.
  Future<List<Map<String, String>>> buildSystemMessages({
    required String latestUserMessage,
    WeatherSnapshot? liveWeather,
    List<WardrobeItem>? wardrobeSnapshot,
    UserStyleProfile? styleProfile,
    RecentOutfitSignals? recentSignals,
  }) async {
    try {
      List<WardrobeItem> wardrobe;
      try {
        if (wardrobeSnapshot != null) {
          wardrobe = StylistPipelineSafety.sanitizeWardrobe(wardrobeSnapshot);
        } else {
          wardrobe = StylistPipelineSafety.sanitizeWardrobe(
            await WardrobeSyncService.loadFreshWardrobeForAi(),
          );
        }
      } catch (e, stack) {
        StylistPipelineLogger.logFailure('loadWardrobe', e, stack);
        wardrobe = const [];
      }

      final revision = _wardrobeAiContext.revision;

      final requestContext =
          StylistContextParser.parse(latestUserMessage.trim());

      final wardrobeSelection = WardrobePromptSelector.select(
        wardrobe,
        context: requestContext,
      );

      WardrobePromptBuilder.logPromptWardrobe(
        revision: revision,
        selection: wardrobeSelection,
      );
      StylistPipelineLogger.logCategorizedWardrobe(wardrobeSelection.items);

      final weather = StylistPipelineSafety.safeWeather(
        liveWeather ?? await _weatherRepository.getCurrent(),
      );

      final wardrobeSection = WardrobePromptBuilder.buildWardrobeSection(
        wardrobe,
        context: requestContext,
        selection: wardrobeSelection,
      );

      String freshnessGuard;
      try {
        freshnessGuard = WardrobePromptBuilder.buildFreshnessGuard(
          revision: revision,
          selection: wardrobeSelection,
        );
      } catch (e, stack) {
        StylistPipelineLogger.logFailure('freshnessGuard', e, stack);
        freshnessGuard =
            'АКТУАЛЬНОСТЬ ГАРДЕРОБА (ревизия $revision): используй только текущий список вещей.';
      }

      String contextSection;
      try {
        contextSection =
            WardrobePromptBuilder.buildStylingContextSection(requestContext);
      } catch (e, stack) {
        StylistPipelineLogger.logFailure('stylingContext', e, stack);
        contextSection = 'КОНТЕКСТ ЗАПРОСА: учти сообщение пользователя и гардероб.';
      }

      String? weatherSection;
      try {
        weatherSection = WeatherPromptBuilder.buildSystemSection(
          weather: weather,
          userContext: requestContext,
        );
      } catch (e, stack) {
        StylistPipelineLogger.logFailure('weatherSection', e, stack);
        weatherSection = null;
      }

      if (weather.isAvailable) {
        AppLogger.debug(
          'OpenAiChatService: live weather → ${weather.compactUiLabel}',
        );
      }

      final profile = styleProfile ?? await UserStyleProfileLoader.load();
      final recent = recentSignals ?? await RecentOutfitMemoryLoader.load();
      final dislikeProfile = profile.dislikeProfile;
      final colorTypeSection = profile.colorType != null
          ? ColorTypePromptBuilder.buildSystemSection(profile.colorType!)
          : null;
      final bodyTypeSection = profile.bodyProfile != null
          ? BodyTypePromptBuilder.buildSystemSection(profile.bodyProfile!)
          : null;

      final messages = <Map<String, String>>[
        {'role': 'system', 'content': _baseSystemPrompt.trim()},
        {'role': 'system', 'content': wardrobeSection},
        {'role': 'system', 'content': freshnessGuard.trim()},
      ];

      if (colorTypeSection != null && colorTypeSection.trim().isNotEmpty) {
        messages.add({'role': 'system', 'content': colorTypeSection.trim()});
      }

      if (bodyTypeSection != null && bodyTypeSection.trim().isNotEmpty) {
        messages.add({'role': 'system', 'content': bodyTypeSection.trim()});
      }

      final dislikeSection =
          OutfitPreferencePromptBuilder.buildSystemSection(dislikeProfile);
      if (dislikeSection.isNotEmpty) {
        messages.add({'role': 'system', 'content': dislikeSection});
      }

      final favoriteSection = FavoritePreferencePromptBuilder.buildSystemSection(
        profile.favoriteProfile,
      );
      if (favoriteSection.isNotEmpty) {
        messages.add({'role': 'system', 'content': favoriteSection});
      }

      final recentSection = RecentOutfitPromptBuilder.buildSystemSection(recent);
      if (recentSection.isNotEmpty) {
        messages.add({'role': 'system', 'content': recentSection});
      }

      final stylistDefaultsSection = StylistDefaultsPromptBuilder.buildSystemSection(
        profile.stylistDefaults,
      );
      if (stylistDefaultsSection.isNotEmpty) {
        messages.add({'role': 'system', 'content': stylistDefaultsSection});
      }

      try {
        final styleInsights = await StyleInsightsLoader.load();
        final insightsSection =
            StyleInsightsPromptBuilder.buildSystemSection(styleInsights);
        if (insightsSection != null && insightsSection.trim().isNotEmpty) {
          messages.add({'role': 'system', 'content': insightsSection.trim()});
        }
      } catch (e) {
        AppLogger.debug('OpenAiChatService: style insights skipped ($e)');
      }

      if (weatherSection != null && weatherSection.trim().isNotEmpty) {
        messages.add({'role': 'system', 'content': weatherSection});
      }

      messages.addAll([
        {'role': 'system', 'content': contextSection},
        {
          'role': 'system',
          'content': WardrobePromptBuilder.buildResponseFormatSection(
            hasColorType: profile.colorType != null,
            hasBodyType: profile.bodyProfile != null,
          ).trim(),
        },
      ]);

      final compact = StylistSystemPromptMerger.compact(messages);
      final safe = StylistPipelineSafety.sanitizeApiMessages(compact);
      StylistPipelineLogger.logSystemMessages(safe);
      StylistPipelineLogger.logWardrobeItems(wardrobe);

      return safe;
    } catch (e, stack) {
      StylistPipelineLogger.logFailure('buildSystemMessages', e, stack);
      return _minimalSystemMessages();
    }
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

    if (history.isEmpty) {
      return StylistPipelineSafety.fallbackResponse();
    }

    final latestUser = history.lastWhere(
      (message) => message.role == ChatRole.user,
      orElse: () => ChatMessage.user(''),
    );

    WeatherSnapshot weather;
    try {
      weather = StylistPipelineSafety.safeWeather(
        liveWeather ?? await _weatherRepository.getCurrent(),
      );
    } catch (e, stack) {
      StylistPipelineLogger.logFailure('getWeather', e, stack);
      weather = WeatherSnapshot.unavailable;
    }

    final requestContext =
        StylistContextParser.parse(latestUser.content.trim());

    List<WardrobeItem> wardrobe = const [];
    try {
      wardrobe = StylistPipelineSafety.sanitizeWardrobe(
        await WardrobeSyncService.loadFreshWardrobeForAi(),
      );
    } catch (e, stack) {
      StylistPipelineLogger.logFailure('loadWardrobe', e, stack);
    }

    StylistPipelineLogger.logRequestStart(
      userMessage: latestUser.content,
      context: requestContext,
      weather: weather,
      wardrobeCount: wardrobe.length,
      historyLength: history.length,
    );
    StylistPipelineLogger.logCategorizedWardrobe(wardrobe);

    final styleProfile = await UserStyleProfileLoader.load();
    final recentSignals = await RecentOutfitMemoryLoader.load();
    final apiHistory = ChatHistoryLimiter.trimForApi(history);

    try {
      final systemMessages = await buildSystemMessages(
        latestUserMessage: latestUser.content,
        liveWeather: weather,
        wardrobeSnapshot: wardrobe,
        styleProfile: styleProfile,
        recentSignals: recentSignals,
      );

      final messages = StylistPipelineSafety.sanitizeApiMessages([
        ...systemMessages,
        for (final message in apiHistory)
          {
            'role': message.role == ChatRole.user ? 'user' : 'assistant',
            'content': message.content,
          },
      ]);

      if (messages.isEmpty) {
        throw const OpenAiChatException('Не удалось собрать сообщения для API.');
      }

      final requestBody = jsonEncode({
        'model': _model,
        'messages': messages,
        'response_format': const {'type': 'json_object'},
      });

      StylistPipelineLogger.logApiRequest(
        messageCount: messages.length,
        bodyBytes: requestBody.length,
        model: _model,
      );

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: requestBody,
          )
          .timeout(_requestTimeout);

      StylistPipelineLogger.logApiResponse(
        statusCode: response.statusCode,
        bodyBytes: response.bodyBytes.length,
      );

      if (response.statusCode == 200) {
        OpenAiCostLogger.logFromResponse(
          feature: 'stylist_chat',
          model: _model,
          responseBody: response.body,
          requestBodyBytes: requestBody.length,
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode != 200) {
        AppLogger.debug(
          'StylistPipeline: error body=${_preview(response.body)}',
        );
        throw OpenAiChatException(_parseErrorMessage(response));
      }

      final parsed = _parseApiContent(response.body);

      // Re-read Hive after the API round-trip so curation never uses stale data.
      List<WardrobeItem> wardrobeForCuration;
      try {
        wardrobeForCuration = StylistPipelineSafety.sanitizeWardrobe(
          await WardrobeSyncService.loadFreshWardrobeForAi(),
        );
      } catch (e, stack) {
        StylistPipelineLogger.logFailure('reloadWardrobePostApi', e, stack);
        wardrobeForCuration = wardrobe;
      }

      var curatedIds = await _curateRecommendations(
        rawIds: parsed.recommendedItemIds,
        wardrobe: wardrobeForCuration,
        context: requestContext,
        weather: weather,
        styleProfile: styleProfile,
        recentSignals: recentSignals,
      );

      var resolvedItems = WardrobeRecommendationResolver.resolveItems(
        requestedIds: curatedIds,
        wardrobe: wardrobeForCuration,
      );

      if (resolvedItems.isNotEmpty && weather.isAvailable) {
        resolvedItems = OutfitWeatherGuard.repairOutfit(
          current: resolvedItems,
          wardrobe: wardrobeForCuration,
          weather: weather,
          context: requestContext,
          colorType: styleProfile.colorType,
          bodyProfile: styleProfile.bodyProfile,
          preferenceProfile: styleProfile.dislikeProfile,
          favoriteProfile: styleProfile.favoriteProfile,
          recentSignals: recentSignals,
        );
        curatedIds = resolvedItems.map((item) => item.id).toList();
      }

      if (resolvedItems.isEmpty && wardrobeForCuration.isNotEmpty) {
        resolvedItems = WardrobeOutfitFallback.build(
          wardrobe: wardrobeForCuration,
          context: requestContext,
          weather: weather.isAvailable ? weather : null,
          colorType: styleProfile.colorType,
          bodyProfile: styleProfile.bodyProfile,
          preferenceProfile: styleProfile.dislikeProfile,
          favoriteProfile: styleProfile.favoriteProfile,
          recentSignals: recentSignals,
        );
        curatedIds = resolvedItems.map((item) => item.id).toList();
        if (curatedIds.isNotEmpty) {
          AppLogger.info(
            'OpenAiChatService: wardrobe fallback outfit ids=$curatedIds',
          );
        }
      }

      var messageText = parsed.message.isNotEmpty
          ? parsed.message
          : StylistPipelineSafety.fallbackAssistantMessage;

      if (resolvedItems.isNotEmpty) {
        messageText = WardrobeOutfitFallback.enrichMessage(
          message: messageText,
          items: resolvedItems,
        );
      }

      final cleanedMessage = WardrobeMessageContentSanitizer.alignWithValidItems(
        message: messageText,
        validItems: resolvedItems,
      );

      StylistPipelineLogger.logRecommendationSource(
        sourceIds: parsed.recommendedItemIds,
        resultIds: curatedIds,
        wardrobeCount: wardrobeForCuration.length,
      );
      StylistPipelineLogger.logParsedResponse(
        messageLength: cleanedMessage.length,
        rawIds: parsed.recommendedItemIds,
        curatedIds: curatedIds,
      );

      return StylistResponse(
        message: cleanedMessage,
        recommendedItemIds: curatedIds,
      );
    } on OpenAiChatException {
      rethrow;
    } on TimeoutException catch (e, stack) {
      StylistPipelineLogger.logFailure('httpTimeout', e, stack);
      throw const OpenAiChatException(
        'Стилист не ответил вовремя. Попробуйте ещё раз.',
      );
    } on SocketException catch (e, stack) {
      StylistPipelineLogger.logFailure('socket', e, stack);
      throw const OpenAiChatException(
        'Нет соединения с интернетом. Проверьте сеть и попробуйте снова.',
      );
    } catch (e, stack) {
      StylistPipelineLogger.logFailure('completeConversation', e, stack);
      AppLogger.warning(
        'OpenAiChatService: returning in-app fallback (${e.runtimeType})',
      );
      return StylistPipelineSafety.fallbackResponse();
    }
  }

  static List<Map<String, String>> _minimalSystemMessages() {
    return StylistPipelineSafety.sanitizeApiMessages([
      {'role': 'system', 'content': _baseSystemPrompt.trim()},
      {'role': 'system', 'content': StylistPipelineSafety.emptyWardrobeSection},
      {
        'role': 'system',
        'content': WardrobePromptBuilder.buildResponseFormatSection().trim(),
      },
    ]);
  }

  static StylistResponse _parseApiContent(String responseBody) {
    try {
      final body = jsonDecode(responseBody) as Map<String, dynamic>;
      final choices = body['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw const OpenAiChatException('Пустой ответ от OpenAI.');
      }

      final message = choices.first['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        throw const OpenAiChatException('Не удалось получить текст ответа.');
      }

      return StylistResponseParser.parse(content.trim());
    } catch (e) {
      if (e is OpenAiChatException) rethrow;
      throw OpenAiChatException('Ошибка разбора ответа: ${e.runtimeType}');
    }
  }

  static Future<List<String>> _curateRecommendations({
    required List<String> rawIds,
    required List<WardrobeItem> wardrobe,
    required StylistRequestContext context,
    required WeatherSnapshot weather,
    required UserStyleProfile styleProfile,
    required RecentOutfitSignals recentSignals,
  }) async {
    if (rawIds.isEmpty || wardrobe.isEmpty) return const [];

    try {
      return OutfitRecommendationCurator.curateIds(
        requestedIds: rawIds,
        wardrobe: wardrobe,
        context: context,
        weather: weather.isAvailable ? weather : null,
        colorType: styleProfile.colorType,
        bodyProfile: styleProfile.bodyProfile,
        preferenceProfile: styleProfile.dislikeProfile,
        favoriteProfile: styleProfile.favoriteProfile,
        recentSignals: recentSignals,
      );
    } catch (e, stack) {
      StylistPipelineLogger.logFailure('curateRecommendations', e, stack);
      AppLogger.warning(
        'OpenAiChatService: curator failed — using resolved ids',
      );
      try {
        return WardrobeRecommendationResolver.resolveItems(
          requestedIds: rawIds,
          wardrobe: wardrobe,
        ).map((item) => item.id).toList();
      } catch (e2, stack2) {
        StylistPipelineLogger.logFailure('resolveFallback', e2, stack2);
        return const [];
      }
    }
  }

  static String _preview(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 300) return normalized;
    return '${normalized.substring(0, 300)}…';
  }

  static String _parseErrorMessage(http.Response response) {
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
