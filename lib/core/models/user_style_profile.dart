import 'body_profile.dart';
import 'favorite_preference_profile.dart';
import 'outfit_preference_profile.dart';
import 'seasonal_color_type.dart';
import 'stylist_defaults.dart';

/// Color + body + taste signals for stylist scoring and prompts.
class UserStyleProfile {
  const UserStyleProfile({
    this.colorType,
    this.bodyProfile,
    this.dislikeProfile = OutfitPreferenceProfile.empty,
    this.favoriteProfile = FavoritePreferenceProfile.empty,
    this.stylistDefaults = StylistDefaults.empty,
  });

  final SeasonalColorType? colorType;
  final BodyProfile? bodyProfile;
  final OutfitPreferenceProfile dislikeProfile;
  final FavoritePreferenceProfile favoriteProfile;
  final StylistDefaults stylistDefaults;

  bool get hasPersonalization =>
      colorType != null ||
      bodyProfile != null ||
      dislikeProfile.hasSignals ||
      favoriteProfile.hasSignals ||
      stylistDefaults.hasSignals;
}
