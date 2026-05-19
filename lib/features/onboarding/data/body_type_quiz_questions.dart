class BodyTypeQuizOption {
  const BodyTypeQuizOption({
    required this.id,
    required this.label,
    this.hint,
  });

  final String id;
  final String label;
  final String? hint;
}

class BodyTypeQuizQuestion {
  const BodyTypeQuizQuestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.options,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<BodyTypeQuizOption> options;
}

abstract final class BodyTypeQuizQuestions {
  static const questions = <BodyTypeQuizQuestion>[
    BodyTypeQuizQuestion(
      id: 'body_shape',
      title: 'Какой силуэт ближе всего?',
      subtitle: 'Смотри на пропорции плеч, талии и бёдер',
      options: [
        BodyTypeQuizOption(
          id: 'shape_hourglass',
          label: 'Песочные часы',
          hint: 'Талия уже плеч и бёдер',
        ),
        BodyTypeQuizOption(
          id: 'shape_pear',
          label: 'Груша',
          hint: 'Низ шире верха',
        ),
        BodyTypeQuizOption(
          id: 'shape_rectangle',
          label: 'Прямоугольник',
          hint: 'Почти прямая линия',
        ),
        BodyTypeQuizOption(
          id: 'shape_apple',
          label: 'Яблоко',
          hint: 'Объём в центре',
        ),
        BodyTypeQuizOption(
          id: 'shape_inverted',
          label: 'Перевёрнутый треугольник',
          hint: 'Плечи шире бёдер',
        ),
      ],
    ),
    BodyTypeQuizQuestion(
      id: 'shoulder_hips',
      title: 'Плечи и бёдра',
      subtitle: 'Где шире — сверху или снизу?',
      options: [
        BodyTypeQuizOption(
          id: 'prop_narrow_shoulders',
          label: 'Уже сверху',
          hint: 'Плечи уже бёдер',
        ),
        BodyTypeQuizOption(
          id: 'prop_balanced',
          label: 'Сбалансировано',
          hint: 'Плечи ≈ бёдра',
        ),
        BodyTypeQuizOption(
          id: 'prop_broad_shoulders',
          label: 'Шире сверху',
          hint: 'Плечи шире бёдер',
        ),
        BodyTypeQuizOption(
          id: 'prop_wide_hips',
          label: 'Шире снизу',
          hint: 'Бёдра заметно шире',
        ),
      ],
    ),
    BodyTypeQuizQuestion(
      id: 'waist',
      title: 'Линия талии',
      subtitle: 'Насколько выражен изгиб?',
      options: [
        BodyTypeQuizOption(
          id: 'waist_defined',
          label: 'Выраженная талия',
          hint: 'Чёткий перехват',
        ),
        BodyTypeQuizOption(
          id: 'waist_soft',
          label: 'Мягкая линия',
          hint: 'Плавный переход',
        ),
        BodyTypeQuizOption(
          id: 'waist_straight',
          label: 'Почти прямая',
          hint: 'Мало изгиба',
        ),
      ],
    ),
    BodyTypeQuizQuestion(
      id: 'fit_pref',
      title: 'Любимая посадка',
      subtitle: 'Как сидит одежда на тебе',
      options: [
        BodyTypeQuizOption(
          id: 'fit_fitted',
          label: 'По фигуре',
          hint: 'Приталенно',
        ),
        BodyTypeQuizOption(
          id: 'fit_balanced',
          label: 'Универсальная',
          hint: 'Не в обтяжку',
        ),
        BodyTypeQuizOption(
          id: 'fit_oversized',
          label: 'Свободная',
          hint: 'Oversize',
        ),
      ],
    ),
    BodyTypeQuizQuestion(
      id: 'height',
      title: 'Рост',
      subtitle: 'Для пропорций в советах',
      options: [
        BodyTypeQuizOption(
          id: 'height_petite',
          label: 'Ниже среднего',
        ),
        BodyTypeQuizOption(
          id: 'height_average',
          label: 'Средний',
        ),
        BodyTypeQuizOption(
          id: 'height_tall',
          label: 'Выше среднего',
        ),
      ],
    ),
  ];
}
