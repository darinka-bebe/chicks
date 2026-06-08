import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../utils/logger.dart';
import '../utils/openai_key_diagnostics.dart';

/// Loads [.env] from Flutter assets without crashing the app when missing.
abstract final class EnvBootstrap {
  static bool _loaded = false;

  static bool get isLoaded => _loaded;

  static Future<void> load() async {
    if (_loaded) return;

    try {
      await dotenv.load(fileName: '.env');
      _loaded = true;
      final key = OpenAiKeyDiagnostics.normalize(dotenv.env['OPENAI_API_KEY']);
      AppLogger.info(
        'EnvBootstrap: OPENAI_API_KEY ${OpenAiKeyDiagnostics.describe(key)}',
      );
    } catch (e, stack) {
      AppLogger.error(
        'EnvBootstrap: .env not loaded (app continues; AI needs a key)',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
