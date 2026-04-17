import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Типографика приложения в стиле Chicks.
class AppTextStyles {
  // ── Заголовки ──────────────────────────────────────────────────
  /// Крупный заголовок (например, "Добро пожаловать!")
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.3,
  );

  /// Средний заголовок (например, "Твой гардероб", "Твой стиль и вайб")
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// Малый заголовок (например, описания секций или карточек)
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // ── Основной текст ─────────────────────────────────────────────
  /// Обычный текст (для диалогов, описаний и подсказок)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Второстепенный текст (например "ИИ‑помощник ответит на все вопросы о моде")
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  /// Подписи в полях, подсказки и комментарии
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  // ── Кнопки и интерактив ────────────────────────────────────────
  /// Текст на кнопках (яркий, контрастный, капсом или полужирный)
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.onPrimary,
    letterSpacing: 0.5,
  );

  /// Второстепенные кнопки / ссылки
  static const TextStyle buttonSecondary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  /// Лейблы (на табах, бейджах или навигации)
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );
}
