import 'package:flutter/foundation.dart';

import '../../core/services/outfit_content_hasher.dart';
import '../../core/services/outfit_dislike_factory.dart';
import '../../data/models/outfit_dislike_entry.dart';
import '../../data/models/wardrobe_item.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/outfit_dislike_repository.dart';

/// Dislike feedback + derived taste profile for recommendations.
class OutfitPreferencesController extends ChangeNotifier {
  OutfitPreferencesController({
    OutfitDislikeRepository? dislikeRepository,
    FavoritesRepository? favoritesRepository,
  })  : _dislikeRepository = dislikeRepository ?? OutfitDislikeRepository.instance,
        _favoritesRepository = favoritesRepository ?? FavoritesRepository.instance;

  final OutfitDislikeRepository _dislikeRepository;
  final FavoritesRepository _favoritesRepository;

  List<OutfitDislikeEntry> _dislikes = [];
  final Set<String> _dislikedHashes = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  bool isDislikedRecommendation(String recommendation) {
    final hash = OutfitContentHasher.hash(recommendation);
    return _dislikedHashes.contains(hash);
  }

  Future<void> ensureLoaded() async {
    if (_isLoaded) return;
    _dislikes = await _dislikeRepository.loadEntries();
    _dislikedHashes
      ..clear()
      ..addAll(_dislikes.map((entry) => entry.contentHash));
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> refresh() async {
    _dislikes = await _dislikeRepository.loadEntries();
    _dislikedHashes
      ..clear()
      ..addAll(_dislikes.map((entry) => entry.contentHash));
    _isLoaded = true;
    notifyListeners();
  }

  /// Records dislike. Returns `true` when newly saved.
  Future<bool> recordDislike({
    required String recommendation,
    required List<String> recommendedItemIds,
    required List<WardrobeItem> wardrobe,
    String? userPrompt,
  }) async {
    await ensureLoaded();

    final entry = OutfitDislikeFactory.create(
      recommendationText: recommendation,
      wardrobeItems: wardrobe,
      recommendedItemIds: recommendedItemIds,
      userPrompt: userPrompt,
    );

    final added = await _dislikeRepository.addIfNew(entry);
    if (!added) return false;

    await _favoritesRepository.deleteByContentHash(entry.contentHash);

    _dislikes = await _dislikeRepository.loadEntries();
    _dislikedHashes.add(entry.contentHash);
    notifyListeners();
    return true;
  }

  /// Removes dislike for this recommendation if present.
  Future<bool> removeDislike(String recommendation) async {
    await ensureLoaded();
    final hash = OutfitContentHasher.hash(recommendation);
    final removed = await _dislikeRepository.removeByContentHash(hash);
    if (!removed) return false;

    _dislikes = await _dislikeRepository.loadEntries();
    _dislikedHashes.remove(hash);
    notifyListeners();
    return true;
  }

  /// Toggle dislike state. Returns `true` if now disliked.
  Future<bool> toggleDislike({
    required String recommendation,
    required List<String> recommendedItemIds,
    required List<WardrobeItem> wardrobe,
    String? userPrompt,
  }) async {
    if (isDislikedRecommendation(recommendation)) {
      await removeDislike(recommendation);
      return false;
    }
    return recordDislike(
      recommendation: recommendation,
      recommendedItemIds: recommendedItemIds,
      wardrobe: wardrobe,
      userPrompt: userPrompt,
    );
  }
}
