import '../models/outfit_preference_profile.dart';

/// Compact negative-taste block for the stylist system prompt.
abstract final class OutfitPreferencePromptBuilder {
  static String buildSystemSection(OutfitPreferenceProfile profile) {
    if (!profile.hasSignals) return '';

    final buffer = StringBuffer()
      ..writeln('НЕГАТИВНЫЕ ПРЕДПОЧТЕНИЯ ПОЛЬЗОВАТЕЛЯ (из дизлайков образов):');

    final styles = profile.topStyles();
    if (styles.isNotEmpty) {
      buffer.writeln('- Избегай стилей: ${_labels(styles)}.');
    }

    final colors = profile.topColors();
    if (colors.isNotEmpty) {
      buffer.writeln('- Избегай палитр/оттенков: ${_labels(colors)}.');
    }

    final silhouettes = profile.topSilhouettes();
    if (silhouettes.isNotEmpty) {
      buffer.writeln('- Избегай силуэтов/посадки: ${_labels(silhouettes)}.');
    }

    buffer.writeln(
      '- Не повторяй сочетания вещей, похожие на ранее отклонённые образы.',
    );
    buffer.writeln(
      '- Если есть альтернатива в гардеробе — предложи другой характер лука.',
    );

    return buffer.toString().trim();
  }

  static String _labels(List<String> keys) {
    return keys.map(_humanize).join(', ');
  }

  static String _humanize(String key) {
    return switch (key) {
      'oversized' => 'оверсайз / слишком свободная посадка',
      'sporty' => 'спортивный стиль',
      'streetwear' => 'streetwear',
      'romantic' => 'романтичный стиль',
      'elegant' => 'слишком нарядный / formal',
      'casual' => 'слишком casual',
      'minimal' => 'минимализм',
      'pink' => 'розовые сочетания',
      'bright' => 'яркие / неоновые цвета',
      'black' => 'полностью чёрные луки',
      'fitted' => 'слишком обтягивающая посадка',
      'relaxed' => 'слишком свободный силуэт',
      _ => key.replaceAll('_', ' '),
    };
  }
}
