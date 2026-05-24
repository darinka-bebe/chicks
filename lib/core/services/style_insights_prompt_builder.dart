import '../models/wardrobe_insight.dart';

/// Compact style insights block for the AI stylist system prompt (local, no API).
abstract final class StyleInsightsPromptBuilder {
  static String? buildSystemSection(List<WardrobeInsight> insights) {
    if (insights.isEmpty) return null;

    final lines = insights
        .take(6)
        .map((i) => '• ${i.title}: ${i.body}')
        .join('\n');

    return '''
Personal style insights (from local wardrobe analysis — treat as soft preferences):
$lines
Use these to personalize tone and suggestions; still prioritize the live wardrobe list.
'''
        .trim();
  }
}
