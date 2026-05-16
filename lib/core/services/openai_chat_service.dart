import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../data/models/chat_message.dart';

/// Calls OpenAI Chat Completions API (GPT-4o-mini).
class OpenAiChatService {
  static const _endpoint = 'https://api.openai.com/v1/chat/completions';
  static const _model = 'gpt-4o-mini';

  static const _systemPrompt = '''
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

Темы:
- Подбор образов, капсульный гардероб, dress code, сезон, тип фигуры, цветотип (осторожно, без категоричности).
- Что с чем сочетать, как обновить базовый гардероб, что докупить к имеющим вещам.

Ограничения:
- Не выдумывай факты о гардеробе пользователя — опирайся на то, что он написал.
- Не давай медицинских и правовых советов. Не обсуждай темы вне моды и стиля.
''';

  String? get _apiKey => dotenv.env['OPENAI_API_KEY'];

  Future<String> completeConversation(List<ChatMessage> history) async {
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw const OpenAiChatException(
        'OPENAI_API_KEY не задан. Добавьте ключ в файл .env в корне проекта.',
      );
    }

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt},
      for (final message in history)
        {
          'role': message.role == ChatRole.user ? 'user' : 'assistant',
          'content': message.content,
        },
    ];

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
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

    return content.trim();
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
