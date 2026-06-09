import 'package:flutter/material.dart';

import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/user_preferences_repository.dart';
import '../../data/repositories/wardrobe_repository.dart';
import '../localization/app_locale.dart';
import '../models/wardrobe_insight.dart';
import 'style_insights_engine.dart';

/// Loads wardrobe + preferences and builds local style insights.
abstract final class StyleInsightsLoader {
  static Future<List<WardrobeInsight>> load({Locale? locale}) async {
    final appLocale = locale ?? AppLocale.resolve(null);
    AppLocale.updateResolvedLocale(appLocale);
    final itemsFuture = WardrobeRepository.instance.loadItems();
    final bundleFuture = UserPreferencesRepository.instance.loadBundle();
    final favoritesFuture = FavoritesRepository.instance.countOutfits();

    final items = await itemsFuture;
    final bundle = await bundleFuture;
    final favoritesCount = await favoritesFuture;

    return StyleInsightsEngine.build(
      items: items,
      preferences: bundle,
      favoritesCount: favoritesCount,
      locale: appLocale,
    );
  }
}
