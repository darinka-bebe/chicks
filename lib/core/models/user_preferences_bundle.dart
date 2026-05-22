import 'body_profile.dart';
import 'outfit_preference_profile.dart';
import 'seasonal_color_type.dart';
import 'stylist_defaults.dart';

/// Full local preference snapshot for profile UI and AI bootstrap.
class UserPreferencesBundle {
  const UserPreferencesBundle({
    this.colorType,
    this.bodyProfile,
    this.stylistDefaults = StylistDefaults.empty,
    this.dislikeProfile = OutfitPreferenceProfile.empty,
    this.username = '',
    this.favoritesCount = 0,
    this.dislikesCount = 0,
    this.onboardingCompleted = false,
    this.colorQuizCompleted = false,
    this.bodyQuizCompleted = false,
  });

  static const empty = UserPreferencesBundle();

  final SeasonalColorType? colorType;
  final BodyProfile? bodyProfile;
  final StylistDefaults stylistDefaults;
  final OutfitPreferenceProfile dislikeProfile;
  final String username;
  final int favoritesCount;
  final int dislikesCount;
  final bool onboardingCompleted;
  final bool colorQuizCompleted;
  final bool bodyQuizCompleted;

  bool get hasStyleQuiz =>
      colorType != null && bodyProfile != null;

  bool get hasTasteSignals =>
      stylistDefaults.hasSignals || dislikeProfile.hasSignals;

  bool get isFullyConfigured =>
      onboardingCompleted && colorQuizCompleted && bodyQuizCompleted;
}
