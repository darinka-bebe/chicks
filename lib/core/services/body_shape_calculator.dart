import '../models/body_profile.dart';
import '../models/body_shape_type.dart';
/// Maps onboarding answers → [BodyProfile].
abstract final class BodyShapeCalculator {
  static BodyProfile determine(BodyTypeQuizAnswers answers) {
    final shape = _shapeFromId(answers.shapeId);
    final fitId = answers.fitPreferenceId;

    return BodyProfile(
      shape: shape,
      heightCategory: _heightFromId(answers.heightId),
      shoulderWidth: _shouldersFromId(answers.shoulderHipsId),
      hipDominance: _hipsFromId(answers.shoulderHipsId, answers.waistId),
      fitPreference: _fitLabelFromId(fitId),
      prefersOversized: fitId == 'fit_oversized',
      prefersFitted: fitId == 'fit_fitted',
    );
  }

  static BodyShapeType _shapeFromId(String id) {
    return switch (id) {
      'shape_hourglass' => BodyShapeType.hourglass,
      'shape_pear' => BodyShapeType.pear,
      'shape_rectangle' => BodyShapeType.rectangle,
      'shape_apple' => BodyShapeType.apple,
      'shape_inverted' => BodyShapeType.invertedTriangle,
      _ => BodyShapeType.rectangle,
    };
  }

  static String _heightFromId(String id) => switch (id) {
        'height_petite' => 'petite',
        'height_tall' => 'tall',
        _ => 'average',
      };

  static String _shouldersFromId(String id) => switch (id) {
        'prop_narrow_shoulders' => 'narrow',
        'prop_broad_shoulders' => 'broad',
        _ => 'balanced',
      };

  static String _hipsFromId(String propId, String waistId) {
    if (propId == 'prop_wide_hips') return 'high';
    if (waistId == 'waist_straight') return 'balanced';
    return 'balanced';
  }

  static String _fitLabelFromId(String id) => switch (id) {
        'fit_fitted' => 'fitted',
        'fit_oversized' => 'oversized',
        _ => 'balanced',
      };
}
