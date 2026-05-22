import '../models/openai_usage.dart';

/// Estimated USD cost from token counts (dev/debug; verify on OpenAI dashboard).
abstract final class OpenAiCostEstimator {
  /// gpt-4o-mini — USD per 1M tokens (update when OpenAI changes pricing).
  static const double gpt4oMiniInputPerMillion = 0.15;
  static const double gpt4oMiniOutputPerMillion = 0.60;

  static double? estimateUsd({
    required String model,
    required OpenAiUsage usage,
  }) {
    final rates = _ratesFor(model);
    if (rates == null) return null;

    final inputCost =
        usage.promptTokens * rates.inputPerMillion / 1000000;
    final outputCost =
        usage.completionTokens * rates.outputPerMillion / 1000000;

    return inputCost + outputCost;
  }

  static String formatUsd(double? usd) {
    if (usd == null) return 'n/a';
    if (usd < 0.0001) return usd.toStringAsExponential(2);
    return usd.toStringAsFixed(6);
  }

  static _ModelRates? _ratesFor(String model) {
    final normalized = model.trim().toLowerCase();
    if (normalized.contains('gpt-4o-mini') || normalized == 'gpt-4o-mini') {
      return const _ModelRates(
        inputPerMillion: gpt4oMiniInputPerMillion,
        outputPerMillion: gpt4oMiniOutputPerMillion,
      );
    }
    return null;
  }
}

class _ModelRates {
  const _ModelRates({
    required this.inputPerMillion,
    required this.outputPerMillion,
  });

  final double inputPerMillion;
  final double outputPerMillion;
}
