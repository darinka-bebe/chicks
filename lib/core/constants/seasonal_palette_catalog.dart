import 'package:flutter/material.dart';

/// Visual palette identity for seasonal color type cards.
enum SeasonalPaletteId {
  lightSpring,
  coolSummer,
  warmAutumn,
  brightWinter,
  deepAutumn,
  deepSummer,
  darkWinter,
  coolSpring,
}

extension SeasonalPaletteIdX on SeasonalPaletteId {
  String get displayNameRu => switch (this) {
        SeasonalPaletteId.lightSpring => 'Светлая весна',
        SeasonalPaletteId.coolSummer => 'Холодное лето',
        SeasonalPaletteId.warmAutumn => 'Тёплая осень',
        SeasonalPaletteId.brightWinter => 'Яркая зима',
        SeasonalPaletteId.deepAutumn => 'Глубокая осень',
        SeasonalPaletteId.deepSummer => 'Глубокое лето',
        SeasonalPaletteId.darkWinter => 'Тёмная зима',
        SeasonalPaletteId.coolSpring => 'Холодная весна',
      };

  String get shortDescriptionRu => switch (this) {
        SeasonalPaletteId.lightSpring =>
          'Светлые тёплые оттенки, воздушные и свежие сочетания.',
        SeasonalPaletteId.coolSummer =>
          'Нежные прохладные тона с мягким, деликатным контрастом.',
        SeasonalPaletteId.warmAutumn =>
          'Тёплые природные тона: терракота, карамель, олива, шоколад.',
        SeasonalPaletteId.brightWinter =>
          'Чистые насыщенные оттенки и выразительный контраст.',
        SeasonalPaletteId.deepAutumn =>
          'Глубокие землистые тона: ржавчина, оливковый, махагон.',
        SeasonalPaletteId.deepSummer =>
          'Приглушённые холодные оттенки с мягкой глубиной.',
        SeasonalPaletteId.darkWinter =>
          'Насыщенные холодные цвета и глубокий контраст.',
        SeasonalPaletteId.coolSpring =>
          'Светлые свежие оттенки с прохладным подтоном.',
      };
}

/// Soft pastel swatch sets for all seasonal color types.
abstract final class SeasonalPaletteCatalog {
  static const _swatchCount = 5;

  static List<Color> colorsFor(SeasonalPaletteId id) {
    final palette = _palettes[id] ?? _palettes[SeasonalPaletteId.lightSpring]!;
    assert(palette.length == _swatchCount);
    return palette;
  }

  static const _palettes = {
    SeasonalPaletteId.lightSpring: [
      Color(0xFFF8C4D8),
      Color(0xFFF5DCC4),
      Color(0xFFEBD4B8),
      Color(0xFFE8C8A8),
      Color(0xFFF0D8C0),
    ],
    SeasonalPaletteId.coolSummer: [
      Color(0xFFE4D4EC),
      Color(0xFFC8D8EC),
      Color(0xFFD0D0D8),
      Color(0xFFD8C4D0),
      Color(0xFFE8E0F0),
    ],
    SeasonalPaletteId.warmAutumn: [
      Color(0xFFD4A574),
      Color(0xFFCC8860),
      Color(0xFFC87850),
      Color(0xFF8B5A40),
      Color(0xFFA06848),
    ],
    SeasonalPaletteId.brightWinter: [
      Color(0xFFF8F8F8),
      Color(0xFFFF6EB4),
      Color(0xFFE84060),
      Color(0xFF5080E8),
      Color(0xFF303040),
    ],
    SeasonalPaletteId.deepAutumn: [
      Color(0xFF5C8050),
      Color(0xFF9C5840),
      Color(0xFF703028),
      Color(0xFF586838),
      Color(0xFF684830),
    ],
    SeasonalPaletteId.deepSummer: [
      Color(0xFF6888A8),
      Color(0xFFB89098),
      Color(0xFF98A890),
      Color(0xFF686870),
      Color(0xFF788898),
    ],
    SeasonalPaletteId.darkWinter: [
      Color(0xFFB898C8),
      Color(0xFF8898A8),
      Color(0xFF384878),
      Color(0xFF485058),
      Color(0xFF684888),
    ],
    SeasonalPaletteId.coolSpring: [
      Color(0xFFB8E8C8),
      Color(0xFFF0A890),
      Color(0xFF98C8E8),
      Color(0xFFB0A8E0),
      Color(0xFFF8C0D0),
    ],
  };

