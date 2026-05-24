import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_preferences_repository.dart';
import '../services/sync_coordinator.dart';
import '../utils/logger.dart';

/// Restores persisted profile-related data on cold start / after login.
abstract final class ProfileBootstrapService {
  static Future<void> restoreOnStartup() async {
    try {
      await AuthRepository.instance.initialize();
      await restoreUserData();
    } catch (e, stack) {
      AppLogger.error(
        'ProfileBootstrapService.restoreOnStartup failed',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// After login/sign-up: repair avatar paths, warm caches, restore cloud data.
  static Future<void> restoreUserData() async {
    try {
      await AuthRepository.instance.repairStoredSession();
      await UserPreferencesRepository.instance.restoreAllCaches();

      if (AuthRepository.instance.isLoggedIn) {
        await SyncCoordinator.instance.restoreAfterLogin(
          uid: AuthRepository.instance.currentUser.uid,
        );
      }
    } catch (e, stack) {
      AppLogger.error(
        'ProfileBootstrapService.restoreUserData failed',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
