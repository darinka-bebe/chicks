import 'package:flutter/widgets.dart';

/// Device locale helpers (ru / en) for UI and AI prompts.
abstract final class AppLocale {
  static const fallback = Locale('en');

  static Locale? _resolvedAppLocale;

  /// Sync with [MaterialApp] resolved locale (call from app builder).
  static void updateResolvedLocale(Locale? locale) {
    if (locale != null) {
      _resolvedAppLocale = locale;
    }
  }

  static Locale deviceLocale() {
    return WidgetsBinding.instance.platformDispatcher.locale;
  }

  static Locale effectiveLocale([Locale? locale]) {
    if (locale != null) return locale;
    if (_resolvedAppLocale != null) return _resolvedAppLocale!;
    return deviceLocale();
  }

  static String languageCode([Locale? locale]) {
    return effectiveLocale(locale).languageCode.toLowerCase();
  }

  static bool isRussian([Locale? locale]) {
    return languageCode(locale).startsWith('ru');
  }

  /// Maps device language to a supported app locale (en or ru).
  static Locale resolve(Locale? locale) {
    if (locale != null && isRussian(locale)) {
      return const Locale('ru');
    }
    return fallback;
  }

  static String stylistLanguageRule([Locale? locale]) {
    if (isRussian(locale)) {
      return 'Always respond in Russian.';
    }
    return 'Always respond in English.';
  }

  static String messageLanguageLabel([Locale? locale]) {
    return isRussian(locale) ? 'Russian' : 'English';
  }

  /// Picks Russian or English copy based on device locale.
  static String pick({
    required String ru,
    required String en,
    Locale? locale,
  }) {
    return isRussian(locale) ? ru : en;
  }
}
