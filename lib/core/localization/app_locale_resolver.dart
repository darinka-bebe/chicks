import 'package:flutter/material.dart';

import 'app_locale.dart';

/// Picks [Locale] from phone settings → supported app language (en / ru / kk).
/// No per-account override — always follows the device language.
abstract final class AppLocaleResolver {
  static Locale? resolve(
    Locale? locale,
    Iterable<Locale> supportedLocales,
  ) {
    final resolved = AppLocale.resolve(locale);
    for (final supported in supportedLocales) {
      if (supported.languageCode == resolved.languageCode) {
        return resolved;
      }
    }
    return AppLocale.fallback;
  }
}
