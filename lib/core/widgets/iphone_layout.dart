import 'package:flutter/material.dart';

/// Lightweight layout helpers for iPhone notch, home indicator, and keyboard.
abstract final class IphoneLayout {
  /// Height reserved above home indicator when inside [HomeShell] tab routes.
  static const shellBottomNavHeight = 72.0;

  static EdgeInsets scrollPadding(
    BuildContext context, {
    double horizontal = 20,
    double top = 4,
    double baseBottom = 24,
    double extraBottom = 0,
  }) {
    final safe = MediaQuery.paddingOf(context);
    return EdgeInsets.fromLTRB(
      horizontal,
      top,
      horizontal,
      baseBottom + safe.bottom + extraBottom,
    );
  }

  /// List padding inside bottom-tab shell (main + profile tabs).
  static EdgeInsets shellTabScrollPadding(BuildContext context) {
    return scrollPadding(
      context,
      extraBottom: shellBottomNavHeight,
    );
  }

  /// Chat / input bars: keep the field above home indicator / keyboard.
  static EdgeInsets inputBarPadding(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottom = keyboard > 0 ? 10.0 : 12.0 + safeBottom;
    return EdgeInsets.fromLTRB(16, 0, 16, bottom);
  }
}
