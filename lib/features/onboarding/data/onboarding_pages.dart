import 'package:flutter/material.dart';

import '../../../core/localization/app_locale.dart';

class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentIcon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final IconData accentIcon;
}

abstract final class OnboardingPages {
  static List<OnboardingPageData> get slides {
    if (AppLocale.isKazakh()) return _slidesKk;
    if (AppLocale.isRussian()) return _slidesRu;
    return _slidesEn;
  }

  static const _slidesRu = <OnboardingPageData>[
    OnboardingPageData(
      title: 'Рекомендации AI-стилиста',
      subtitle:
          'Получай персональные советы по стилю и готовые образы от умного ассистента Chicks.',
      icon: Icons.auto_awesome_rounded,
      accentIcon: Icons.chat_bubble_outline_rounded,
    ),
    OnboardingPageData(
      title: 'Образы из твоего гардероба',
      subtitle:
          'Стилист подбирает луки из вещей, которые уже есть у тебя — без случайных советов.',
      icon: Icons.checkroom_outlined,
      accentIcon: Icons.style_outlined,
    ),
    OnboardingPageData(
      title: 'Сохраняй любимые луки',
      subtitle:
          'Понравился образ? Сохрани в избранное и возвращайся к нему в любой момент.',
      icon: Icons.favorite_rounded,
      accentIcon: Icons.bookmark_outline_rounded,
    ),
    OnboardingPageData(
      title: 'Твой fashion-ассистент',
      subtitle:
          'Настроение, погода и повод — Chicks учитывает контекст и объясняет, почему образ работает.',
      icon: Icons.spa_outlined,
      accentIcon: Icons.wb_sunny_outlined,
    ),
  ];

  static const _slidesKk = <OnboardingPageData>[
    OnboardingPageData(
      title: 'AI стилист ұсыныстары',
      subtitle:
          'Chicks ақылды көмекшісінен жеке стиль кеңестері мен дайын образдар алыңыз.',
      icon: Icons.auto_awesome_rounded,
      accentIcon: Icons.chat_bubble_outline_rounded,
    ),
    OnboardingPageData(
      title: 'Гардеробыңыздан образдар',
      subtitle:
          'Стилист сізде бар заттардан образ жасайды — кездейсоқ кеңес емес.',
      icon: Icons.checkroom_outlined,
      accentIcon: Icons.style_outlined,
    ),
    OnboardingPageData(
      title: 'Ұнаған образдарды сақтаңыз',
      subtitle:
          'Образ ұнады ма? Таңдаулыларға сақтап, кез келген уақытта оралыңыз.',
      icon: Icons.favorite_rounded,
      accentIcon: Icons.bookmark_outline_rounded,
    ),
    OnboardingPageData(
      title: 'Сіздің fashion көмекшіңіз',
      subtitle:
          'Көңіл-күй, ауа райы және повод — Chicks контекстті ескереді және неге сәйкес екенін түсіндіреді.',
      icon: Icons.spa_outlined,
      accentIcon: Icons.wb_sunny_outlined,
    ),
  ];

  static const _slidesEn = <OnboardingPageData>[
    OnboardingPageData(
      title: 'AI stylist recommendations',
      subtitle:
          'Get personal style tips and ready-made looks from the smart Chicks assistant.',
      icon: Icons.auto_awesome_rounded,
      accentIcon: Icons.chat_bubble_outline_rounded,
    ),
    OnboardingPageData(
      title: 'Looks from your wardrobe',
      subtitle:
          'The stylist builds outfits from items you already own — no random advice.',
      icon: Icons.checkroom_outlined,
      accentIcon: Icons.style_outlined,
    ),
    OnboardingPageData(
      title: 'Save your favorite looks',
      subtitle:
          'Love an outfit? Save it to favorites and come back to it anytime.',
      icon: Icons.favorite_rounded,
      accentIcon: Icons.bookmark_outline_rounded,
    ),
    OnboardingPageData(
      title: 'Your fashion assistant',
      subtitle:
          'Mood, weather, and occasion — Chicks uses context and explains why a look works.',
      icon: Icons.spa_outlined,
      accentIcon: Icons.wb_sunny_outlined,
    ),
  ];
}
