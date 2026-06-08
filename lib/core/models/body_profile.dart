import '../localization/app_locale.dart';
import 'body_shape_type.dart';

/// Optional fit / proportion preferences stored with body shape.
class BodyProfile {
  const BodyProfile({
    required this.shape,
    this.heightCategory = '',
    this.shoulderWidth = '',
    this.hipDominance = '',
    this.fitPreference = '',
    this.prefersOversized = false,
    this.prefersFitted = false,
  });

  final BodyShapeType shape;
  final String heightCategory;
  final String shoulderWidth;
  final String hipDominance;
  final String fitPreference;
  final bool prefersOversized;
  final bool prefersFitted;

  String get displayFitPreference => switch (fitPreference) {
        'fitted' => AppLocale.pick(ru: 'по фигуре', en: 'fitted'),
        'oversized' => AppLocale.pick(ru: 'свободная', en: 'relaxed'),
        _ => AppLocale.pick(ru: 'универсальная', en: 'balanced'),
      };

  Map<String, dynamic> toJson() => {
        'shape': shape.storageKey,
        'heightCategory': heightCategory,
        'shoulderWidth': shoulderWidth,
        'hipDominance': hipDominance,
        'fitPreference': fitPreference,
        'prefersOversized': prefersOversized,
        'prefersFitted': prefersFitted,
      };

  factory BodyProfile.fromJson(Map<String, dynamic> json) {
    final shape = BodyShapeType.fromStorageKey(json['shape'] as String?) ??
        BodyShapeType.rectangle;
    return BodyProfile(
      shape: shape,
      heightCategory: json['heightCategory'] as String? ?? '',
      shoulderWidth: json['shoulderWidth'] as String? ?? '',
      hipDominance: json['hipDominance'] as String? ?? '',
      fitPreference: json['fitPreference'] as String? ?? '',
      prefersOversized: json['prefersOversized'] as bool? ?? false,
      prefersFitted: json['prefersFitted'] as bool? ?? false,
    );
  }

  BodyProfile copyWith({
    BodyShapeType? shape,
    String? heightCategory,
    String? shoulderWidth,
    String? hipDominance,
    String? fitPreference,
    bool? prefersOversized,
    bool? prefersFitted,
  }) {
    return BodyProfile(
      shape: shape ?? this.shape,
      heightCategory: heightCategory ?? this.heightCategory,
      shoulderWidth: shoulderWidth ?? this.shoulderWidth,
      hipDominance: hipDominance ?? this.hipDominance,
      fitPreference: fitPreference ?? this.fitPreference,
      prefersOversized: prefersOversized ?? this.prefersOversized,
      prefersFitted: prefersFitted ?? this.prefersFitted,
    );
  }
}

/// Quiz answers for body profile onboarding.
class BodyTypeQuizAnswers {
  const BodyTypeQuizAnswers({
    required this.shapeId,
    required this.shoulderHipsId,
    required this.waistId,
    required this.fitPreferenceId,
    required this.heightId,
  });

  final String shapeId;
  final String shoulderHipsId;
  final String waistId;
  final String fitPreferenceId;
  final String heightId;

  bool get isComplete =>
      shapeId.isNotEmpty &&
      shoulderHipsId.isNotEmpty &&
      waistId.isNotEmpty &&
      fitPreferenceId.isNotEmpty &&
      heightId.isNotEmpty;
}
