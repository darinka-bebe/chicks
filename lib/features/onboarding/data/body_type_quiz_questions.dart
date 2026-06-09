import '../../../core/localization/app_locale.dart';

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
  static List<BodyTypeQuizQuestion> get questions {
    if (AppLocale.isKazakh()) return _questionsKk;
    if (AppLocale.isRussian()) return _questionsRu;
    return _questionsEn;
  }

  static const _questionsRu = <BodyTypeQuizQuestion>[
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

  static const _questionsEn = <BodyTypeQuizQuestion>[
    BodyTypeQuizQuestion(
      id: 'body_shape',
      title: 'Which silhouette is closest?',
      subtitle: 'Look at your shoulders, waist, and hips',
      options: [
        BodyTypeQuizOption(
          id: 'shape_hourglass',
          label: 'Hourglass',
          hint: 'Waist narrower than shoulders and hips',
        ),
        BodyTypeQuizOption(
          id: 'shape_pear',
          label: 'Pear',
          hint: 'Lower body wider than upper',
        ),
        BodyTypeQuizOption(
          id: 'shape_rectangle',
          label: 'Rectangle',
          hint: 'Almost a straight line',
        ),
        BodyTypeQuizOption(
          id: 'shape_apple',
          label: 'Apple',
          hint: 'Volume in the midsection',
        ),
        BodyTypeQuizOption(
          id: 'shape_inverted',
          label: 'Inverted triangle',
          hint: 'Shoulders wider than hips',
        ),
      ],
    ),
    BodyTypeQuizQuestion(
      id: 'shoulder_hips',
      title: 'Shoulders and hips',
      subtitle: 'Where is wider — top or bottom?',
      options: [
        BodyTypeQuizOption(
          id: 'prop_narrow_shoulders',
          label: 'Narrower on top',
          hint: 'Shoulders narrower than hips',
        ),
        BodyTypeQuizOption(
          id: 'prop_balanced',
          label: 'Balanced',
          hint: 'Shoulders ≈ hips',
        ),
        BodyTypeQuizOption(
          id: 'prop_broad_shoulders',
          label: 'Broader on top',
          hint: 'Shoulders wider than hips',
        ),
        BodyTypeQuizOption(
          id: 'prop_wide_hips',
          label: 'Wider on bottom',
          hint: 'Hips noticeably wider',
        ),
      ],
    ),
    BodyTypeQuizQuestion(
      id: 'waist',
      title: 'Waistline',
      subtitle: 'How defined is the curve?',
      options: [
        BodyTypeQuizOption(
          id: 'waist_defined',
          label: 'Defined waist',
          hint: 'Clear cinch',
        ),
        BodyTypeQuizOption(
          id: 'waist_soft',
          label: 'Soft line',
          hint: 'Smooth transition',
        ),
        BodyTypeQuizOption(
          id: 'waist_straight',
          label: 'Almost straight',
          hint: 'Little curve',
        ),
      ],
    ),
    BodyTypeQuizQuestion(
      id: 'fit_pref',
      title: 'Preferred fit',
      subtitle: 'How clothes sit on you',
      options: [
        BodyTypeQuizOption(
          id: 'fit_fitted',
          label: 'Fitted',
          hint: 'Tailored',
        ),
        BodyTypeQuizOption(
          id: 'fit_balanced',
          label: 'Classic',
          hint: 'Not too tight',
        ),
        BodyTypeQuizOption(
          id: 'fit_oversized',
          label: 'Relaxed',
          hint: 'Oversized',
        ),
      ],
    ),
    BodyTypeQuizQuestion(
      id: 'height',
      title: 'Height',
      subtitle: 'For proportion tips in styling advice',
      options: [
        BodyTypeQuizOption(
          id: 'height_petite',
          label: 'Below average',
        ),
        BodyTypeQuizOption(
          id: 'height_average',
          label: 'Average',
        ),
        BodyTypeQuizOption(
          id: 'height_tall',
          label: 'Above average',
        ),
      ],
    ),
  ];

  static const _questionsKk = <BodyTypeQuizQuestion>[
    BodyTypeQuizQuestion(
      id: 'body_shape',
      title: 'Қай силуэт жақын?',
      subtitle: 'Иық, бел және жамбас пропорцияларына қараңыз',
      options: [
        BodyTypeQuizOption(
          id: 'shape_hourglass',
          label: 'Құм сағаты',
          hint: 'Бел иық пен жамбастан тар',
        ),
        BodyTypeQuizOption(
          id: 'shape_pear',
          label: 'Алмұрт',
          hint: 'Төменгі бөлігі жоғарыдан кең',
        ),
        BodyTypeQuizOption(
          id: 'shape_rectangle',
          label: 'Төртбұрыш',
          hint: 'Өте түзу сызық',
        ),
        BodyTypeQuizOption(
          id: 'shape_apple',
          label: 'Алма',
          hint: 'Орталықта көлем',
        ),
        BodyTypeQuizOption(
          id: 'shape_inverted',
          label: 'Төңкерілген үшбұрыш',
          hint: 'Иық жамбастан кең',
        ),
      ],
    ),
    BodyTypeQuizQuestion(
      id: 'shoulder_hips',
      title: 'Иық және жамбас',
      subtitle: 'Қай жақ кеңірек — жоғары ма, төмен бе?',
      options: [
        BodyTypeQuizOption(
          id: 'prop_narrow_shoulders',
          label: 'Жоғары тар',
          hint: 'Иық жамбастан тар',
        ),
        BodyTypeQuizOption(
          id: 'prop_balanced',
          label: 'Теңгерімді',
          hint: 'Иық ≈ жамбас',
        ),
        BodyTypeQuizOption(
          id: 'prop_broad_shoulders',
          label: 'Жоғары кең',
          hint: 'Иық жамбастан кең',
        ),
        BodyTypeQuizOption(
          id: 'prop_wide_hips',
          label: 'Төмен кең',
          hint: 'Жамбас айқын кеңірек',
        ),
      ],
    ),
    BodyTypeQuizQuestion(
      id: 'waist',
      title: 'Бел сызығы',
      subtitle: 'Иілгіштық қаншалықты айқын?',
      options: [
        BodyTypeQuizOption(
          id: 'waist_defined',
          label: 'Айқын бел',
          hint: 'Нақты тарылу',
        ),
        BodyTypeQuizOption(
          id: 'waist_soft',
          label: 'Жұмсақ сызық',
          hint: 'Байсалды өту',
        ),
        BodyTypeQuizOption(
          id: 'waist_straight',
          label: 'Өте түзу',
          hint: 'Аз иілгі',
        ),
      ],
    ),
    BodyTypeQuizQuestion(
      id: 'fit_pref',
      title: 'Қалаулы отырыс',
      subtitle: 'Киім сізге қалай отырады',
      options: [
        BodyTypeQuizOption(
          id: 'fit_fitted',
          label: 'Денеге сай',
          hint: 'Тарылған',
        ),
        BodyTypeQuizOption(
          id: 'fit_balanced',
          label: 'Классикалық',
          hint: 'Тым тар емес',
        ),
        BodyTypeQuizOption(
          id: 'fit_oversized',
          label: 'Бос',
          hint: 'Oversize',
        ),
      ],
    ),
    BodyTypeQuizQuestion(
      id: 'height',
      title: 'Бой',
      subtitle: 'Кеңес үшін пропорциялар',
      options: [
        BodyTypeQuizOption(
          id: 'height_petite',
          label: 'Орташа төмен',
        ),
        BodyTypeQuizOption(
          id: 'height_average',
          label: 'Орташа',
        ),
        BodyTypeQuizOption(
          id: 'height_tall',
          label: 'Орташа жоғары',
        ),
      ],
    ),
  ];
}
