import 'dart:io';

import 'package:flutter/painting.dart';

/// Reuses decoded thumbnail [ImageProvider]s for chat outfit cards.
abstract final class WardrobeChatImageCache {
  static const int defaultCacheWidth = 200;
  static const int _maxEntries = 64;

  static final Map<String, ImageProvider> _providers = {};

  static ImageProvider fileProvider(
    String path, {
    int cacheWidth = defaultCacheWidth,
  }) {
    final key = '$path|$cacheWidth';
    final existing = _providers[key];
    if (existing != null) return existing;

    if (_providers.length >= _maxEntries) {
      _providers.remove(_providers.keys.first);
    }

    final provider = ResizeImage(
      FileImage(File(path)),
      width: cacheWidth,
      policy: ResizeImagePolicy.fit,
    );
    _providers[key] = provider;
    return provider;
  }

  static void clear() => _providers.clear();
}
