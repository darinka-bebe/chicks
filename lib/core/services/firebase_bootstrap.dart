import 'package:cloud_firestore/cloud_firestore.dart';
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
      await FirestoreBootstrap.ensureReady();
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

/// Warms up the Firestore native channel after [FirebaseBootstrap].
abstract final class FirestoreBootstrap {
  static bool _ready = false;

  static bool get isReady => _ready;

  static Future<void> ensureReady() async {
    if (_ready) return;
    await FirebaseBootstrap.ensureInitialized();

    Object? lastError;
    for (var attempt = 1; attempt <= 4; attempt++) {
      try {
        final firestore = FirebaseFirestore.instance;
        firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        _ready = true;
        AppLogger.info('FirestoreBootstrap: native channel ready');
        return;
      } catch (e) {
        lastError = e;
        AppLogger.warning(
          'FirestoreBootstrap: channel not ready (attempt $attempt/4): $e',
        );
        await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
      }
    }

    AppLogger.error(
      'FirestoreBootstrap: failed to connect native Firestore channel. '
      'Run flutter clean → flutter pub get → full rebuild (not hot restart).',
      error: lastError,
    );
    throw lastError ?? StateError('Firestore channel unavailable');
  }

  static bool isChannelError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('unable to establish connection on channel') ||
        text.contains('firebasefirestorehostapi') ||
        text.contains('channel-error');
  }

  static bool isPermissionDenied(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('permission-denied') ||
        text.contains('permission_denied');
  }
}
