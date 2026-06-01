import 'dart:async';

import 'logger.dart';

/// Timeouts + logging for async operations that must not hang the UI forever.
abstract final class AsyncGuard {
  static const defaultTimeout = Duration(seconds: 20);
  static const syncTimeout = Duration(seconds: 25);
  static const firestoreTimeout = Duration(seconds: 15);

  static Future<T> withTimeout<T>({
    required String label,
    required Future<T> Function() action,
    Duration timeout = defaultTimeout,
    T Function()? onTimeout,
  }) async {
    try {
      return await action().timeout(timeout);
    } on TimeoutException {
      AppLogger.warning('AsyncGuard: timeout after ${timeout.inSeconds}s — $label');
      if (onTimeout != null) return onTimeout();
      rethrow;
    }
  }

  static void runInBackground({
    required String label,
    required Future<void> Function() action,
    Duration timeout = syncTimeout,
  }) {
    unawaited(
      withTimeout(
        label: label,
        timeout: timeout,
        action: action,
      ).catchError((Object e, StackTrace stack) {
        AppLogger.error(
          'AsyncGuard: background task failed — $label',
          error: e,
          stackTrace: stack,
        );
      }),
    );
  }
}
