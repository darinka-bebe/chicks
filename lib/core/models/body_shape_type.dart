/// Body shape types for silhouette-aware styling (rule-based, no photos).
enum BodyShapeType {
  hourglass,
  pear,
  rectangle,
  apple,
  invertedTriangle;

  static BodyShapeType? fromStorageKey(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return switch (raw.trim()) {
      'hourglass' => BodyShapeType.hourglass,
      'pear' => BodyShapeType.pear,
      'rectangle' => BodyShapeType.rectangle,
      'apple' => BodyShapeType.apple,
      'inverted_triangle' => BodyShapeType.invertedTriangle,
      _ => null,
    };
  }

  String get storageKey => switch (this) {
        BodyShapeType.hourglass => 'hourglass',
        BodyShapeType.pear => 'pear',
        BodyShapeType.rectangle => 'rectangle',
        BodyShapeType.apple => 'apple',
        BodyShapeType.invertedTriangle => 'inverted_triangle',
      };

  /// English label for AI prompts (compact tokens).
  String get englishLabel => switch (this) {
        BodyShapeType.hourglass => 'Hourglass',
        BodyShapeType.pear => 'Pear',
        BodyShapeType.rectangle => 'Rectangle',
        BodyShapeType.apple => 'Apple',
        BodyShapeType.invertedTriangle => 'Inverted Triangle',
      };

  /// Russian UI label.
  String get displayNameRu => switch (this) {
        BodyShapeType.hourglass => 'Песочные часы',
        BodyShapeType.pear => 'Груша',
        BodyShapeType.rectangle => 'Прямоугольник',
        BodyShapeType.apple => 'Яблоко',
        BodyShapeType.invertedTriangle => 'Перевёрнутый треугольник',
      };

  String get shortDescriptionRu => switch (this) {
        BodyShapeType.hourglass =>
          'Баланс плеч и бёдер, выраженная талия — подчёркивай линию талии.',
        BodyShapeType.pear =>
          'Бёдра шире плеч — визуально уравнивай пропорции через верх.',
        BodyShapeType.rectangle =>
          'Плечи, талия и бёдра близки — создавай изгибы и слои.',
        BodyShapeType.apple =>
          'Акцент в центре — удлиняй силуэт и структурируй плечи.',
        BodyShapeType.invertedTriangle =>
          'Плечи шире бёдер — смягчай верх, добавляй объём внизу.',
      };
}
