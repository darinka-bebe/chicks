import '../../data/repositories/chat_history_repository.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/repositories/outfit_dislike_repository.dart';
import '../../data/repositories/outfit_history_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../../data/repositories/wardrobe_repository.dart';
import '../storage/local_hive_storage.dart';
import '../utils/logger.dart';
import 'wardrobe_image_storage.dart';
import 'wardrobe_sync_service.dart';

/// Resets local demo data for QA / presentations (keeps auth session).
abstract final class DemoResetService {
  /// Clears chat, favorites, history, dislikes and re-seeds demo wardrobe.
  static Future<void> resetDemoData() async {
    AppLogger.info('DemoResetService: resetDemoData start');

    final wardrobe = await WardrobeRepository.instance.loadItems();
    for (final item in wardrobe) {
      await WardrobeImageStorage.deleteIfStored(item.imagePath);
    }

    await Future.wait([
      LocalHiveStorage.wardrobeBox.delete(LocalHiveStorage.wardrobeItemsKey),
      ChatHistoryRepository.instance.clear(),
      FavoritesRepository.instance.clear(),
      OutfitHistoryRepository.instance.clear(),
      OutfitDislikeRepository.instance.clear(),
    ]);

    await WardrobeRepository.instance.loadItems();
    await WardrobeSyncService.afterWardrobeMutation(reason: 'demoReset');

    AppLogger.info('DemoResetService: resetDemoData complete');
  }

  /// Also clears onboarding + style quizzes (user will see onboarding again).
  static Future<void> resetAllIncludingQuizzes() async {
    await resetDemoData();
    await OnboardingRepository.instance.setCompleted(completed: false);
    await UserProfileRepository.instance.setColorTypeQuizCompleted(
      completed: false,
    );
    await UserProfileRepository.instance.setBodyTypeQuizCompleted(
      completed: false,
    );
    await UserProfileRepository.instance.clearColorType();
    await UserProfileRepository.instance.clearBodyProfile();
    AppLogger.info('DemoResetService: quizzes cleared');
  }
}
