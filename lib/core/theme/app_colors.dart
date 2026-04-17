import 'package:flutter/material.dart';

/// Палитра цветов в стиле Chicks (как на макетах Фигмы)
class AppColors {
  // ── Основные ───────────────────────────────────────────────────
  /// Главный брендовый розовый (#FF4E9F — яркий, фуксиево‑розовый)
  static const Color primary = Color(0xFFFF4E9F);

  /// Градиентный второй оттенок розового (#FF82C1 — светлее)
  static const Color primaryLight = Color(0xFFFF82C1);

  /// Цвет текста/иконок на primary‑фоне.
  static const Color onPrimary = Colors.white;

  // ── Акценты и дополнительные ──────────────────────────────────
  /// Светлый розовый фон элементов (карточек, кнопок)
  static const Color secondary = Color(0xFFFFB6E0);

  /// Цвет текста/иконок на secondary‑фоне.
  static const Color onSecondary = Color(0xFF4A154B);

  // ── Фоны ───────────────────────────────────────────────────────
  /// Основной фон экранов (мягкий розовый)
  static const Color background = Color(0xFFFFF3F8);

  /// Фон карточек, полей и навигации (чуть светлее)
  static const Color surface = Color(0xFFFFF8FB);

  /// Цвет ошибок (насыщенный розово‑красный)
  static const Color error = Color(0xFFFF4B61);

  // ── Текст ──────────────────────────────────────────────────────
  /// Основной текст (тёмно‑розовый/фиолетовый)
  static const Color textPrimary = Color(0xFF4A154B);

  /// Второстепенный текст (светло‑серо‑розовый)
  static const Color textSecondary = Color(0xFFB08FA5);

  // ── Прочее ─────────────────────────────────────────────────────
  /// Разделители и границы
  static const Color divider = Color(0xFFFFD6E8);

  /// Неактивные иконки в bottom nav bar
  static const Color inactive = Color(0xFFBAA0AE);

  /// Цвет активной иконки в navbar
  static const Color active = primary;

  /// Белый (для удобства)
  static const Color white = Colors.white;
}
