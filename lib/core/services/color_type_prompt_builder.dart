import '../models/seasonal_color_type.dart';

/// Compact color-type guidance for the AI stylist (low token usage).
abstract final class ColorTypePromptBuilder {
  static String buildSystemSection(SeasonalColorType type) {
    final palette = _paletteFor(type);
    return '''
ЦВЕТОТИП ПОЛЬЗОВАТЕЛЯ: ${type.englishLabel} (${type.displayNameRu}).
${palette.preferRu}
${palette.avoidRu}
В блоке «Почему это работает» добавь 1 короткую фразу, почему палитра образа подходит именно цветотипу ${type.englishLabel} (например: «оттенки хорошо ложатся на твой ${type.displayNameRu}»).
Не назначай цветотип заново — используй только ${type.englishLabel}.''';
  }

  static _PaletteHints _paletteFor(SeasonalColorType type) {
    return switch (type) {
      SeasonalColorType.lightSpring => const _PaletteHints(
            preferRu:
                'Предпочитай: светлые тёплые тона — коралл, персик, айвори, '
                'мягкий беж, светлая джинса, пастельный жёлтый.',
            avoidRu:
                'Избегай: тяжёлый чёрный у лица, холодный серый, '
                'приглушённые «пыльные» холодные оттенки.',
          ),
      SeasonalColorType.warmAutumn => const _PaletteHints(
            preferRu:
                'Предпочитай: тёплые землистые тона — терракота, олива, '
                'горчица, карамель, шоколад, тёплый беж, ржавый, хаки.',
            avoidRu:
                'Избегай: холодный розовый, ледяной голубой, '
                'кричащий неон и слишком бледные холодные пастели.',
          ),
      SeasonalColorType.softSummer => const _PaletteHints(
            preferRu:
                'Предпочитай: мягкие прохладные оттенки — пыльная роза, '
                'лаванда, голубой, мягкий серый, шалфей, приглушённый бордо.',
            avoidRu:
                'Избегай: чистый чёрный у лица, яркий оранжевый, '
                'жёлтый с зеленцой, слишком контрастные «кислотные» пары.',
          ),
      SeasonalColorType.coolWinter => const _PaletteHints(
            preferRu:
                'Предпочитай: холодные насыщенные тона — чистый белый, '
                'чёрный, фуксия, изумруд, синий, бордо, серебристый серый.',
            avoidRu:
                'Избегай: тёплый оранжевый, золотистый беж, '
                'приглушённые «теплые» пастели и грязноватые оттенки.',
          ),
    };
  }
}

class _PaletteHints {
  const _PaletteHints({
    required this.preferRu,
    required this.avoidRu,
  });

  final String preferRu;
  final String avoidRu;
}
