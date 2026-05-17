import 'dart:convert';

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
  });

  IconData get placeholderIcon => WardrobeCatalog.iconForCategory(category);

  bool get hasStyleMetadata =>
      styles.isNotEmpty ||
      occasions.isNotEmpty ||
      fit.isNotEmpty ||
      vibes.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'color': color,
        'season': season,
        'fit': fit,
        'styles': styles,
        'occasions': occasions,
        'vibes': vibes,
        'imagePath': imagePath,
      };

  /// Hive / JSON may store ids as int (e.g. microsecond timestamps).
  static String readIdFromJson(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
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
      ];
}
