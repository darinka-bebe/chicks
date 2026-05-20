import 'package:flutter/material.dart';

import 'bootstrap/app_startup_gate.dart';
import 'core/platform/app_platform_bootstrap.dart';

/// Entry point — Firebase/Hive/auth bootstrap runs inside [AppStartupGate]
/// after [runApp], when Android has registered plugin channels.
Future<void> main() async {
  await AppPlatformBootstrap.configure();
  runApp(const AppStartupGate());
}
