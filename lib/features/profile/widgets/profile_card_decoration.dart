import 'package:flutter/material.dart';

/// Shared lightweight card styling (border only — no shadows).
abstract final class ProfileCardDecoration {
  static const Color headerFill = Color(0xFFFFF8FB);
  static const Color tileBorder = Color(0x14FF4FA0);

  static final BoxDecoration statCard = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: tileBorder),
  );

  static final BoxDecoration actionTile = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: tileBorder),
  );

  static final BoxDecoration header = BoxDecoration(
    color: headerFill,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: tileBorder),
  );
}
