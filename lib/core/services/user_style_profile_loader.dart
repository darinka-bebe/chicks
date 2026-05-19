import '../models/body_profile.dart';
import '../models/seasonal_color_type.dart';
import '../models/user_style_profile.dart';
import '../../data/repositories/user_profile_repository.dart';

/// Loads color type + body profile for scoring and prompts.
abstract final class UserStyleProfileLoader {
  static Future<UserStyleProfile> load() async {
    final repo = UserProfileRepository.instance;
    final colorType = await repo.getColorType();
    final bodyProfile = await repo.getBodyProfile();
    return UserStyleProfile(
      colorType: colorType,
      bodyProfile: bodyProfile,
    );
  }
}
