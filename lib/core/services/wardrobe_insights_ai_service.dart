import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/wardrobe_analysis_snapshot.dart';
import '../models/wardrobe_insight.dart';
import '../utils/logger.dart';

/// Optional compact AI pass — adds up to 2 stylist tips from a wardrobe summary.
abstract final class WardrobeInsightsAiService {
  static const _endpoint = 'https://api.openai.com/v1/chat/completions';
  static const _model = 'gpt-4o-mini';
  static const _timeout = Duration(seconds: 45);

  static Future<List<WardrobeInsight>> fetchExtraInsights(
    WardrobeAnalysisSnapshot snapshot,
  ) async {
    final apiKey = dotenv.env['OPENAI_API_KEY']?.trim();
    if (apiKey == null || apiKey.isEmpty) return const [];
    if (snapshot.totalItems < 3) return const [];

    final body = jsonEncode({
      'model': _model,
      'response_format': const {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content': '''
Ты fashion-аналитик. По КРАТКОЙ сводке гардероба дай 1–2 коротких совета на русском.
Тон: дружелюбный стилист, не робот. Без markdown.
JSON: {"insights":[{"title":"...","body":"..."}]}
title ≤ 50 символов, body ≤ 180 символов. Только практичные наблюдения, не выдумывай вещи.''',
        },
        {
          'role': 'user',
          'content': 'Сводка: ${snapshot.compactSummary}',
        },
      ],
    });

    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        AppLogger.warning(
          'WardrobeInsightsAi: API ${response.statusCode}',
        );
        return const [];
      }

      return _parse(response.body);
    } catch (e, stack) {
      AppLogger.error(
        'WardrobeInsightsAi: request failed',
        error: e,
        stackTrace: stack,
      );
      return const [];
    }
  }

  static List<WardrobeInsight> _parse(String responseBody) {
    try {
      final root = jsonDecode(responseBody) as Map<String, dynamic>;
      final choices = root['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) return const [];

      final content =
          (choices.first as Map<String, dynamic>)['message']?['content']
              as String?;
      if (content == null || content.trim().isEmpty) return const [];

      final parsed = jsonDecode(content.trim()) as Map<String, dynamic>;
      final list = parsed['insights'] as List<dynamic>? ?? const [];

      final result = <WardrobeInsight>[];
      for (var i = 0; i < list.length && i < 2; i++) {
        final map = list[i];
        if (map is! Map<String, dynamic>) continue;
        final title = (map['title'] as String? ?? '').trim();
        final body = (map['body'] as String? ?? '').trim();
        if (title.isEmpty || body.isEmpty) continue;
        result.add(
          WardrobeInsight(
            id: 'ai_$i',
            title: title,
            body: body,
            kind: WardrobeInsightKind.tip,
            isAiEnhanced: true,
          ),
        );
      }
      return result;
    } catch (e) {
      AppLogger.warning('WardrobeInsightsAi: parse failed ($e)');
      return const [];
    }
  }
}
