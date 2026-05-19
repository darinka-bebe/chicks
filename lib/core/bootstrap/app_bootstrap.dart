import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../firebase_options.dart';
import '../platform/platform_info.dart';

/// Инициализация приложения до [runApp].
///
/// Вынесено из [main], чтобы точка входа оставалась минимальной
/// и соответствовала чистой архитектуре.
class AppBootstrap {
  const AppBootstrap._();

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    await _loadEnv();
    await _initFirebase();
    _configureSystemChrome();
  }

  static Future<void> _loadEnv() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          'AppBootstrap: .env не найден ($error). '
          'Скопируйте .env.example в .env для Google Sign-In.',
        );
      }
    }
  }

  static Future<void> _initFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  static void _configureSystemChrome() {
    if (!PlatformInfo.isIOS) return;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }
}
