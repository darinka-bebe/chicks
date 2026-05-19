import 'body_profile.dart';
import 'seasonal_color_type.dart';

/// Color + body personalization loaded once per stylist request.
class UserStyleProfile {
  const UserStyleProfile({
    this.colorType,
    this.bodyProfile,
  });

  final SeasonalColorType? colorType;
  final BodyProfile? bodyProfile;

  bool get hasPersonalization => colorType != null || bodyProfile != null;
}
