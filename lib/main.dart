import 'package:flutter/material.dart';

import 'bootstrap/app_startup_gate.dart';
import 'core/bootstrap/env_bootstrap.dart';
import 'core/platform/app_platform_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPlatformBootstrap.configure();
  await EnvBootstrap.load();
  runApp(const AppStartupGate());
}