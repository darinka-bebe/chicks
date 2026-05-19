import '../models/color_type_quiz_answers.dart';
import '../models/seasonal_color_type.dart';

/// Rule-based seasonal color type from appearance quiz answers.
abstract final class ColorTypeCalculator {
  static SeasonalColorType determine(ColorTypeQuizAnswers answers) {
    final scores = _scoreAll(answers);
    SeasonalColorType best = SeasonalColorType.softSummer;
    var bestValue = double.negativeInfinity;

    for (final entry in scores.entries) {
      if (entry.value > bestValue) {
        bestValue = entry.value;
        best = entry.key;
      }
    }

    return best;
  }

  static Map<SeasonalColorType, double> _scoreAll(ColorTypeQuizAnswers answers) {
    final scores = {
      for (final type in SeasonalColorType.values) type: 0.0,
    };

    void bump(SeasonalColorType type, double amount) {
      scores[type] = scores[type]! + amount;
    }

    switch (answers.eyeColorId) {
      case 'eye_light_blue':
        bump(SeasonalColorType.softSummer, 2.5);
        bump(SeasonalColorType.coolWinter, 2);
        bump(SeasonalColorType.lightSpring, 1.5);
      case 'eye_green_hazel':
        bump(SeasonalColorType.warmAutumn, 2);
        bump(SeasonalColorType.lightSpring, 1.5);
        bump(SeasonalColorType.softSummer, 1);
      case 'eye_warm_brown':
        bump(SeasonalColorType.warmAutumn, 2.5);
        bump(SeasonalColorType.lightSpring, 1.5);
      case 'eye_dark_brown':
        bump(SeasonalColorType.coolWinter, 2.5);
        bump(SeasonalColorType.warmAutumn, 1.5);
      default:
        break;
    }

    switch (answers.hairColorId) {
      case 'hair_light_blonde':
        bump(SeasonalColorType.lightSpring, 3);
        bump(SeasonalColorType.softSummer, 1.5);
      case 'hair_golden':
        bump(SeasonalColorType.warmAutumn, 3);
        bump(SeasonalColorType.lightSpring, 2);
      case 'hair_cool_brown':
        bump(SeasonalColorType.softSummer, 2.5);
        bump(SeasonalColorType.coolWinter, 1.5);
      case 'hair_dark':
        bump(SeasonalColorType.coolWinter, 2.5);
        bump(SeasonalColorType.warmAutumn, 2);
      default:
        break;
    }

    switch (answers.skinUndertoneId) {
      case 'undertone_warm':
        bump(SeasonalColorType.warmAutumn, 3);
        bump(SeasonalColorType.lightSpring, 2.5);
      case 'undertone_cool':
        bump(SeasonalColorType.coolWinter, 3);
        bump(SeasonalColorType.softSummer, 2.5);
      case 'undertone_neutral':
        bump(SeasonalColorType.softSummer, 1.5);
        bump(SeasonalColorType.warmAutumn, 1);
      default:
        break;
    }

    switch (answers.contrastLevelId) {
      case 'contrast_low':
        bump(SeasonalColorType.softSummer, 3);
        bump(SeasonalColorType.warmAutumn, 1.5);
      case 'contrast_medium':
        for (final type in SeasonalColorType.values) {
          bump(type, 0.5);
        }
      case 'contrast_high':
        bump(SeasonalColorType.coolWinter, 3);
        bump(SeasonalColorType.lightSpring, 1.5);
      default:
        break;
    }

    switch (answers.skinDepthId) {
      case 'depth_light':
        bump(SeasonalColorType.lightSpring, 3);
        bump(SeasonalColorType.softSummer, 2);
      case 'depth_medium':
        bump(SeasonalColorType.warmAutumn, 1.5);
        bump(SeasonalColorType.softSummer, 1);
      case 'depth_deep':
        bump(SeasonalColorType.warmAutumn, 2.5);
        bump(SeasonalColorType.coolWinter, 2);
      default:
        break;
    }

    return scores;
  }
}
