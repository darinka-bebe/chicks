import 'package:equatable/equatable.dart';

/// Structured wardrobe fields returned by OpenAI Vision.
class ClothingVisionAnalysis extends Equatable {
  const ClothingVisionAnalysis({
    required this.title,
    required this.category,
    required this.color,
    this.clothingType = '',
    this.styles = const [],
    this.seasons = const [],
    this.occasions = const [],
    this.vibes = const [],
    this.fit = '',
    this.outfitContext = '',
    this.isDuplicate = false,
    this.duplicateMatchTitle = '',
    this.recognizable = true,
    this.recognitionNote = '',
  });

  final String title;
  final String category;
  final String color;
  final String clothingType;
  final List<String> styles;
  final List<String> seasons;
  final List<String> occasions;
  final List<String> vibes;
  final String fit;
  final String outfitContext;

  /// Vision thinks this photo is the same item already in the user's wardrobe.
  final bool isDuplicate;

  /// Title of the existing wardrobe item (must match list from the prompt).
  final String duplicateMatchTitle;

  /// False when the item is too blurry, cropped, or hidden to describe honestly.
  final bool recognizable;

  /// User-facing explanation when [recognizable] is false.
  final String recognitionNote;

  factory ClothingVisionAnalysis.fromJson(Map<String, dynamic> json) {
    return ClothingVisionAnalysis(
      title: _str(json['title']),
      category: _str(json['category']),
      color: _str(json['color']),
      clothingType: _str(json['clothingType'] ?? json['clothing_type']),
      styles: _strList(json['styles']),
      seasons: _strList(json['seasons'] ?? json['season']),
      occasions: _strList(json['occasions']),
      vibes: _strList(json['vibes']),
      fit: _str(json['fit']),
      outfitContext: _str(json['outfitContext'] ?? json['outfit_context']),
      isDuplicate: json['isDuplicate'] == true || json['is_duplicate'] == true,
      duplicateMatchTitle: _str(
        json['duplicateMatchTitle'] ?? json['duplicate_match_title'],
      ),
      recognizable: json['recognizable'] != false,
      recognitionNote: _str(
        json['recognitionNote'] ?? json['recognition_note'],
      ),
    );
  }

  static String _str(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static List<String> _strList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }
    return const [];
  }

  @override
  List<Object?> get props => [
        title,
        category,
        color,
        clothingType,
        styles,
        seasons,
        occasions,
        vibes,
        fit,
        outfitContext,
        isDuplicate,
        duplicateMatchTitle,
        recognizable,
        recognitionNote,
      ];
}