  /// Quiz option swatches (eyes, hair, undertone) — no photo assets.
  static List<Color>? quizOptionColors(String optionId) => switch (optionId) {
        'eye_light_blue' => const [
            Color(0xFFB8D4EC),
            Color(0xFFD0E4F0),
            Color(0xFFA8C8E0),
            Color(0xFFC8DCE8),
            Color(0xFFE0ECF4),
          ],
        'eye_green_hazel' => const [
            Color(0xFF98B898),
            Color(0xFFB0C8A8),
            Color(0xFF88A888),
            Color(0xFFC0D0B0),
            Color(0xFFA8B898),
          ],
        'eye_warm_brown' => const [
            Color(0xFFC89870),
            Color(0xFFB88058),
            Color(0xFFD0A880),
            Color(0xFFA87048),
            Color(0xFFE0B890),
          ],
        'eye_dark_brown' => const [
            Color(0xFF684830),
            Color(0xFF503820),
            Color(0xFF786040),
            Color(0xFF584028),
            Color(0xFF907050),
          ],
        'hair_light_blonde' => const [
            Color(0xFFF8E8C8),
            Color(0xFFF0D8B0),
            Color(0xFFE8C898),
            Color(0xFFF5E0B8),
            Color(0xFFEDD0A0),
          ],
        'hair_golden' => const [
            Color(0xFFE8C878),
            Color(0xFFD8B060),
            Color(0xFFF0D088),
            Color(0xFFC8A050),
            Color(0xFFE8D098),
          ],
        'hair_cool_brown' => const [
            Color(0xFFA89080),
            Color(0xFF988070),
            Color(0xFFB8A090),
            Color(0xFF887060),
            Color(0xFFC0B0A0),
          ],
        'hair_dark' => const [
            Color(0xFF484038),
            Color(0xFF383028),
            Color(0xFF585048),
            Color(0xFF403830),
            Color(0xFF686058),
          ],
        'undertone_warm' => const [
            Color(0xFFF0C8A0),
            Color(0xFFE8B888),
            Color(0xFFD8A070),
            Color(0xFFF5D8B8),
            Color(0xFFE0B080),
          ],
        'undertone_cool' => const [
            Color(0xFFE8C8D8),
            Color(0xFFD0E0F0),
            Color(0xFFE0D8F0),
            Color(0xFFC8D8E8),
            Color(0xFFF0E8F8),
          ],
        'undertone_neutral' => const [
            Color(0xFFD8C8B8),
            Color(0xFFE8DCD0),
            Color(0xFFC8B8A8),
            Color(0xFFE0D4C8),
            Color(0xFFD0C0B0),
          ],
        'depth_light' => const [
            Color(0xFFF5E6D8),
            Color(0xFFEDD8C8),
            Color(0xFFF8ECE0),
            Color(0xFFE8D0C0),
            Color(0xFFF0E0D0),
          ],
        'depth_medium' => const [
            Color(0xFFC89878),
            Color(0xFFB88868),
            Color(0xFFD0A888),
            Color(0xFFA87858),
            Color(0xFFE0B898),
          ],
        'depth_deep' => const [
            Color(0xFF684028),
            Color(0xFF583020),
            Color(0xFF785038),
            Color(0xFF483018),
            Color(0xFF886048),
          ],
        _ => null,
      };
}
