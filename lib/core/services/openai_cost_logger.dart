import '../models/openai_usage.dart';
import '../utils/logger.dart';
import 'openai_cost_estimator.dart';
import 'openai_usage_parser.dart';

/// Logs OpenAI token usage and estimated request cost.
abstract final class OpenAiCostLogger {
  /// [feature] e.g. stylist_chat, wardrobe_vision, wardrobe_insights.
  static void logFromResponse({
    required String feature,
    required String model,
    required String responseBody,
    int? requestBodyBytes,
    int? statusCode,
  }) {
    final usage = OpenAiUsageParser.fromResponseBody(responseBody);
    if (usage == null || !usage.hasTokens) {
      AppLogger.warning(
        'OpenAI[$feature]: usage missing in API response '
        '(status=${statusCode ?? "?"})',
      );
      return;
    }

    _log(feature: feature, model: model, usage: usage, requestBodyBytes: requestBodyBytes);
  }

  static void _log({
    required String feature,
    required String model,
    required OpenAiUsage usage,
    int? requestBodyBytes,
  }) {
    final costUsd = OpenAiCostEstimator.estimateUsd(model: model, usage: usage);
    final costLabel = OpenAiCostEstimator.formatUsd(costUsd);

    final reqPart =
        requestBodyBytes != null ? ' reqBytes=$requestBodyBytes' : '';

    AppLogger.info(
      'OpenAI[$feature] model=$model '
      'prompt=${usage.promptTokens} '
      'completion=${usage.completionTokens} '
      'total=${usage.totalTokens} '
      'cost≈\$$costLabel USD$reqPart',
    );
  }
}
