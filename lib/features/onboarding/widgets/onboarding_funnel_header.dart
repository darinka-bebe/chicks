import 'package:flutter/material.dart';

import '../data/onboarding_funnel.dart';
import '../../../core/theme/app_brand_colors.dart';

/// Funnel-wide progress label above quiz / welcome screens.
class OnboardingFunnelHeader extends StatelessWidget {
  const OnboardingFunnelHeader({
    super.key,
    required this.step,
    this.title,
    this.subProgress,
    this.subLabel,
  });

  final int step;
  final String? title;
  final double? subProgress;
  final String? subLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            OnboardingFunnel.stepLabel(step),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppBrandColors.pink.withValues(alpha: 0.9),
              letterSpacing: 0.2,
            ),
          ),
          if (title != null && title!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              title!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (subProgress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: subProgress!.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: AppBrandColors.pink.withValues(alpha: 0.12),
                color: AppBrandColors.pink,
              ),
            ),
          ],
          if (subLabel != null && subLabel!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subLabel!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
