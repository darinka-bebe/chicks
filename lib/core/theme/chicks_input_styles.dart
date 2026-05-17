import 'package:flutter/material.dart';

import 'app_brand_colors.dart';

/// Shared TextField / TextFormField styling for the Chicks pink UI.
abstract final class ChicksInputStyles {
  /// Soft placeholder gray — clearly lighter than typed text.
  static const Color hintColor = Color(0xFFB5ADB1);

  static const TextStyle hint = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: hintColor,
    height: 1.3,
  );

  static const TextStyle value = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppBrandColors.title,
    height: 1.35,
  );

  static const TextStyle valueDense = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppBrandColors.title,
    height: 1.3,
  );

  static InputDecoration decoration({
    required String hintText,
    Color fillColor = Colors.white,
    double borderRadius = 16,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide.none,
    );

    return InputDecoration(
      hintText: hintText,
      hintStyle: ChicksInputStyles.hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
      contentPadding: contentPadding,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: AppBrandColors.pink, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
    );
  }

  static InputDecoration chatDecoration({required String hintText}) {
    return decoration(
      hintText: hintText,
      fillColor: AppBrandColors.background,
      borderRadius: 24,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    );
  }

  static InputDecoration profileDecoration({required String hintText}) {
    return decoration(
      hintText: hintText,
      fillColor: AppBrandColors.background,
      borderRadius: 30,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  /// Filled field without placeholder (dropdowns, etc.).
  static InputDecoration filledShell({
    Color fillColor = Colors.white,
    double borderRadius = 16,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide.none,
    );

    return InputDecoration(
      filled: true,
      fillColor: fillColor,
      contentPadding: contentPadding,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: AppBrandColors.pink, width: 1.2),
      ),
    );
  }
}
