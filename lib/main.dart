import 'package:flutter/material.dart';

import 'core/bootstrap/app_bootstrap.dart';
import 'features/app/ui/app.dart';

Future<void> main() async {
  await AppBootstrap.initialize();
  runApp(const App());
}
