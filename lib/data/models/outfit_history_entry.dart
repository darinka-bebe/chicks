import 'package:equatable/equatable.dart';

/// A persisted AI stylist outfit recommendation snapshot.
class OutfitHistoryEntry extends Equatable {
  const OutfitHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.userPrompt,
    required this.aiResponseText,
    this.recommendedItemIds = const [],
    this.weatherLabel,
    this.moods = const [],
    this.occasions = const [],
    this.weather = const [],
  });

  final String id;
  final DateTime createdAt;
  final String title;
  final String userPrompt;
  final String aiResponseText;
  final List<String> recommendedItemIds;
  final String? weatherLabel;
  final List<String> moods;
  final List<String> occasions;
  final List<String> weather;

  bool get hasRecommendations => recommendedItemIds.isNotEmpty;

  bool get hasContext =>
      moods.isNotEmpty ||
      occasions.isNotEmpty ||
      weather.isNotEmpty ||
      (weatherLabel != null && weatherLabel!.trim().isNotEmpty);

  List<String> get styleTags => [
        ...moods,
        ...occasions,
        ...weather,
      ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'title': title,
        'userPrompt': userPrompt,
        'aiResponseText': aiResponseText,
        if (recommendedItemIds.isNotEmpty)
          'recommendedItemIds': recommendedItemIds,
        if (weatherLabel != null && weatherLabel!.trim().isNotEmpty)
          'weatherLabel': weatherLabel,
        if (moods.isNotEmpty) 'moods': moods,
        if (occasions.isNotEmpty) 'occasions': occasions,
        if (weather.isNotEmpty) 'weather': weather,
      };

  factory OutfitHistoryEntry.fromJson(Map<String, dynamic> json) {
    return OutfitHistoryEntry(
      id: json['id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      title: json['title'] as String? ?? '',
      userPrompt: json['userPrompt'] as String? ?? '',
      aiResponseText: json['aiResponseText'] as String? ??
          json['recommendation'] as String? ??
          '',
      recommendedItemIds: _parseList(json['recommendedItemIds']) ??
          _parseList(json['recommendedItems']) ??
          const [],
      weatherLabel: json['weatherLabel'] as String?,
      moods: _parseList(json['moods']) ?? const [],
      occasions: _parseList(json['occasions']) ?? const [],
      weather: _parseList(json['weather']) ?? const [],
    );
  }

  static List<String>? _parseList(dynamic value) {
    if (value is! List<dynamic>) return null;
    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  @override
  List<Object?> get props => [
        id,
        createdAt,
        title,
        userPrompt,
        aiResponseText,
        recommendedItemIds,
        weatherLabel,
        moods,
        occasions,
        weather,
      ];
}
