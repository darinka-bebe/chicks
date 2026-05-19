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
        SeasonalColorType.softSummer => 'Soft Summer',
        SeasonalColorType.coolWinter => 'Cool Winter',
      };

  /// Russian UI label.
  String get displayNameRu => switch (this) {
        SeasonalColorType.lightSpring => 'Светлая весна',
        SeasonalColorType.warmAutumn => 'Тёплая осень',
        SeasonalColorType.softSummer => 'Мягкое лето',
        SeasonalColorType.coolWinter => 'Холодная зима',
      };

  String get shortDescriptionRu => switch (this) {
        SeasonalColorType.lightSpring =>
          'Светлые тёплые оттенки, воздушные и свежие сочетания.',
        SeasonalColorType.warmAutumn =>
          'Тёплые природные тона: терракота, олива, карамель, горчица.',
        SeasonalColorType.softSummer =>
          'Приглушённые прохладные оттенки с мягким контрастом.',
        SeasonalColorType.coolWinter =>
          'Чистые холодные цвета и выраженный контраст в образе.',
      };
}
