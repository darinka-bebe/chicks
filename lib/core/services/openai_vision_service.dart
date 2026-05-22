import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../data/models/clothing_vision_analysis.dart';
import '../../data/models/wardrobe_item.dart';
import '../utils/logger.dart';
import 'openai_chat_service.dart';
import 'openai_cost_logger.dart';
import 'wardrobe_prompt_selector.dart';

/// Analyzes clothing photos via OpenAI Vision (Chat Completions + image).
class OpenAiVisionService {
  OpenAiVisionService({http.Client? client}) : _client = client ?? http.Client();

  static const _endpoint = 'https://api.openai.com/v1/chat/completions';
  static const _model = 'gpt-4o-mini';

  final http.Client _client;

  String? get _apiKey => dotenv.env['OPENAI_API_KEY'];

  static const _systemPrompt = '''
Ты — AI-модуль распознавания одежды в fashion-приложении Chicks.
По фото определи вещь и верни ТОЛЬКО валидный JSON (без markdown, без пояснений).

Поля:
- title: короткое название на русском (2–5 слов) с отличимой деталью — крой, оттенок, посадка, фактура (не только «джинсы» или «рубашка»). Пример: «Синие джинсы wide leg», «Голубые джинсы клеш»
- clothingType: тип вещи на русском (рубашка, джинсы, платье…)
- category: одна из: Верх, Низ, Платья, Верхняя одежда, Обувь, Аксессуары
- color: основной цвет на русском
- styles: массив из: casual, old money, streetwear, clean girl, sporty, feminine (только подходящие)
- seasons: массив из: Весна, Лето, Осень, Зима, Всесезон (1–2 варианта)
- occasions: массив из: школа, прогулка, office, date, party (подходящие)
- vibes: массив из: минимализм, романтичный, дерзкий, уютный, элегантный, игривый
- fit: одно из: oversized, slim, relaxed, regular (или пустая строка)
- outfitContext: короткая фраза на русском — с чем носить / для какого случая (1 предложение)
- isDuplicate: true ТОЛЬКО если на фото буквально ТОТ ЖЕ предмет из «СУЩЕСТВУЮЩИЙ ГАРДЕРОБ» (повторное фото той же вещи; другой ракурс допустим)
- duplicateMatchTitle: точное название строки из списка (пусто если isDuplicate=false)

ДУБЛИКАТ — НЕТ (isDuplicate=false), если это другая вещь того же типа:
• другая пара джинс / другая рубашка / другая юбка, даже синяя и широкая;
• похожий цвет и категория, но другой крой, модель, принт или фактура;
• в гардеробе уже есть «Широкие джинсы», а на фото другие джинсы — это НОВАЯ вещь.

Если не уверен — isDuplicate=false. Не выдумывай новые категории.
''';

  Future<ClothingVisionAnalysis> analyzeClothingImage(
    String imagePath, {
    List<WardrobeItem> existingWardrobe = const [],
  }) async {
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw const OpenAiChatException(
        'OPENAI_API_KEY не задан. Добавьте ключ в файл .env в корне проекта.',
      );
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      throw const OpenAiChatException('Файл изображения не найден.');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const OpenAiChatException('Изображение пустое.');
    }

    final mime = _mimeFromPath(imagePath);
    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

    final wardrobeBlock = _buildExistingWardrobeBlock(existingWardrobe);

    AppLogger.debug(
      'OpenAiVisionService: analyzing image (${bytes.length} bytes, $mime) '
      'wardrobeContext=${existingWardrobe.length}',
    );

    final requestBody = jsonEncode({
        'model': _model,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': _systemPrompt.trim()},
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': wardrobeBlock.isEmpty
                    ? 'Проанализируй эту вещь гардероба и верни JSON по схеме из system.'
                    : '$wardrobeBlock\n\nПроанализируй фото. duplicateMatchTitle только если это тот же физический предмет из списка, не похожая новая вещь.',
              },
              {
                'type': 'image_url',
                'image_url': {'url': dataUrl, 'detail': 'low'},
              },
            ],
          },
        ],
        'max_tokens': 500,
      });

    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: requestBody,
    );

    if (response.statusCode == 200) {
      OpenAiCostLogger.logFromResponse(
        feature: 'wardrobe_vision',
        model: _model,
        responseBody: response.body,
        requestBodyBytes: requestBody.length,
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode != 200) {
      AppLogger.error(
        'OpenAiVisionService: API error ${response.statusCode}',
      );
      throw OpenAiChatException(_parseErrorMessage(response));
    }

    final content = _extractContent(response.body);
    final json = _parseJsonContent(content);
    final analysis = ClothingVisionAnalysis.fromJson(json);
    if (analysis.isDuplicate) {
      AppLogger.info(
        'OpenAiVisionService: duplicate hint → "${analysis.duplicateMatchTitle}"',
      );
    }
    AppLogger.info('OpenAiVisionService: analysis parsed successfully');
    return analysis;
  }

  static String _buildExistingWardrobeBlock(List<WardrobeItem> wardrobe) {
    if (wardrobe.isEmpty) return '';

    final selection = WardrobePromptSelector.select(wardrobe);
    final buffer = StringBuffer()
      ..writeln('СУЩЕСТВУЮЩИЙ ГАРДЕРОБ (${selection.totalCount} вещей):');

    for (final item in selection.items) {
      buffer.writeln(
        '- «${item.title.trim()}» | ${item.category.trim()} | ${item.color.trim()}',
      );
    }

    if (selection.wasTruncated) {
      buffer.writeln(
        '(в промпте ${selection.promptCount} из ${selection.totalCount}; '
        'сверяй дубликаты с этим списком)',
      );
    }

    return buffer.toString().trim();
  }

  String _extractContent(String body) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw const OpenAiChatException('Пустой ответ от OpenAI Vision.');
    }
    final message = choices.first['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw const OpenAiChatException('Не удалось получить анализ изображения.');
    }
    return content.trim();
  }

  Map<String, dynamic> _parseJsonContent(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (e) {
      AppLogger.error('OpenAiVisionService: JSON parse failed', error: e);
    }

    final start = content.indexOf('{');
    final end = content.lastIndexOf('}');
    if (start >= 0 && end > start) {
      try {
        final decoded = jsonDecode(content.substring(start, end + 1));
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {}
    }

    throw const OpenAiChatException(
      'Не удалось разобрать ответ AI. Заполните поля вручную.',
    );
  }

  String _mimeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  String _parseErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String?;
      if (message != null && message.isNotEmpty) {
        return message;
      }
    } catch (_) {}
    return 'Ошибка Vision API (${response.statusCode})';
  }
}
