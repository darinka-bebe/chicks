import 'package:flutter/material.dart';

import '../../../core/localization/app_locale.dart';

class ColorTypeQuizOption {
  const ColorTypeQuizOption({
    required this.id,
    required this.label,
    this.subtitle,
    this.icon,
  });

  final String id;
  final String label;
  final String? subtitle;
  final IconData? icon;
}

class ColorTypeQuizQuestion {
  const ColorTypeQuizQuestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.options,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<ColorTypeQuizOption> options;
}

abstract final class ColorTypeQuizQuestions {
  static List<ColorTypeQuizQuestion> get questions =>
      AppLocale.isRussian() ? _questionsRu : _questionsEn;

  static const _questionsRu = <ColorTypeQuizQuestion>[
    ColorTypeQuizQuestion(
      id: 'eye_color',
      title: 'Какой у тебя цвет глаз?',
      subtitle: 'Натуральный оттенок без линз',
      options: [
        ColorTypeQuizOption(
          id: 'eye_light_blue',
          label: 'Светло-голубые или серые',
          icon: Icons.remove_red_eye_outlined,
        ),
        ColorTypeQuizOption(
          id: 'eye_green_hazel',
          label: 'Зелёные или ореховые',
          icon: Icons.remove_red_eye_outlined,
        ),
        ColorTypeQuizOption(
          id: 'eye_warm_brown',
          label: 'Тёплые карие / медные',
          icon: Icons.remove_red_eye_outlined,
        ),
        ColorTypeQuizOption(
          id: 'eye_dark_brown',
          label: 'Тёмно-карие или чёрные',
          icon: Icons.remove_red_eye_outlined,
        ),
      ],
    ),
    ColorTypeQuizQuestion(
      id: 'hair_color',
      title: 'Натуральный цвет волос',
      subtitle: 'Какой оттенок ближе к твоему природному',
      options: [
        ColorTypeQuizOption(
          id: 'hair_light_blonde',
          label: 'Светлый блонд / пепельный',
          icon: Icons.face_retouching_natural_outlined,
        ),
        ColorTypeQuizOption(
          id: 'hair_golden',
          label: 'Золотистый / рыжеватый / медный',
          icon: Icons.face_retouching_natural_outlined,
        ),
        ColorTypeQuizOption(
          id: 'hair_cool_brown',
          label: 'Пепельно-каштановый',
          icon: Icons.face_retouching_natural_outlined,
        ),
        ColorTypeQuizOption(
          id: 'hair_dark',
          label: 'Тёмно-каштановый / чёрный',
          icon: Icons.face_retouching_natural_outlined,
        ),
      ],
    ),
    ColorTypeQuizQuestion(
      id: 'skin_undertone',
      title: 'Подтон кожи',
      subtitle: 'На что больше тянет в естественном свете',
      options: [
        ColorTypeQuizOption(
          id: 'undertone_warm',
          label: 'Тёплый',
          subtitle: 'Золотистый, персиковый, слоновая кость',
          icon: Icons.wb_sunny_outlined,
        ),
        ColorTypeQuizOption(
          id: 'undertone_cool',
          label: 'Холодный',
          subtitle: 'Розовый, голубоватый, фарфоровый',
          icon: Icons.ac_unit_outlined,
        ),
        ColorTypeQuizOption(
          id: 'undertone_neutral',
          label: 'Нейтральный',
          subtitle: 'Сложно определить — смешанный',
          icon: Icons.balance_outlined,
        ),
      ],
    ),
    ColorTypeQuizQuestion(
      id: 'contrast_level',
      title: 'Уровень контраста',
      subtitle: 'Насколько контрастны волосы, кожа и глаза',
      options: [
        ColorTypeQuizOption(
          id: 'contrast_low',
          label: 'Низкий',
          subtitle: 'Мягкие, близкие по глубине черты',
        ),
        ColorTypeQuizOption(
          id: 'contrast_medium',
          label: 'Средний',
        ),
        ColorTypeQuizOption(
          id: 'contrast_high',
          label: 'Высокий',
          subtitle: 'Ярко выраженная разница тонов',
        ),
      ],
    ),
    ColorTypeQuizQuestion(
      id: 'skin_depth',
      title: 'Глубина тона кожи',
      subtitle: 'Общая светлость кожи без загара',
      options: [
        ColorTypeQuizOption(
          id: 'depth_light',
          label: 'Светлый',
          icon: Icons.brightness_low_outlined,
        ),
        ColorTypeQuizOption(
          id: 'depth_medium',
          label: 'Средний',
          icon: Icons.brightness_medium_outlined,
        ),
        ColorTypeQuizOption(
          id: 'depth_deep',
          label: 'Глубокий / смуглый',
          icon: Icons.brightness_high_outlined,
        ),
      ],
    ),
  ];

