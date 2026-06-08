import '../constants/seasonal_palette_catalog.dart';
import '../localization/app_locale.dart';

/// Approximate seasonal color type (rule-based quiz, no image analysis).
enum SeasonalColorType {
  lightSpring,
  warmAutumn,
  softSummer,
  coolWinter;

  static SeasonalColorType? fromStorageKey(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return switch (raw.trim()) {
      'light_spring' => SeasonalColorType.lightSpring,
      'warm_autumn' => SeasonalColorType.warmAutumn,
      'soft_summer' => SeasonalColorType.softSummer,
      'cool_winter' => SeasonalColorType.coolWinter,
      _ => null,
    };
  }
}

extension SeasonalColorTypeX on SeasonalColorType {
  String get storageKey => switch (this) {
        SeasonalColorType.lightSpring => 'light_spring',
        SeasonalColorType.warmAutumn => 'warm_autumn',
        SeasonalColorType.softSummer => 'soft_summer',
        SeasonalColorType.coolWinter => 'cool_winter',
      };

  /// English label for AI prompts (compact tokens).
  String get englishLabel => switch (this) {
        SeasonalColorType.lightSpring => 'Light Spring',
        SeasonalColorType.warmAutumn => 'Warm Autumn',
        SeasonalColorType.softSummer => 'Cool Summer',
        SeasonalColorType.coolWinter => 'Bright Winter',
      };

  /// Russian UI label.
  String get displayNameRu => paletteId.displayNameRu;

  String get shortDescriptionRu => paletteId.shortDescriptionRu;

  String get displayName =>
      AppLocale.pick(ru: displayNameRu, en: englishLabel);

  String get shortDescription => AppLocale.pick(
        ru: shortDescriptionRu,
        en: paletteId.shortDescriptionEn,
      );

  SeasonalPaletteId get paletteId => switch (this) {
        SeasonalColorType.lightSpring => SeasonalPaletteId.lightSpring,
        SeasonalColorType.warmAutumn => SeasonalPaletteId.warmAutumn,
        SeasonalColorType.softSummer => SeasonalPaletteId.coolSummer,
        SeasonalColorType.coolWinter => SeasonalPaletteId.brightWinter,
      };
}
