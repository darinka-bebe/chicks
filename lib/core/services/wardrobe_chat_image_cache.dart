import 'dart:io';

import 'package:flutter/painting.dart';

import '../widgets/wardrobe_item_image.dart';

/// Reuses decoded thumbnail [ImageProvider]s for chat outfit cards.
abstract final class WardrobeChatImageCache {
  static const int defaultCacheWidth = 200;
  static const int _maxEntries = 64;

  static final Map<String, ImageProvider> _providers = {};

  static ImageProvider provider(
    String path, {
    int cacheWidth = defaultCacheWidth,
  }) {
    final key = '$path|$cacheWidth';
    final existing = _providers[key];
    if (existing != null) return existing;

    if (_providers.length >= _maxEntries) {
      _providers.remove(_providers.keys.first);
    }

    final ImageProvider<Object> base;
    if (WardrobeItemImage.looksLikeRemoteUrl(path)) {
      base = NetworkImage(path);
    } else if (WardrobeItemImage.isAssetPath(path)) {
      base = AssetImage(path);
    } else {
      base = FileImage(File(path));
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
