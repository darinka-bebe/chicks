import 'package:flutter/material.dart';

import 'app_locale.dart';

/// Picks [Locale] from phone settings → supported app language (en / ru).
/// No per-account override — always follows the device language.
abstract final class AppLocaleResolver {
  static Locale? resolve(
    Locale? locale,
    Iterable<Locale> supportedLocales,
  ) {
    return AppLocale.resolve(locale ?? AppLocale.deviceLocale());
  }
}
