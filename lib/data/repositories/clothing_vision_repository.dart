import 'package:flutter/widgets.dart';

import '../../core/localization/app_locale.dart';
import '../../core/services/clothing_vision_mapper.dart';
import '../../core/services/openai_chat_service.dart';
import '../../core/services/openai_vision_service.dart';
import '../../core/utils/logger.dart';
import '../models/clothing_vision_analysis.dart';
import 'wardrobe_repository.dart';

/// Wardrobe image analysis — coordinates Vision API and catalog mapping.
class ClothingVisionRepository {
  ClothingVisionRepository({
    OpenAiVisionService? visionService,
  }) : _visionService = visionService ?? OpenAiVisionService();

  final OpenAiVisionService _visionService;

  /// Sends [imagePath] to Vision API and returns catalog-aligned fields.
  Future<ClothingVisionAnalysis> analyzeImage(
    String imagePath, {
    Locale? locale,
  }) async {
    final uiLocale = locale ?? AppLocale.effectiveLocale();
    AppLogger.debug(
      'ClothingVisionRepository: analyze $imagePath locale=${uiLocale.languageCode}',
    );
    try {
      final wardrobe = await WardrobeRepository.instance.loadItems();
      final raw = await _visionService.analyzeClothingImage(
        imagePath,
        existingWardrobe: wardrobe,
        locale: uiLocale,
      );
      final mapped = ClothingVisionMapper.toCatalogValues(raw);
      final hasUsableFields =
          mapped.title.trim().isNotEmpty && mapped.category.trim().isNotEmpty;
      if (!mapped.recognizable && !hasUsableFields) {
        final note = mapped.recognitionNote.trim();
        throw OpenAiChatException(
          note.isNotEmpty
              ? note
              : AppLocale.pick(
                  ru:
                      'Не удалось распознать вещь — сделайте фото чётче или заполните вручную.',
                  en:
                      'Could not recognize the item — take a clearer photo or fill in manually.',
                  locale: uiLocale,
                ),
        );
      }
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
      throw OpenAiChatException(
        AppLocale.pick(
          ru: 'Не удалось распознать вещь. Заполните поля вручную.',
          en: 'Could not recognize the item. Fill in the fields manually.',
          locale: uiLocale,
        ),
      );
    }
  }
}
