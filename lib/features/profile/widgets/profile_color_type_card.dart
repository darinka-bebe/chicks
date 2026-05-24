import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/seasonal_color_type.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../onboarding/widgets/quiz_visual_registry.dart';
import '../../onboarding/widgets/quiz_visual_theme.dart';
import '../widgets/profile_card_decoration.dart';

/// Shows the user's seasonal color type with option to retake the quiz.
class ProfileColorTypeCard extends StatelessWidget {
  const ProfileColorTypeCard({
    super.key,
    required this.colorType,
    required this.onUpdated,
    this.grouped = false,
  });

  final SeasonalColorType? colorType;
  final VoidCallback onUpdated;
  final bool grouped;

  Future<void> _openQuiz(BuildContext context) async {
    final updated = await context.pushNamed<bool>(
      RouteNames.colorTypeQuizName,
      queryParameters: const {'from': 'profile'},
    );
    if (updated == true) onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    final type = colorType;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openQuiz(context),
        borderRadius: BorderRadius.circular(
          grouped ? 0 : ProfileCardDecoration.radius,
        ),
        child: Ink(
          decoration: grouped ? null : ProfileCardDecoration.actionTile,
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Row(
            children: [
              type != null
                  ? QuizVisualRegistry.forColorResult(
                      type,
                      size: QuizVisualTheme.optionPreviewSize,
                    )
                  : SizedBox(
                      width: QuizVisualTheme.optionPreviewSize,
                      height: QuizVisualTheme.optionPreviewSize,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppBrandColors.iconBackground,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.palette_outlined,
                          color: AppBrandColors.pink,
                        ),
                      ),
                    ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Цветотип',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppBrandColors.pink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type?.displayNameRu ?? 'Не определён',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppBrandColors.title,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type != null
                          ? type.shortDescriptionRu
                          : 'Пройди короткий тест — стилист точнее подберёт палитру',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppBrandColors.pink.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
