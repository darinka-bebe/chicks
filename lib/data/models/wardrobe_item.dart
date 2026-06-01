import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../core/constants/wardrobe_catalog.dart';

/// A clothing item in the user's digital wardrobe.
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

  /// Stable local identifier (Hive key).
  String get localId => id;

  /// Same as [localId]; used as the Firestore document id.
  String get firestoreDocId => id;

  /// Full Firestore path: `users/{uid}/wardrobe/{firestoreDocId}`.
  String firestorePath(String uid) => 'users/$uid/wardrobe/$firestoreDocId';

  bool get hasStyleMetadata =>
      styles.isNotEmpty ||
      occasions.isNotEmpty ||
      fit.isNotEmpty ||
      vibes.isNotEmpty;

  /// Best source for UI: cloud URL first, then local/asset path.
  String? get displayImageSource {
    final url = imageUrl?.trim() ?? '';
    if (url.isNotEmpty) return url;
    final path = imagePath?.trim() ?? '';
    return path.isEmpty ? null : path;
  }

  bool get hasDisplayImage {
    final url = imageUrl?.trim() ?? '';
    if (url.startsWith('http://') || url.startsWith('https://')) return true;

    final path = imagePath?.trim() ?? '';
    if (path.isEmpty) return false;
    if (path.startsWith('assets/')) return true;
    if (path.startsWith('http://') || path.startsWith('https://')) return true;
    return File(path).existsSync();
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
        'imagePath': imagePath,
        'imageUrl': imageUrl,
      };

  /// Firestore payload — never sync device-local [imagePath].
  Map<String, dynamic> toFirestoreJson() {
    final json = Map<String, dynamic>.from(toJson());
    json.remove('imagePath');
    return json;
  }

  /// Hive / JSON may store ids as int (e.g. microsecond timestamps).
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
    return WardrobeItem(
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
