import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Основная светлая тема приложения в стиле Chicks.
class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins', // Подходит по вайбу визуала (можно заменить)
      scaffoldBackgroundColor: AppColors.background,

      // ── Цветовая схема ─────────────────────────────────────────────
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        surface: AppColors.surface,
        error: AppColors.error,
        background: AppColors.background,
      ),

      // ── AppBar ────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: AppTextStyles.headlineMedium,
      ),

      // ── Кнопки ─────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
          textStyle: AppTextStyles.button,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.buttonSecondary,
        ),
      ),

      // ── Поля ввода ────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: AppTextStyles.bodySmall,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
      ),

      // ── Текстовая тема ─────────────────────────────────────────────
      textTheme: const TextTheme(
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodySmall: AppTextStyles.bodySmall,
        labelSmall: AppTextStyles.label,
      ),

      // ── Нижняя навигация ──────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.inactive,
        selectedLabelStyle: AppTextStyles.label,
        unselectedLabelStyle: AppTextStyles.label,
        showUnselectedLabels: true,
        elevation: 8,
      ),

      // ── Карточки ─────────────────────────────────────────────────
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),

      // ── Разделители и прочее ─────────────────────────────────────
      dividerColor: AppColors.divider,
      iconTheme: const IconThemeData(color: AppColors.inactive, size: 24),
    );
  }
}
