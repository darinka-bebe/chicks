import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../core/constants/wardrobe_catalog.dart';

/// A clothing item in the user's digital wardrobe.
///
/// Cloud photos: [imageUrl] (Firebase Storage download URL).
/// [imagePath] is only a temporary local staging path before upload.
class WardrobeItem extends Equatable {
  final String id;
  final String title;
  final String category;
  final String color;
  final String season;
  final String fit;
  final List<String> styles;
  final List<String> occasions;
  final List<String> vibes;
  final String? imagePath;
  final String? imageUrl;

  const WardrobeItem({
    required this.id,
    required this.title,
    required this.category,
    required this.color,
    required this.season,
    this.fit = '',
    this.styles = const [],
    this.occasions = const [],
    this.vibes = const [],
    this.imagePath,
    this.imageUrl,
  });

  IconData get placeholderIcon => WardrobeCatalog.iconForCategory(category);

  String get localId => id;

  String get firestoreDocId => id;

  String firestorePath(String uid) => 'users/$uid/wardrobe/$firestoreDocId';

  bool get hasStyleMetadata =>
      styles.isNotEmpty ||
      occasions.isNotEmpty ||
      fit.isNotEmpty ||
      vibes.isNotEmpty;

  static bool isHttpUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  static bool isAssetPath(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.startsWith('assets/');
  }

  static bool hasCloudImageUrl(WardrobeItem item) => isHttpUrl(item.imageUrl);

  static bool hasPendingLocalUpload(WardrobeItem item) {
    final path = pendingLocalPath(item);
    if (path == null) return false;
    return File(path).existsSync();
  }

  /// Local file awaiting upload (never shown on other devices).
  static String? pendingLocalPath(WardrobeItem item) {
    final path = item.imagePath?.trim() ?? '';
    if (path.isEmpty || isAssetPath(path) || isHttpUrl(path)) return null;
    return path;
  }

  /// URL used by UI widgets ([CachedNetworkImage]).
  String? get displayImageUrl {
    final url = imageUrl?.trim() ?? '';
    if (isHttpUrl(url)) return url;

    final path = imagePath?.trim() ?? '';
    if (isHttpUrl(path)) return path;

    return null;
  }

  /// For chat thumbnail cache — cloud URL or asset path only.
  String? get displayImageSource {
    final url = displayImageUrl;
    if (url != null) return url;

    final path = imagePath?.trim() ?? '';
    if (isAssetPath(path)) return path;

    return null;
  }

  bool get hasDisplayImage {
    if (displayImageUrl != null) return true;
    return isAssetPath(imagePath);
  }

  /// Normalizes legacy fields (URL stored in [imagePath], etc.).
  static WardrobeItem normalizeImageFields(WardrobeItem item) {
    var url = item.imageUrl?.trim() ?? '';
    var path = item.imagePath?.trim() ?? '';

    if (!isHttpUrl(url) && isHttpUrl(path)) {
      url = path;
      path = '';
    }

    if (isHttpUrl(url) && path.isNotEmpty && !isAssetPath(path)) {
      path = '';
    }

    if (url == item.imageUrl && path == item.imagePath) return item;

    return item.copyWith(
      imageUrl: url.isEmpty ? null : url,
      imagePath: path.isEmpty ? null : path,
      clearImageUrl: url.isEmpty,
      clearImagePath: path.isEmpty,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firestoreDocId': firestoreDocId,
        'title': title,
        'category': category,
        'color': color,
        'season': season,
        'fit': fit,
        'styles': styles,
        'occasions': occasions,
        'vibes': vibes,
        if (imageUrl != null && imageUrl!.trim().isNotEmpty) 'imageUrl': imageUrl,
        if (!hasCloudImageUrl(this) &&
            imagePath != null &&
            imagePath!.trim().isNotEmpty)
          'imagePath': imagePath,
      };

  /// Firestore — only [imageUrl], never device-local [imagePath].
  Map<String, dynamic> toFirestoreJson() {
    final json = Map<String, dynamic>.from(toJson());
    json.remove('imagePath');
    return json;
  }

  static String readIdFromJson(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  WardrobeItem copyWith({
    String? id,
    String? title,
    String? category,
    String? color,
    String? season,
    String? fit,
    List<String>? styles,
    List<String>? occasions,
    List<String>? vibes,
    String? imagePath,
    String? imageUrl,
    bool clearImagePath = false,
    bool clearImageUrl = false,
  }) {
    return WardrobeItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      color: color ?? this.color,
      season: season ?? this.season,
      fit: fit ?? this.fit,
      styles: styles ?? this.styles,
      occasions: occasions ?? this.occasions,
      vibes: vibes ?? this.vibes,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
    );
  }

  factory WardrobeItem.fromJson(Map<String, dynamic> json) {
    return normalizeImageFields(
      WardrobeItem(
        id: readIdFromJson(json['id']),
        title: json['title'] as String? ?? '',
        category: json['category'] as String? ?? '',
        color: json['color'] as String? ?? '',
        season: json['season'] as String? ?? '',
        fit: json['fit'] as String? ?? '',
        styles: _parseStringList(json['styles']),
        occasions: _parseStringList(json['occasions']),
        vibes: _parseStringList(json['vibes']),
        imagePath: json['imagePath'] as String?,
        imageUrl: json['imageUrl'] as String?,
      ),
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List<dynamic>) {
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  static List<WardrobeItem> listFromJsonString(String jsonString) {
    if (jsonString.trim().isEmpty) return [];

    final decoded = jsonDecode(jsonString);
    if (decoded is! List<dynamic>) return [];

    return decoded
        .whereType<Map>()
        .map((entry) => WardrobeItem.fromJson(Map<String, dynamic>.from(entry)))
        .where((item) => item.title.isNotEmpty)
        .toList();
  }

  static String listToJsonString(List<WardrobeItem> items) {
    return jsonEncode(items.map((item) => item.toJson()).toList());
  }

  @override
  List<Object?> get props => [
        id,
        title,
        category,
        color,
        season,
        fit,
        styles,
        occasions,
        vibes,
        imagePath,
        imageUrl,
      ];
}
