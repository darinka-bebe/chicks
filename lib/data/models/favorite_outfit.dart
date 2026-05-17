import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../core/services/outfit_content_hasher.dart';

/// A saved AI stylist outfit recommendation.
class FavoriteOutfit extends Equatable {
  final String id;
  final String title;
  final String recommendation;
  final String contentHash;
  final DateTime createdAt;
  final List<String> moods;
  final List<String> occasions;
  final List<String> weather;

  const FavoriteOutfit({
    required this.id,
    required this.title,
    required this.recommendation,
    required this.contentHash,
    required this.createdAt,
    this.moods = const [],
    this.occasions = const [],
    this.weather = const [],
  });

  bool get hasContext =>
      moods.isNotEmpty || occasions.isNotEmpty || weather.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'recommendation': recommendation,
        'contentHash': contentHash,
        'createdAt': createdAt.toIso8601String(),
        'moods': moods,
        'occasions': occasions,
        'weather': weather,
      };

  factory FavoriteOutfit.fromJson(Map<String, dynamic> json) {
    final recommendation = json['recommendation'] as String? ?? '';
    final storedHash = json['contentHash'] as String? ?? '';

    return FavoriteOutfit(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      recommendation: recommendation,
      contentHash: storedHash.isNotEmpty
          ? storedHash
          : OutfitContentHasher.hash(recommendation),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      moods: _parseList(json['moods']),
      occasions: _parseList(json['occasions']),
      weather: _parseList(json['weather']),
    );
  }

  static List<String> _parseList(dynamic value) {
    if (value is List<dynamic>) {
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  static List<FavoriteOutfit> listFromJsonString(String jsonString) {
    if (jsonString.trim().isEmpty) return [];

    final decoded = jsonDecode(jsonString);
    if (decoded is! List<dynamic>) return [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(FavoriteOutfit.fromJson)
        .where((item) => item.recommendation.isNotEmpty)
        .toList();
  }

  static String listToJsonString(List<FavoriteOutfit> items) {
    return jsonEncode(items.map((item) => item.toJson()).toList());
  }

  @override
  List<Object?> get props => [
        id,
        title,
        recommendation,
        contentHash,
        createdAt,
        moods,
        occasions,
        weather,
      ];
}
