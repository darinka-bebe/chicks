import 'package:flutter/material.dart';

import 'app_locale.dart';

/// ru / en / kk copy helper for inline engine strings.
abstract final class LocaleTri {
  static String pick({
    required String ru,
    required String en,
    required String kk,
    Locale? locale,
  }) =>
      AppLocale.pick(ru: ru, en: en, kk: kk, locale: locale);
}