  static const _questionsEn = <ColorTypeQuizQuestion>[
    ColorTypeQuizQuestion(
      id: 'eye_color',
      title: 'What is your eye color?',
      subtitle: 'Natural shade without contacts',
      options: [
        ColorTypeQuizOption(
          id: 'eye_light_blue',
          label: 'Light blue or gray',
          icon: Icons.remove_red_eye_outlined,
        ),
        ColorTypeQuizOption(
          id: 'eye_green_hazel',
          label: 'Green or hazel',
          icon: Icons.remove_red_eye_outlined,
        ),
        ColorTypeQuizOption(
          id: 'eye_warm_brown',
          label: 'Warm brown / amber',
          icon: Icons.remove_red_eye_outlined,
        ),
        ColorTypeQuizOption(
          id: 'eye_dark_brown',
          label: 'Dark brown or black',
          icon: Icons.remove_red_eye_outlined,
        ),
      ],
    ),
    ColorTypeQuizQuestion(
      id: 'hair_color',
      title: 'Natural hair color',
      subtitle: 'Which shade is closest to your natural color',
      options: [
        ColorTypeQuizOption(
          id: 'hair_light_blonde',
          label: 'Light blonde / ash',
          icon: Icons.face_retouching_natural_outlined,
        ),
        ColorTypeQuizOption(
          id: 'hair_golden',
          label: 'Golden / auburn / copper',
          icon: Icons.face_retouching_natural_outlined,
        ),
        ColorTypeQuizOption(
          id: 'hair_cool_brown',
          label: 'Ash brown',
          icon: Icons.face_retouching_natural_outlined,
        ),
        ColorTypeQuizOption(
          id: 'hair_dark',
          label: 'Dark brown / black',
          icon: Icons.face_retouching_natural_outlined,
        ),
      ],
    ),
    ColorTypeQuizQuestion(
      id: 'skin_undertone',
      title: 'Skin undertone',
      subtitle: 'What stands out most in natural light',
      options: [
        ColorTypeQuizOption(
          id: 'undertone_warm',
          label: 'Warm',
          subtitle: 'Golden, peachy, ivory',
          icon: Icons.wb_sunny_outlined,
        ),
        ColorTypeQuizOption(
          id: 'undertone_cool',
          label: 'Cool',
          subtitle: 'Pink, bluish, porcelain',
          icon: Icons.ac_unit_outlined,
        ),
        ColorTypeQuizOption(
          id: 'undertone_neutral',
          label: 'Neutral',
          subtitle: 'Hard to tell — mixed',
          icon: Icons.balance_outlined,
        ),
      ],
    ),
    ColorTypeQuizQuestion(
      id: 'contrast_level',
      title: 'Contrast level',
      subtitle: 'How much contrast between hair, skin, and eyes',
      options: [
        ColorTypeQuizOption(
          id: 'contrast_low',
          label: 'Low',
          subtitle: 'Soft features with similar depth',
        ),
        ColorTypeQuizOption(
          id: 'contrast_medium',
          label: 'Medium',
        ),
        ColorTypeQuizOption(
          id: 'contrast_high',
          label: 'High',
          subtitle: 'Strong difference between tones',
        ),
      ],
    ),
    ColorTypeQuizQuestion(
      id: 'skin_depth',
      title: 'Skin depth',
      subtitle: 'Overall lightness without tan',
      options: [
        ColorTypeQuizOption(
          id: 'depth_light',
          label: 'Light',
          icon: Icons.brightness_low_outlined,
        ),
        ColorTypeQuizOption(
          id: 'depth_medium',
          label: 'Medium',
          icon: Icons.brightness_medium_outlined,
        ),
        ColorTypeQuizOption(
          id: 'depth_deep',
          label: 'Deep / tan',
          icon: Icons.brightness_high_outlined,
        ),
      ],
    ),
  ];
}
