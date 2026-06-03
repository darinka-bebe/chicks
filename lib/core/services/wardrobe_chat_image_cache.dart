import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';

import '../../data/models/wardrobe_item.dart';

/// Reuses decoded thumbnail [ImageProvider]s for chat outfit cards.
abstract final class WardrobeChatImageCache {
  static const int defaultCacheWidth = 200;
  static const int _maxEntries = 64;

  static final Map<String, ImageProvider> _providers = {};

  static ImageProvider provider(
    String source, {
    int cacheWidth = defaultCacheWidth,
  }) {
    final key = '$source|$cacheWidth';
    final existing = _providers[key];
    if (existing != null) return existing;

    if (_providers.length >= _maxEntries) {
      _providers.remove(_providers.keys.first);
    }

    final ImageProvider<Object> base;
    if (WardrobeItem.isHttpUrl(source)) {
      base = CachedNetworkImageProvider(source);
    } else if (WardrobeItem.isAssetPath(source)) {
      base = AssetImage(source);
    } else {
      throw ArgumentError(
        'WardrobeChatImageCache: only cloud URL or asset paths are supported: $source',
      );
    }

    final provider = ResizeImage(
      base,
      width: cacheWidth,
      policy: ResizeImagePolicy.fit,
    );
    _providers[key] = provider;
    return provider;
  }

  static void clear() => _providers.clear();
}
