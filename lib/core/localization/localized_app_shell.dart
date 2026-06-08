import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../l10n/generated/app_localizations.dart';
import 'app_locale_resolver.dart';

/// Minimal [MaterialApp] shell with device locale for pre-main screens.
abstract final class LocalizedAppShell {
  static Widget wrap(Widget home) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: AppLocaleResolver.resolve,
      home: home,
    );
  }
}
