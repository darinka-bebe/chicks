import 'dart:convert';

import '../models/openai_usage.dart';

/// Reads `usage` from OpenAI Chat Completions JSON responses.
abstract final class OpenAiUsageParser {
  static OpenAiUsage? fromResponseBody(String responseBody) {
    if (responseBody.trim().isEmpty) return null;

    try {
      final root = jsonDecode(responseBody);
      if (root is! Map<String, dynamic>) return null;
      return fromUsageMap(root['usage']);
    } catch (_) {
      return null;
    }
  }

  static OpenAiUsage? fromUsageMap(dynamic usage) {
    if (usage is! Map<String, dynamic>) return null;

    final prompt = _int(usage['prompt_tokens']);
    final completion = _int(usage['completion_tokens']);
    final total = _int(usage['total_tokens']);

    if (prompt == 0 && completion == 0 && total == 0) {
      return null;
    }

    return OpenAiUsage(
      promptTokens: prompt,
      completionTokens: completion,
      totalTokens: total > 0 ? total : prompt + completion,
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
