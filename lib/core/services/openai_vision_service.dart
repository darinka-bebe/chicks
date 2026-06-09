import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../data/models/clothing_vision_analysis.dart';
import '../../data/models/wardrobe_item.dart';
import '../localization/app_locale.dart';
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

  static String _systemPromptFor(Locale? locale) {
    if (AppLocale.isKazakh(locale)) return _systemPromptKk;
    if (AppLocale.isRussian(locale)) return _systemPromptRu;
    return _systemPromptEn;
  }

  static const _systemPromptRu = '''
Ты — AI-модуль распознавания одежды в fashion-приложении Chicks.
По фото определи вещь и верни ТОЛЬКО валидный JSON (без markdown, без пояснений).

Поля:
- title: короткое название на русском (2–6 слов) с отличимой деталью — крой, оттенок, принт, фактура.
- clothingType: тип вещи на русском (рубашка, джинсы, спортивный костюм…)
- category: одна из: Верх, Низ, Платья, Комплекты, Верхняя одежда, Обувь, Аксессуары
- color: основной цвет на русском
- styles: массив из: casual, old money, streetwear, clean girl, sporty, feminine (только подходящие)
- seasons: массив из: Весна, Лето, Осень, Зима, Всесезон (1–2 варианта)
- occasions: массив из: школа, прогулка, office, date, party (подходящие)
- vibes: массив из: минимализм, романтичный, дерзкий, уютный, элегантный, игривый
- fit: одно из: oversized, slim, relaxed, regular (или пустая строка)
- outfitContext: короткая фраза — с чем носить / для какого случая (1 предложение)
- isDuplicate: true ТОЛЬКО если на фото буквально ТОТ ЖЕ предмет из «СУЩЕСТВУЮЩИЙ ГАРДЕРОБ»
- duplicateMatchTitle: точное название строки из списка (пусто если isDuplicate=false)
- recognizable: true в большинстве случаев — если на фото видна одна вещь и можно назвать тип + цвет
- recognitionNote: пустая строка если recognizable=true; иначе — короткая причина

РАСПОЗНАВАНИЕ (баланс):
- Это фото ОДНОЙ вещи для гардероба (на вешалке, на столе, крупный план). Если вещь видна — recognizable=true и заполни поля.
- recognizable=false ТОЛЬКО если вещь реально не разобрать: сильное размытие, почти ничего не видно, кадр без одежды.
- Не отказывай из‑за сложной фактуры, вязки, принта или логотипа — опиши то, что видишь.
- Не выдумывай бренд, если логотип не читается. Цвет и тип вещи — указывай по видимому.

КОМПЛЕКТЫ (критично):
- Если на фото готовый комплект — спортивный костюм, костюм-двойка, коорд-сет, twin set, одинаковый топ+низ в одном кадре — это ОДНА вещь.
- category: «Комплекты». Не разделяй на Верх и Низ.
- title примеры: «Серый спортивный костюм», «Чёрный коорд-сет», «Розовый трикотажный комплект».
- Не создавай две записи из одного фото комплекта.

ОБУВЬ (критично):
- Кроссовки, кеды, ботинки, лоферы, сандалии, туфли, сапоги, шлёпанцы, uggs — category: «Обувь».
- clothingType: кроссовки, кеды, ботинки… title примеры: «Белые кроссовки Nike», «Чёрные кожаные лоферы».
- Не относись обувь к «Верх» или «Аксессуары», даже если на фото только одна пара.

ДУБЛИКАТ — НЕТ (isDuplicate=false), если это другая вещь того же типа.
Если не уверен — isDuplicate=false. Не выдумывай новые категории.
''';

  static const _systemPromptEn = '''
You are Chicks wardrobe vision AI. Analyze the photo and return ONLY valid JSON.

LANGUAGE (critical):
- title, clothingType, color, outfitContext: English only — never use Cyrillic.
- category, seasons, occasions, vibes: use the exact Russian storage tokens listed below.

Fields:
- title: short English name (2–6 words) with a distinguishing detail.
- clothingType: garment type in English (shirt, jeans, tracksuit…)
- category: one of: Верх, Низ, Платья, Комплекты, Верхняя одежда, Обувь, Аксессуары
- color: main color in English (white, black, beige…)
- styles: array from: casual, old money, streetwear, clean girl, sporty, feminine
- seasons: array from: Весна, Лето, Осень, Зима, Всесезон
- occasions: array from: школа, прогулка, office, date, party
- vibes: array from: минимализм, романтичный, дерзкий, уютный, элегантный, игривый
- fit: one of: oversized, slim, relaxed, regular (or empty)
- outfitContext: one short styling sentence in English
- isDuplicate: true ONLY if the photo is the exact same item from EXISTING WARDROBE
- duplicateMatchTitle: exact title from the list (empty if isDuplicate=false)
- recognizable: true in most cases when one garment is visible and type + color can be named
- recognitionNote: empty if recognizable=true; otherwise a short reason

RECOGNITION (balanced):
- This is a single wardrobe item photo (hanger, flat lay, close-up). If the garment is visible — recognizable=true and fill fields.
- recognizable=false ONLY when truly unreadable: extreme blur, almost nothing visible, no clothing in frame.
- Do not refuse because of knit texture, patches, or prints — describe what you see.
- Do not invent brand if logo is unreadable. Name visible color and garment type.

COORDINATED SETS (critical):
- If the photo shows a matching set — tracksuit, suit, co-ord set, twin set, top+bottom sold as one look in one frame — treat it as ONE item.
- category: «Комплекты». Do NOT split into top and bottom.
- title examples: "Gray tracksuit", "Black co-ord set", "Pink knit matching set".
- Never create two wardrobe entries from one set photo.

FOOTWEAR (critical):
- Sneakers, trainers, boots, loafers, sandals, heels, slippers — category: «Обувь».
- clothingType: sneakers, boots, loafers… title examples: "White Nike sneakers", "Black leather loafers".
- Never classify footwear as «Верх» or «Аксессуары».

If unsure about duplicate — isDuplicate=false. Do not invent categories.
''';

  static const _systemPromptKk = '''
You are Chicks wardrobe vision AI. Analyze the photo and return ONLY valid JSON.

LANGUAGE (critical):
- title, clothingType, color, outfitContext: Kazakh only — use Latin script for loanwords if needed.
- category, seasons, occasions, vibes: use the exact Russian storage tokens listed below.

Fields:
- title: short Kazakh name (2–6 words) with a distinguishing detail.
- clothingType: garment type in Kazakh
- category: one of: Верх, Низ, Платья, Комплекты, Верхняя одежда, Обувь, Аксессуары
- color: main color in Kazakh
- styles: array from: casual, old money, streetwear, clean girl, sporty, feminine
- seasons: array from: Весна, Лето, Осень, Зима, Всесезон
- occasions: array from: школа, прогулка, office, date, party
- vibes: array from: минимализм, романтичный, дерзкий, уютный, элегантный, игривый
- fit: one of: oversized, slim, relaxed, regular (or empty)
- outfitContext: one short styling sentence in Kazakh
- isDuplicate: true ONLY if the photo is the exact same item from EXISTING WARDROBE
- duplicateMatchTitle: exact title from the list (empty if isDuplicate=false)
- recognizable: true in most cases when one garment is visible and type + color can be named
- recognitionNote: empty if recognizable=true; otherwise a short reason in Kazakh

RECOGNITION, COORDINATED SETS, FOOTWEAR: same rules as English prompt.
If unsure about duplicate — isDuplicate=false. Do not invent categories.
''';

  Future<ClothingVisionAnalysis> analyzeClothingImage(
    String imagePath, {
    List<WardrobeItem> existingWardrobe = const [],
    Locale? locale,
  }) async {
    final uiLocale = locale ?? AppLocale.effectiveLocale();
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

    final wardrobeBlock = _buildExistingWardrobeBlock(
      existingWardrobe,
      locale: uiLocale,
    );

    AppLogger.debug(
      'OpenAiVisionService: analyzing image (${bytes.length} bytes, $mime) '
      'wardrobeContext=${existingWardrobe.length} locale=${uiLocale.languageCode}',
    );

    final honestyHint = AppLocale.pick(
      ru:
          'Если вещь на фото видна — recognizable=true и заполни поля. Отказ только если реально ничего не разобрать.',
      en:
          'If the garment is visible — recognizable=true and fill fields. Refuse only when truly unreadable.',
      kk:
          'Фотода киім көрінсе — recognizable=true және өрістерді толтыр. Шынымен оқу мүмкін емес болса ғана бас тарту.',
      locale: uiLocale,
    );

    final languageReminder = AppLocale.isRussian(uiLocale)
        ? ''
        : AppLocale.isKazakh(uiLocale)
            ? '\n\nЕСКЕРТУ: title, clothingType, color, outfitContext қазақ тілінде болуы керек.'
            : '\n\nREMINDER: title, clothingType, color, outfitContext must be English (Latin letters only).';

    final userText = wardrobeBlock.isEmpty
        ? AppLocale.pick(
            ru:
                'Проанализируй эту вещь гардероба. $honestyHint Верни JSON по схеме из system.',
            en:
                'Analyze this wardrobe item. $honestyHint Return JSON per the system schema.$languageReminder',
            kk:
                'Гардероб затын талда. $honestyHint JSON қайтар.$languageReminder',
            locale: uiLocale,
          )
        : AppLocale.pick(
            ru:
                '$wardrobeBlock\n\nПроанализируй фото. Если это комплект — одна запись «Комплекты». '
                'duplicateMatchTitle только если это тот же физический предмет из списка. $honestyHint',
            en:
                '$wardrobeBlock\n\nAnalyze the photo. If it is a coordinated set — one «Комплекты» entry. '
                'duplicateMatchTitle only for the exact same physical item from the list. $honestyHint$languageReminder',
            kk:
                '$wardrobeBlock\n\nФотоны талда. Комплект болса — бір «Комплекты» жазба. '
                'duplicateMatchTitle тек тізімдегі сол зат болса. $honestyHint$languageReminder',
            locale: uiLocale,
          );

    final requestBody = jsonEncode({
      'model': _model,
      'response_format': {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': _systemPromptFor(uiLocale).trim()},
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': userText},
            {
              'type': 'image_url',
              'image_url': {'url': dataUrl, 'detail': 'high'},
            },
          ],
        },
      ],
      'max_tokens': 550,
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

  static String _buildExistingWardrobeBlock(
    List<WardrobeItem> wardrobe, {
    Locale? locale,
  }) {
    if (wardrobe.isEmpty) return '';

    final selection = WardrobePromptSelector.select(wardrobe);
    final header = AppLocale.isRussian(locale)
        ? 'СУЩЕСТВУЮЩИЙ ГАРДЕРОБ (${selection.totalCount} вещей):'
        : 'EXISTING WARDROBE (${selection.totalCount} items):';

    final buffer = StringBuffer()..writeln(header);

    for (final item in selection.items) {
      buffer.writeln(
        '- «${item.title.trim()}» | ${item.category.trim()} | ${item.color.trim()}',
      );
    }

    if (selection.wasTruncated) {
      buffer.writeln(
        AppLocale.isRussian(locale)
            ? '(в промпте ${selection.promptCount} из ${selection.totalCount}; '
                'сверяй дубликаты с этим списком)'
            : '(showing ${selection.promptCount} of ${selection.totalCount}; '
                'match duplicates against this list)',
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
