import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../utils/logger.dart';

/// Initializes Firebase after the Flutter engine + plugins are ready.
abstract final class FirebaseBootstrap {
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    if (Firebase.apps.isNotEmpty) {
      _initialized = true;
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      AppLogger.info(
        'FirebaseBootstrap: initialized (${defaultTargetPlatform.name})',
      );
    } on FirebaseException catch (e, stack) {
      AppLogger.error(
        'FirebaseBootstrap: FirebaseException ${e.code}',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    } catch (e, stack) {
      AppLogger.error(
        'FirebaseBootstrap: init failed',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
