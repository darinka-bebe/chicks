import '../../data/models/clothing_vision_analysis.dart';
import '../../data/models/wardrobe_item.dart';
import '../../data/repositories/wardrobe_repository.dart';
import '../constants/wardrobe_catalog.dart';

/// Builds [WardrobeItem] rows from Vision analysis.
abstract final class WardrobeItemFromVision {
  static WardrobeItem build({
    required ClothingVisionAnalysis analysis,
    String? imagePath,
    String? id,
  }) {
    final color = analysis.color.trim();
    return WardrobeItem(
      id: id ?? WardrobeRepository.generateItemId(),
      title: analysis.title.trim(),
      category: WardrobeCatalog.categories.contains(analysis.category)
          ? analysis.category
          : WardrobeCatalog.categories.first,
      color: color.isEmpty ? 'Не указан' : color,
      season: analysis.seasons.isNotEmpty
          ? analysis.seasons.first
          : WardrobeCatalog.seasons.last,
      fit: analysis.fit,
      styles: List<String>.from(analysis.styles),
      occasions: List<String>.from(analysis.occasions),
      vibes: List<String>.from(analysis.vibes),
      imagePath: imagePath,
    );
  }
}
