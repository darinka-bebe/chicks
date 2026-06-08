import 'package:flutter/material.dart';

import '../../../core/models/seasonal_color_type.dart';
import '../../../core/models/user_preferences_bundle.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'profile_card_decoration.dart';

/// Saved style quiz + taste signals from chat (likes/dislikes).
class ProfilePreferencesSummaryCard extends StatelessWidget {
  const ProfilePreferencesSummaryCard({
    super.key,
    required this.bundle,
  });

  final UserPreferencesBundle bundle;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final color = bundle.colorType;
    final body = bundle.bodyProfile;
    final defaults = bundle.stylistDefaults;
    final dislikes = bundle.dislikeProfile;

    return DecoratedBox(
      decoration: ProfileCardDecoration.actionTile,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.profileSavedPreferences,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppBrandColors.pink,
              ),
            ),
            const SizedBox(height: 12),
            if (color != null)
              _Row(
                icon: Icons.palette_outlined,
                label: loc.profilePrefColorType,
                value: color.displayName,
              ),
            if (body != null) ...[
              const SizedBox(height: 8),
              _Row(
                icon: Icons.accessibility_new_outlined,
                label: loc.profilePrefSilhouette,
                value: body.shape.displayName,
              ),
              if (body.fitPreference.isNotEmpty) ...[
                const SizedBox(height: 8),
                _Row(
                  icon: Icons.checkroom_outlined,
                  label: loc.profilePrefFit,
                  value: body.fitPreference,
                ),
              ],
            ],
            if (defaults.topMoods().isNotEmpty) ...[
              const SizedBox(height: 8),
              _Row(
                icon: Icons.auto_awesome_outlined,
                label: loc.profilePrefMood,
                value: defaults.topMoods().join(', '),
              ),
            ],
            if (defaults.topOccasions().isNotEmpty) ...[
              const SizedBox(height: 8),
              _Row(
                icon: Icons.event_outlined,
                label: loc.profilePrefOccasions,
                value: defaults.topOccasions().join(', '),
              ),
            ],
            const SizedBox(height: 10),
            _Row(
              icon: Icons.favorite_rounded,
              label: loc.profilePrefFavorites,
              value: '${bundle.favoritesCount}',
            ),
            const SizedBox(height: 8),
            _Row(
              icon: Icons.thumb_down_off_alt_outlined,
              label: loc.profilePrefDislikes,
              value: '${bundle.dislikesCount}',
            ),
            if (dislikes.hasSignals && dislikes.topStyles().isNotEmpty) ...[
              const SizedBox(height: 8),
              _Row(
                icon: Icons.block_outlined,
                label: loc.profilePrefAvoid,
                value: dislikes.topStyles().join(', '),
              ),
            ],
            if (!bundle.hasStyleQuiz && !bundle.hasTasteSignals) ...[
              Text(
                loc.profilePrefEmpty,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppBrandColors.pink.withValues(alpha: 0.85)),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
