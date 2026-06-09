import 'package:flutter/widgets.dart';

/// Device locale helpers (en / ru / kk) for UI and AI prompts.
abstract final class AppLocale {
  static const fallback = Locale('en');
  static const kazakh = Locale('kk');

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
    if (locale != null) return resolve(locale);
    return resolve(null);
  }

  static String languageCode([Locale? locale]) {
    return effectiveLocale(locale).languageCode.toLowerCase();
  }

  static bool isRussian([Locale? locale]) {
    return languageCode(locale).startsWith('ru');
  }

  static bool isKazakh([Locale? locale]) {
    return languageCode(locale).startsWith('kk');
  }

  /// Maps device / app language to a supported locale (en, ru, or kk).
  ///
  /// Walks [MaterialApp] locale, then the system preferred-locale list, so
  /// Kazakh is picked even when iOS reports `en` as [deviceLocale].
  static Locale resolve(Locale? locale) {
    final seen = <String>{};
    final candidates = <Locale>[
      if (locale != null) locale,
      if (_resolvedAppLocale != null) _resolvedAppLocale!,
      ...WidgetsBinding.instance.platformDispatcher.locales,
      deviceLocale(),
    ];

    for (final candidate in candidates) {
      final code = candidate.languageCode.toLowerCase();
      if (!seen.add(code)) continue;
      if (code.startsWith('ru')) return const Locale('ru');
      if (code.startsWith('kk')) return kazakh;
    }

    return fallback;
  }

  static String stylistLanguageRule([Locale? locale]) {
    if (isRussian(locale)) return 'Always respond in Russian.';
    if (isKazakh(locale)) return 'Always respond in Kazakh.';
    return 'Always respond in English.';
  }

  static String messageLanguageLabel([Locale? locale]) {
    if (isRussian(locale)) return 'Russian';
    if (isKazakh(locale)) return 'Kazakh';
    return 'English';
  }

  /// Picks copy by device locale. [kk] falls back to [en] when omitted.
  static String pick({
    required String ru,
    required String en,
    String? kk,
    Locale? locale,
  }) {
    final code = resolve(locale).languageCode.toLowerCase();
    if (code.startsWith('kk')) return kk ?? en;
    if (code.startsWith('ru')) return ru;
    return en;
  }
}
