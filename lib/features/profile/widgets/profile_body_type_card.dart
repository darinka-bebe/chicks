import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/body_profile.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../onboarding/widgets/body_type_illustration.dart';
import 'profile_card_decoration.dart';

class ProfileBodyTypeCard extends StatelessWidget {
  const ProfileBodyTypeCard({
    super.key,
    required this.bodyProfile,
    required this.onUpdated,
  });

  final BodyProfile? bodyProfile;
  final VoidCallback onUpdated;

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
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: ProfileCardDecoration.actionTile,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: profile != null
                    ? BodyTypeIllustration.forBodyShape(
                        profile.shape,
                        width: 48,
                        height: 56,
                      )
                    : Container(
                        width: 48,
                        height: 56,
                        color: AppBrandColors.iconBackground,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.accessibility_new_rounded,
                          color: AppBrandColors.pink,
                          size: 28,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Тип фигуры',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppBrandColors.pink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.shape.displayNameRu ?? 'Не определён',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppBrandColors.title,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile != null
                          ? profile.shape.shortDescriptionRu
                          : 'Пройди короткий тест — образы станут точнее по силуэту',
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
