import '../models/body_profile.dart';
import '../models/body_shape_type.dart';

/// Compact body-shape guidance for the AI stylist.
abstract final class BodyTypePromptBuilder {
  static String buildSystemSection(BodyProfile profile) {
    final rules = _rulesFor(profile.shape);
    final extras = _extrasLine(profile);

    return '''
ТИП ФИГУРЫ: ${profile.shape.englishLabel} (${profile.shape.displayNameRu}).
${rules.preferRu}
${rules.avoidRu}
$extras
При подборе recommendedItemIds выбирай вещи, которые поддерживают силуэт (не только описывай).
В «Почему это работает» добавь 1 фразу про тип фигуры (почему пропорции/посадка образа подходят).''';
  }

  static String _extrasLine(BodyProfile profile) {
    final parts = <String>[];
    if (profile.heightCategory.isNotEmpty && profile.heightCategory != 'average') {
      parts.add('рост: ${profile.heightCategory}');
    }
    if (profile.fitPreference.isNotEmpty) {
      parts.add('посадка: ${profile.fitPreference}');
    }
    if (profile.prefersOversized) {
      parts.add('любит oversize на верхе');
    }
    if (profile.prefersFitted) {
      parts.add('предпочитает приталенный крой');
    }
    if (parts.isEmpty) return '';
    return 'Уточнения: ${parts.join(', ')}.';
  }

  static _BodyRules _rulesFor(BodyShapeType shape) {
    return switch (shape) {
      BodyShapeType.hourglass => const _BodyRules(
            preferRu:
                'Подчёркивай талию: приталенный верх, пояс, wrap, платье по фигуре. '
                'Балансируй объём верха и низа.',
            avoidRu:
                'Избегай одновременно мешковатого oversize сверху и снизу без талии.',
          ),
      BodyShapeType.pear => const _BodyRules(
            preferRu:
                'Визуально уравнивай: акцент на верх (плечи, яркий/структурный верх), '
                'более спокойный низ. Подходят А-силуэт, прямые брюки.',
            avoidRu:
                'Не сочетай oversize низ + oversize верх без структуры. '
                'Не перегружай бёдра объёмом и тёмным низом без баланса сверху.',
          ),
      BodyShapeType.rectangle => const _BodyRules(
            preferRu:
                'Создавай изгибы: слои, пояс, peplum, контраст верх/низ, '
                'текстуры и приталенные элементы.',
            avoidRu:
                'Избегай полностью прямого «прямоугольного» силуэта без линии талии.',
          ),
      BodyShapeType.apple => const _BodyRules(
            preferRu:
                'Удлиняй силуэт: V-вырез, структурные плечи, верх чуть длиннее, '
                'прямой/flowy низ, монохромные вертикали.',
            avoidRu:
                'Избегай плотной талии и объёмного oversize только в центре образа.',
          ),
      BodyShapeType.invertedTriangle => const _BodyRules(
            preferRu:
                'Смягчай верх, добавляй объём внизу: светлый/детальный верх, '
                'А-силуэт, светлый низ, широкие брюки/юбка.',
            avoidRu:
                'Избегай плечевых акцентов, объёмных воротников и узкого низа без баланса.',
          ),
    };
  }
}

class _BodyRules {
  const _BodyRules({required this.preferRu, required this.avoidRu});

  final String preferRu;
  final String avoidRu;
}
