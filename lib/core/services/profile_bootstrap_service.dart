import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/outfit_dislike_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../utils/logger.dart';

/// Restores persisted profile-related data on cold start / after login.
abstract final class ProfileBootstrapService {
  static Future<void> restoreOnStartup() async {
    try {
      await AuthRepository.instance.initialize();
      await AuthRepository.instance.repairStoredSession();
      await restoreUserData();
    } catch (e, stack) {
      AppLogger.error(
        'ProfileBootstrapService.restoreOnStartup failed',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Wardrobe, quizzes, favorites, dislikes — device-local (survives restart).
  static Future<void> restoreUserData() async {
    await UserProfileRepository.instance.getColorType();
    await UserProfileRepository.instance.getBodyProfile();
    await OutfitDislikeRepository.instance.loadProfile();
    await FavoritesRepository.instance.loadOutfits();
    AppLogger.info('ProfileBootstrapService: user data caches warmed');
  }
}
