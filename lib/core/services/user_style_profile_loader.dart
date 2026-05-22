import '../models/user_style_profile.dart';
import '../../data/repositories/user_preferences_repository.dart';

/// Loads full personalization bundle for AI stylist requests.
abstract final class UserStyleProfileLoader {
  static Future<UserStyleProfile> load() async {
    final bundle = await UserPreferencesRepository.instance.loadBundle();
    return UserStyleProfile(
      colorType: bundle.colorType,
      bodyProfile: bundle.bodyProfile,
      dislikeProfile: bundle.dislikeProfile,
      stylistDefaults: bundle.stylistDefaults,
    );
  }
}
