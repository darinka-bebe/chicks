import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';

import '../../data/models/wardrobe_item.dart';

/// Reuses decoded thumbnail [ImageProvider]s for chat outfit cards.
abstract final class WardrobeChatImageCache {
  static const int defaultCacheWidth = 200;
  static const int _maxEntries = 64;

  static final Map<String, ImageProvider> _providers = {};

  /// Returns a cached provider, or `null` when [source] cannot be loaded.
  static ImageProvider? tryProvider(
    String source, {
    int cacheWidth = defaultCacheWidth,
  }) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) return null;

    final key = '$trimmed|$cacheWidth';
    final existing = _providers[key];
    if (existing != null) return existing;

    final ImageProvider<Object>? base = _baseProvider(trimmed);
    if (base == null) return null;

    if (_providers.length >= _maxEntries) {
      _providers.remove(_providers.keys.first);
    }

    final provider = ResizeImage(
      base,
      width: cacheWidth,
      policy: ResizeImagePolicy.fit,
    );
    _providers[key] = provider;
    return provider;
  }

  static ImageProvider provider(
    String source, {
    int cacheWidth = defaultCacheWidth,
  }) {
    final resolved = tryProvider(source, cacheWidth: cacheWidth);
    if (resolved != null) return resolved;
    throw ArgumentError(
      'WardrobeChatImageCache: unsupported image source: $source',
    );
  }

  static ImageProvider<Object>? _baseProvider(String source) {
    if (WardrobeItem.isHttpUrl(source)) {
      return CachedNetworkImageProvider(source);
    }
    if (WardrobeItem.isAssetPath(source)) {
      return AssetImage(source);
    }
    if (File(source).existsSync()) {
      return FileImage(File(source));
    }
    return null;
  }

  static void clear() => _providers.clear();
}
