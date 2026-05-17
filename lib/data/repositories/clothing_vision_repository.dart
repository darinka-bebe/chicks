import '../../core/services/clothing_vision_mapper.dart';
import '../../core/services/openai_chat_service.dart';
import '../../core/services/openai_vision_service.dart';
import '../../core/utils/logger.dart';
import '../models/clothing_vision_analysis.dart';

/// Wardrobe image analysis — coordinates Vision API and catalog mapping.
class ClothingVisionRepository {
  ClothingVisionRepository({
    OpenAiVisionService? visionService,
  }) : _visionService = visionService ?? OpenAiVisionService();

  final OpenAiVisionService _visionService;

  /// Sends [imagePath] to Vision API and returns catalog-aligned fields.
  Future<ClothingVisionAnalysis> analyzeImage(String imagePath) async {
    AppLogger.debug('ClothingVisionRepository: analyze $imagePath');
    try {
      final raw = await _visionService.analyzeClothingImage(imagePath);
      final mapped = ClothingVisionMapper.toCatalogValues(raw);
      AppLogger.debug(
        'ClothingVisionRepository: title="${mapped.title}" category=${mapped.category}',
      );
      return mapped;
    } on OpenAiChatException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error(
        'ClothingVisionRepository: unexpected failure',
        error: e,
        stackTrace: stack,
      );
      throw const OpenAiChatException(
        'Не удалось распознать вещь. Заполните поля вручную.',
      );
    }
  }
}
