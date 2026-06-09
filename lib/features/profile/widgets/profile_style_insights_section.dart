import 'package:flutter/material.dart';

import '../../../core/models/wardrobe_insight.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/services/style_insights_loader.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/chicks_error_state.dart';
import '../../../core/widgets/chicks_skeleton.dart';
import '../../wardrobe/widgets/wardrobe_insight_card.dart';
import '../widgets/profile_card_decoration.dart';

/// Profile section — local style analytics (no OpenAI).
class ProfileStyleInsightsSection extends StatefulWidget {
  const ProfileStyleInsightsSection({super.key});

  @override
  State<ProfileStyleInsightsSection> createState() =>
      ProfileStyleInsightsSectionState();
}

class ProfileStyleInsightsSectionState
    extends State<ProfileStyleInsightsSection> {
  List<WardrobeInsight> _insights = const [];
  bool _isLoading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      final locale = Localizations.localeOf(context);
      final insights = await StyleInsightsLoader.load(locale: locale);
      if (!mounted) return;
      setState(() {
        _insights = insights;
        _isLoading = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppBrandColors.pink.withValues(alpha: 0.22),
                      AppBrandColors.pink.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppBrandColors.pink,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.profileStyleInsightsTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppBrandColors.title,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loc.profileStyleInsightsSub,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8A7A82),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_isLoading)
          const _InsightsLoadingPlaceholder()
        else if (_loadFailed)
          ChicksErrorState(
            message: loc.profileStyleInsightsLoadError,
            onRetry: reload,
            compact: true,
          )
        else if (_insights.isEmpty)
          _InsightsEmptyCard(message: loc.profileStyleInsightsEmpty)
        else
          ..._insights.map(
            (insight) => StyleInsightCard(insight: insight),
          ),
      ],
    );
  }
}

class StyleInsightCard extends StatelessWidget {
  const StyleInsightCard({super.key, required this.insight});

  final WardrobeInsight insight;

  @override
  Widget build(BuildContext context) {
    return WardrobeInsightCard(
      insight: insight,
      showCategoryLabel: true,
    );
  }
}

class _InsightsLoadingPlaceholder extends StatelessWidget {
  const _InsightsLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: DecoratedBox(
            decoration: ProfileCardDecoration.actionTile,
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.cardPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChicksSkeleton(width: 42, height: 42, borderRadius: 12),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ChicksSkeleton(
                          width: double.infinity,
                          height: 14,
                          borderRadius: 6,
                        ),
                        SizedBox(height: 10),
                        ChicksSkeleton(
                          width: double.infinity,
                          height: 11,
                          borderRadius: 6,
                        ),
                        SizedBox(height: 6),
                        ChicksSkeleton(width: 180, height: 11, borderRadius: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InsightsEmptyCard extends StatelessWidget {
  const _InsightsEmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: ProfileCardDecoration.actionTile,
      child: Text(
        message,
        style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.45),
      ),
    );
  }
}
