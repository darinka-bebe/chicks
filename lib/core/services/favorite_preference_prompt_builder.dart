import '../models/favorite_preference_profile.dart';

/// Compact positive-taste block for the stylist system prompt.
abstract final class FavoritePreferencePromptBuilder {
  static String buildSystemSection(FavoritePreferenceProfile profile) {
    if (!profile.hasSignals) return '';

    final buffer = StringBuffer()
      ..writeln('ИЗБРАННЫЕ ОБРАЗЫ ПОЛЬЗОВАТЕЛЯ (усиливай похожие решения):');

    final styles = profile.topStyles();
    if (styles.isNotEmpty) {
      buffer.writeln(
        '- Предпочитает стили: ${_labels(styles)}.',
      );
    }

    final colors = profile.topColors();
    if (colors.isNotEmpty) {
      buffer.writeln(
        '- Нравятся палитры/оттенки: ${_labels(colors)}.',
      );
    }

    final silhouettes = profile.topSilhouettes();
    if (silhouettes.isNotEmpty) {
      buffer.writeln(
        '- Нравятся силуэты/посадка: ${_labels(silhouettes)}.',
      );
    }

    buffer.writeln(
      '- Если контекст подходит — предлагай вариации в духе сохранённых образов.',
    );
    buffer.writeln(
      '- Не копируй один в один — добавляй свежие сочетания из гардероба.',
    );

    return buffer.toString().trim();
  }

  static String _labels(List<String> keys) {
    return keys.map(_humanize).join(', ');
  }

  static String _humanize(String key) {
    return switch (key) {
      'oversized' => 'оверсайз / свободная посадка',
      'sporty' => 'спортивный стиль',
      'streetwear' => 'streetwear',
      'romantic' => 'романтичный стиль',
      'elegant' => 'элегантный / нарядный',
      'casual' => 'casual',
      'minimal' => 'минимализм',
      'pink' => 'розовые сочетания',
      'bright' => 'яркие оттенки',
      'black' => 'чёрные луки',
      'fitted' => 'приталенная посадка',
      'relaxed' => 'свободный силуэт',
      _ => key.replaceAll('_', ' '),
    };
  }
}
