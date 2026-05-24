import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Shared lightweight card styling for profile screens.
abstract final class ProfileCardDecoration {
  static const Color headerFill = Color(0xFFFFF8FB);
  static const Color tileBorder = Color(0x14FF4FA0);
  static const double radius = AppSpacing.cardRadius;

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFFFF4FA0).withValues(alpha: 0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  static final BoxDecoration statCard = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: tileBorder),
    boxShadow: softShadow,
  );

  static final BoxDecoration actionTile = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: tileBorder),
    boxShadow: softShadow,
  );

  static final BoxDecoration grouped = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: tileBorder),
    boxShadow: softShadow,
  );

  static final BoxDecoration header = BoxDecoration(
    color: headerFill,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: tileBorder),
    boxShadow: softShadow,
  );
}
