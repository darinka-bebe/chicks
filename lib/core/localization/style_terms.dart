import 'app_locale.dart';

/// Shared style / mood labels for insights and prompts.
abstract final class StyleTerms {
  static String streetwear() => AppLocale.pick(
        ru: 'уличный стиль',
        en: 'streetwear',
        kk: 'көше стилі',
      );

  static String casual() => AppLocale.pick(
        ru: 'повседневный',
        en: 'casual',
        kk: 'күнделікті',
      );

  static String comfy() => AppLocale.pick(
        ru: 'уютный',
        en: 'comfy',
        kk: 'ыңғайлы',
      );

  static String cleanGirl() => AppLocale.pick(
        ru: 'clean girl',
        en: 'clean girl',
        kk: 'clean girl',
      );

  static String oldMoney() => AppLocale.pick(
        ru: 'old money',
        en: 'old money',
        kk: 'old money',
      );

  static String feminine() => AppLocale.pick(
        ru: 'женственный',
        en: 'feminine',
        kk: 'әйелдік',
      );

  static String sporty() => AppLocale.pick(
        ru: 'спортивный',
        en: 'sporty',
        kk: 'спорттық',
      );

  static String cozy() => AppLocale.pick(
        ru: 'уютный',
        en: 'cozy',
        kk: 'жайлы',
      );

  static String romantic() => AppLocale.pick(
        ru: 'романтичный',
        en: 'romantic',
        kk: 'романтик',
      );

  static String softSummer() => AppLocale.pick(
        ru: 'мягкое лето',
        en: 'soft summer',
        kk: 'жұмсақ жаз',
      );

  static String smartCasual() => AppLocale.pick(
        ru: 'smart-casual',
        en: 'smart-casual',
        kk: 'smart-casual',
      );
}
