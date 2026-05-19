import 'package:equatable/equatable.dart';

/// A single negative outfit feedback record (local only).
class OutfitDislikeEntry extends Equatable {
  const OutfitDislikeEntry({
    required this.id,
    required this.contentHash,
    required this.createdAt,
    required this.recommendationText,
    this.recommendedItemIds = const [],
    this.styles = const [],
    this.colors = const [],
    this.silhouettes = const [],
    this.combinationKey = '',
    this.moods = const [],
    this.occasions = const [],
  });

  final String id;
  final String contentHash;
  final DateTime createdAt;
  final String recommendationText;
  final List<String> recommendedItemIds;
  final List<String> styles;
  final List<String> colors;
  final List<String> silhouettes;
  final String combinationKey;
  final List<String> moods;
  final List<String> occasions;

  Map<String, dynamic> toJson() => {
        'id': id,
        'contentHash': contentHash,
        'createdAt': createdAt.toIso8601String(),
        'recommendationText': recommendationText,
        if (recommendedItemIds.isNotEmpty)
          'recommendedItemIds': recommendedItemIds,
        if (styles.isNotEmpty) 'styles': styles,
        if (colors.isNotEmpty) 'colors': colors,
        if (silhouettes.isNotEmpty) 'silhouettes': silhouettes,
        if (combinationKey.isNotEmpty) 'combinationKey': combinationKey,
        if (moods.isNotEmpty) 'moods': moods,
        if (occasions.isNotEmpty) 'occasions': occasions,
      };

  factory OutfitDislikeEntry.fromJson(Map<String, dynamic> json) {
    return OutfitDislikeEntry(
      id: json['id'] as String? ?? '',
      contentHash: json['contentHash'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      recommendationText: json['recommendationText'] as String? ?? '',
      recommendedItemIds: _list(json['recommendedItemIds']),
      styles: _list(json['styles']),
      colors: _list(json['colors']),
      silhouettes: _list(json['silhouettes']),
      combinationKey: json['combinationKey'] as String? ?? '',
      moods: _list(json['moods']),
      occasions: _list(json['occasions']),
    );
  }

  static List<String> _list(dynamic value) {
    if (value is! List<dynamic>) return const [];
    return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
  }

  @override
  List<Object?> get props => [
        id,
        contentHash,
        createdAt,
        recommendationText,
        recommendedItemIds,
        styles,
        colors,
        silhouettes,
        combinationKey,
        moods,
        occasions,
      ];
}
