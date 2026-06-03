import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'bootstrap/app_startup_gate.dart';
import 'core/platform/app_platform_bootstrap.dart';

Future<void> main() async {
  await AppPlatformBootstrap.configure();

  await dotenv.load(fileName: '.env');

  runApp(const AppStartupGate());
}