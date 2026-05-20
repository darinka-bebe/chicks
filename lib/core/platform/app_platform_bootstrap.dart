import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Platform-specific startup configuration (iOS-safe areas, status bar, orientation).
abstract final class AppPlatformBootstrap {
  static const _brandBackground = Color(0xFFFFF0F5);

  static Future<void> configure() async {
    WidgetsFlutterBinding.ensureInitialized();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    if (Platform.isIOS) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    SystemChrome.setSystemUIOverlayStyle(_overlayStyle);
  }

  static SystemUiOverlayStyle get _overlayStyle {
    return const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    );
  }

  /// Wraps the app tree to keep status bar readable on pastel backgrounds.
  static Widget wrapApp(Widget child) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: ColoredBox(
        color: _brandBackground,
        child: child,
      ),
    );
  }
}
