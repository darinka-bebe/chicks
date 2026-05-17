import '../../../data/repositories/chat_history_repository.dart';
import '../../../data/repositories/favorites_repository.dart';
import '../../../data/repositories/wardrobe_repository.dart';

/// Local profile statistics for the profile screen.
class ProfileStats {
  const ProfileStats({
    required this.wardrobeCount,
    required this.favoritesCount,
    required this.stylistRequestsCount,
  });

  final int wardrobeCount;
  final int favoritesCount;
  final int stylistRequestsCount;

  static const empty = ProfileStats(
    wardrobeCount: 0,
    favoritesCount: 0,
    stylistRequestsCount: 0,
  );
}

abstract final class ProfileStatsLoader {
  /// Loads counts in parallel. Pass [favoritesCount] when already in memory.
  static Future<ProfileStats> load({int? favoritesCount}) async {
    final wardrobeFuture = WardrobeRepository.instance.countItems();
    final favoritesFuture = favoritesCount != null
        ? Future<int>.value(favoritesCount)
        : FavoritesRepository.instance.countOutfits();
    final chatFuture = ChatHistoryRepository.instance.countUserMessages();

    final counts = await Future.wait<int>([
      wardrobeFuture,
      favoritesFuture,
      chatFuture,
    ]);

    return ProfileStats(
      wardrobeCount: counts[0],
      favoritesCount: counts[1],
      stylistRequestsCount: counts[2],
    );
  }
}
