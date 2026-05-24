import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/body_profile.dart';
import '../../../core/models/body_shape_type.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../onboarding/widgets/quiz_visual_registry.dart';
import '../../onboarding/widgets/quiz_visual_theme.dart';
import 'profile_card_decoration.dart';

/// Profile preview for body shape — vector silhouette, same art as onboarding quiz.
class ProfileBodyTypeCard extends StatelessWidget {
  const ProfileBodyTypeCard({
    super.key,
    required this.bodyProfile,
    required this.onUpdated,
    this.grouped = false,
  });

  final BodyProfile? bodyProfile;
  final VoidCallback onUpdated;
  final bool grouped;

  Future<void> _openQuiz(BuildContext context) async {
    final updated = await context.pushNamed<bool>(
      RouteNames.bodyTypeQuizName,
      queryParameters: const {'from': 'profile'},
    );
    if (updated == true) onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    final profile = bodyProfile;

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BodyTypeProfilePreview(
                shape: profile?.shape,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Тип фигуры',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppBrandColors.pink,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile?.shape.displayNameRu ?? 'Не определён',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppBrandColors.title,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile != null
                          ? profile.shape.shortDescriptionRu
                          : 'Пройди короткий тест — образы станут точнее по силуэту',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 26,
                  color: AppBrandColors.pink.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodyTypeProfilePreview extends StatelessWidget {
  const _BodyTypeProfilePreview({required this.shape});

  final BodyShapeType? shape;

  @override
  Widget build(BuildContext context) {
    const previewSize = QuizVisualTheme.optionPreviewSize;

    return SizedBox(
      width: previewSize,
      height: previewSize,
      child: shape != null
          ? QuizVisualRegistry.forBodyResult(shape!, size: previewSize)
          : Center(
              child: Icon(
                Icons.accessibility_new_rounded,
                color: AppBrandColors.pink.withValues(alpha: 0.55),
                size: 34,
              ),
            ),
    );
  }
}
