import 'package:flutter/foundation.dart';

/// Платформенные флаги без [dart:io] (совместимо с web).
abstract final class PlatformInfo {
  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isAndroid =>
      defaultTargetPlatform == TargetPlatform.android;

  static bool get isCupertino =>
      isIOS || defaultTargetPlatform == TargetPlatform.macOS;
}
