import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/models/wardrobe_analysis_snapshot.dart';
import '../../../core/widgets/chicks_error_state.dart';
import '../../../core/widgets/chicks_skeleton.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../wardrobe_controller.dart';
import '../wardrobe_insights_controller.dart';
import '../widgets/wardrobe_insight_card.dart';
import '../widgets/wardrobe_stats_strip.dart';

/// Wardrobe balance analysis — category stats and stylist insights.
class WardrobeInsightsScreen extends StatefulWidget {
  const WardrobeInsightsScreen({super.key});

  @override
  State<WardrobeInsightsScreen> createState() => _WardrobeInsightsScreenState();
}

class _WardrobeInsightsScreenState extends State<WardrobeInsightsScreen> {
  late final WardrobeInsightsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WardrobeInsightsController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAnalysis());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    final wardrobe = context.read<WardrobeController>();
    await wardrobe.ensureLoaded();
    if (!mounted) return;
    await _controller.analyze(wardrobe: wardrobe.items);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppBrandColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: AppBrandColors.pink,
              onPressed: () => context.pop(),
            ),
            title: Text(
              AppLocale.pick(
                ru: 'Анализ гардероба',
                en: 'Wardrobe analysis',
              ),
              style: const TextStyle(
                color: AppBrandColors.pink,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
          ),
          body: RefreshIndicator(
            color: AppBrandColors.pink,
            onRefresh: _runAnalysis,
            child: _buildBody(),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading && _controller.snapshot == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: List.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ChicksSkeleton(
              width: double.infinity,
              height: 72,
              borderRadius: 16,
            ),
          ),
        ),
      );
    }

    if (_controller.error != null && _controller.snapshot == null) {
      return ChicksRefreshableScroll(
        onRefresh: _runAnalysis,
        child: ChicksErrorState(
          message: _controller.error!,
          onRetry: _runAnalysis,
        ),
      );
    }

    final snapshot = _controller.snapshot;
    if (snapshot == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _SummaryHeader(
            snapshot: snapshot,
            usedAi: _controller.usedAi,
          ),
        ),
        const SizedBox(height: 20),
        if (snapshot.totalItems > 0) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(
              AppLocale.pick(ru: 'По категориям', en: 'By category'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppBrandColors.title,
              ),
            ),
          ),
          WardrobeStatsStrip(snapshot: snapshot),
          const SizedBox(height: 24),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                AppLocale.pick(
                  ru: 'Инсайты гардероба',
                  en: 'Wardrobe insights',
                ),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppBrandColors.title,
                ),
              ),
              if (_controller.isLoading) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppBrandColors.pink,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              for (final insight in _controller.insights)
                WardrobeInsightCard(insight: insight),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.snapshot,
    required this.usedAi,
  });

  final WardrobeAnalysisSnapshot snapshot;
  final bool usedAi;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppBrandColors.pink.withValues(alpha: 0.14),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppBrandColors.pink.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insights_outlined,
                  color: AppBrandColors.pink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  snapshot.totalItems == 0
                      ? AppLocale.pick(
                          ru: 'Добавь вещи для анализа',
                          en: 'Add items to analyze',
                        )
                      : AppLocale.pick(
                          ru: '${snapshot.totalItems} вещей в гардеробе',
                          en: '${snapshot.totalItems} items in wardrobe',
                        ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppBrandColors.title,
                  ),
                ),
              ),
            ],
          ),
          if (snapshot.totalItems > 0) ...[
            const SizedBox(height: 12),
            Text(
              usedAi
                  ? AppLocale.pick(
                      ru:
                          'Локальный разбор + короткие советы стилиста (компактный AI-запрос).',
                      en:
                          'Local analysis plus short stylist tips (compact AI request).',
                    )
                  : AppLocale.pick(
                      ru:
                          'Разбор баланса категорий, цветов и пробелов — без лишних токенов.',
                      en:
                          'Category, color, and gap analysis — without extra tokens.',
                    ),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
