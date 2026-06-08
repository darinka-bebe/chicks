import 'package:flutter/foundation.dart';

import '../../core/localization/app_locale.dart';
import '../../core/services/favorite_outfit_factory.dart';
import '../../core/services/outfit_content_hasher.dart';
import '../../data/models/favorite_outfit.dart';
import '../../data/repositories/favorites_repository.dart';

/// Global favorites state shared by chat and favorites screen.
class FavoritesController extends ChangeNotifier {
  FavoritesController({FavoritesRepository? repository})
      : _repository = repository ?? FavoritesRepository.instance;

  final FavoritesRepository _repository;

  List<FavoriteOutfit> _outfits = [];
  Set<String> _savedHashes = {};
  bool _isLoaded = false;
  bool _isLoading = false;
  String? _loadError;

  List<FavoriteOutfit> get outfits => List.unmodifiable(_outfits);
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  String? get loadError => _loadError;

  bool isSavedRecommendation(String recommendation) {
    return _savedHashes.contains(OutfitContentHasher.hash(recommendation));
  }

  Future<void> ensureLoaded() async {
    if (_isLoaded) return;
    await refresh();
  }

  Future<void> refresh() async {
    if (_isLoading) return;
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      _outfits = await _repository.loadOutfits();
      _savedHashes = _outfits.map((item) => item.contentHash).toSet();
      _isLoaded = true;
    } catch (_) {
      _loadError = AppLocale.pick(
        ru: 'Не удалось загрузить избранное',
        en: 'Could not load favorites',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles favorite by recommendation content. Returns `true` if now saved.
  Future<bool> toggleRecommendation({
    required String recommendation,
    String? userPrompt,
    List<String> recommendedItemIds = const [],
  }) async {
    final hash = OutfitContentHasher.hash(recommendation);

    if (_savedHashes.contains(hash)) {
      await _repository.deleteByContentHash(hash);
      await refresh();
      return false;
    }

    final outfit = FavoriteOutfitFactory.fromAiRecommendation(
      recommendation: recommendation,
      userPrompt: userPrompt,
      recommendedItemIds: recommendedItemIds,
    );
    final added = await _repository.addOutfitIfNew(outfit);
    await refresh();
    return added != null || _savedHashes.contains(hash);
  }

  Future<bool> removeByContentHash(String contentHash) async {
    if (!_savedHashes.contains(contentHash)) return false;
    await _repository.deleteByContentHash(contentHash);
    await refresh();
    return true;
  }
}

