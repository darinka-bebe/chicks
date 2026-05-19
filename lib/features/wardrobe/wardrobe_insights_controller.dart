import 'package:flutter/foundation.dart';

import '../../core/models/wardrobe_analysis_snapshot.dart';
import '../../core/models/wardrobe_insight.dart';
import '../../core/services/wardrobe_analyzer.dart';
import '../../core/services/wardrobe_insights_ai_service.dart';
import '../../core/services/wardrobe_sync_service.dart';
import '../../core/utils/logger.dart';
import '../../data/models/wardrobe_item.dart';

/// Loads wardrobe, runs local analysis, optionally enriches with compact AI tips.
class WardrobeInsightsController extends ChangeNotifier {
  WardrobeAnalysisSnapshot? snapshot;
  List<WardrobeInsight> insights = const [];
  bool isLoading = false;
  String? error;
  bool usedAi = false;

  Future<void> analyze({List<WardrobeItem>? wardrobe}) async {
    isLoading = true;
    error = null;
    usedAi = false;
    notifyListeners();

    try {
      final items =
          wardrobe ?? await WardrobeSyncService.loadFreshWardrobeForAi();
      final stats = WardrobeAnalyzer.analyze(items);
      var cards = WardrobeAnalyzer.buildInsights(stats);

      final aiCards = await WardrobeInsightsAiService.fetchExtraInsights(stats);
      if (aiCards.isNotEmpty) {
        usedAi = true;
        cards = [...cards, ...aiCards].take(9).toList();
      }

      snapshot = stats;
      insights = cards;
      AppLogger.info(
        'WardrobeInsights: analyzed ${stats.totalItems} items, '
        '${cards.length} insight(s), ai=$usedAi',
      );
    } catch (e, stack) {
      error = 'Не удалось проанализировать гардероб';
      AppLogger.error(
        'WardrobeInsights: analyze failed',
        error: e,
        stackTrace: stack,
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
