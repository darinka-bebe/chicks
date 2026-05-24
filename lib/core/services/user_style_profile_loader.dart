import '../models/user_style_profile.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/user_preferences_repository.dart';
import '../../data/repositories/wardrobe_repository.dart';
import 'favorite_preference_aggregator.dart';

/// Loads full personalization bundle for AI stylist requests.
abstract final class UserStyleProfileLoader {
  static Future<UserStyleProfile> load() async {
    final bundle = await UserPreferencesRepository.instance.loadBundle();
    final favorites = await FavoritesRepository.instance.loadOutfits();
    final wardrobe = await WardrobeRepository.instance.loadItems();
    final favoriteProfile = FavoritePreferenceAggregator.fromOutfits(
      favorites,
      wardrobe: wardrobe,
    );

    return UserStyleProfile(
      colorType: bundle.colorType,
      bodyProfile: bundle.bodyProfile,
      dislikeProfile: bundle.dislikeProfile,
      favoriteProfile: favoriteProfile,
      stylistDefaults: bundle.stylistDefaults,
    );
  }
}
