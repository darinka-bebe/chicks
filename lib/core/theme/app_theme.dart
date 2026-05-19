import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../platform/platform_info.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Тема приложения (пока только светлая).
///
/// [ThemeData] собирает в себе цвета, стили текста,
/// настройки AppBar, кнопок и прочих компонентов.
/// Чтобы добавить тёмную тему — создайте аналогичный метод `dark()`.
class AppTheme {
  /// Светлая тема.
  static ThemeData get light {
    final platform =
        PlatformInfo.isIOS ? TargetPlatform.iOS : TargetPlatform.android;

    return ThemeData(
      useMaterial3: true,
      platform: platform,
      cupertinoOverrideTheme: PlatformInfo.isCupertino
          ? const CupertinoThemeData(
              primaryColor: AppColors.primary,
              barBackgroundColor: AppColors.surface,
            )
          : null,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
        },
      ),

      // ── Цветовая схема ───────────────────────────────────────
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),

      scaffoldBackgroundColor: AppColors.background,

      // ── AppBar ───────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      // ── Кнопки ───────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // ── Текстовая тема ───────────────────────────────────────
      textTheme: const TextTheme(
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodySmall: AppTextStyles.bodySmall,
        labelSmall: AppTextStyles.label,
      ),

      // ── Навигация ────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.inactive,
        showUnselectedLabels: true,
      ),

      dividerColor: AppColors.divider,
    );
  }
}
