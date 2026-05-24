import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import 'profile_card_decoration.dart';

/// Section header with consistent spacing for profile screen.
class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.topSpacing = AppSpacing.lg,
    this.bottomSpacing = 0,
  });

  final String? title;
  final String? subtitle;
  final Widget child;
  final double topSpacing;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: topSpacing),
        if (title != null) ...[
          Text(
            title!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D1A24),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
        child,
        if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
      ],
    );
  }
}

/// Groups color type + body type cards in one visual block.
class ProfileStyleProfileGroup extends StatelessWidget {
  const ProfileStyleProfileGroup({
    super.key,
    required this.colorCard,
    required this.bodyCard,
  });

  final Widget colorCard;
  final Widget bodyCard;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ProfileCardDecoration.grouped,
      child: Column(
        children: [
          colorCard,
          Divider(
            height: 1,
            thickness: 1,
            indent: AppSpacing.cardPadding,
            endIndent: AppSpacing.cardPadding,
            color: ProfileCardDecoration.tileBorder,
          ),
          bodyCard,
        ],
      ),
    );
  }
}

/// Removes outer decoration from nested profile cards inside a group.
class ProfileGroupedCard extends StatelessWidget {
  const ProfileGroupedCard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: child,
    );
  }
}
