import 'package:flutter/material.dart';

import '../../../core/localization/app_locale.dart';

class TutorialPageData {
  const TutorialPageData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentIcon,
    this.hint,
    this.gradientColors,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final IconData accentIcon;
  final String? hint;
  final List<Color>? gradientColors;
}

abstract final class TutorialPages {
  static List<TutorialPageData> get slides =>
      AppLocale.isRussian() ? _slidesRu : _slidesEn;

  static const _slidesRu = <TutorialPageData>[
    TutorialPageData(
      title: 'Добро пожаловать в Chicks',
      subtitle:
          'Твой персональный AI-стилист — образы, которые подходят именно тебе',
      icon: Icons.auto_awesome_rounded,
      accentIcon: Icons.favorite_rounded,
    ),
    TutorialPageData(
      title: 'Собери цифровой гардероб',
      subtitle:
          'Добавляй вещи — стилист подберёт луки из того, что уже есть у тебя',
      icon: Icons.checkroom_rounded,
      accentIcon: Icons.add_circle_outline_rounded,
      hint: 'Добавь хотя бы 5 вещей для лучших рекомендаций',
      gradientColors: [Color(0xFFFFE4F2), Color(0xFFFFF0F5)],
    ),
    TutorialPageData(
      title: 'Умный стилист учитывает всё',
      subtitle:
          'Погоду, тип фигуры и цветотип — для образов, которые работают на тебя',
      icon: Icons.wb_sunny_outlined,
      accentIcon: Icons.palette_outlined,
      gradientColors: [Color(0xFFFFD6E8), Color(0xFFFFF0F5)],
    ),
    TutorialPageData(
      title: 'Персональные образы каждый день',
      subtitle:
          'Спроси стилиста — и получи готовый лук из своего гардероба',
      icon: Icons.style_outlined,
      accentIcon: Icons.chat_bubble_outline_rounded,
      hint: 'Попробуй: «Уютный образ на дождливый день»',
      gradientColors: [Color(0xFFFFE4F2), Color(0xFFFFFBFE)],
    ),
    TutorialPageData(
      title: 'Сохраняй и вдохновляйся',
      subtitle:
          'Любимые образы и стиль-подсказки всегда под рукой в профиле',
      icon: Icons.bookmark_rounded,
      accentIcon: Icons.insights_outlined,
      hint: 'Рекомендации улучшаются с каждой новой вещью',
      gradientColors: [Color(0xFFFFD6E8), Color(0xFFFFF0F5)],
    ),
  ];

  static const _slidesEn = <TutorialPageData>[
    TutorialPageData(
      title: 'Welcome to Chicks',
      subtitle: 'Your personal AI stylist — looks made just for you',
      icon: Icons.auto_awesome_rounded,
      accentIcon: Icons.favorite_rounded,
    ),
    TutorialPageData(
      title: 'Build your digital wardrobe',
      subtitle:
          'Add items — your stylist will create looks from what you already own',
      icon: Icons.checkroom_rounded,
      accentIcon: Icons.add_circle_outline_rounded,
      hint: 'Add at least 5 items for better recommendations',
      gradientColors: [Color(0xFFFFE4F2), Color(0xFFFFF0F5)],
    ),
    TutorialPageData(
      title: 'A stylist that knows the context',
      subtitle:
          'Weather, body shape, and color type — outfits that work for you',
      icon: Icons.wb_sunny_outlined,
      accentIcon: Icons.palette_outlined,
      gradientColors: [Color(0xFFFFD6E8), Color(0xFFFFF0F5)],
    ),
    TutorialPageData(
      title: 'Personal looks every day',
      subtitle: 'Ask the stylist for a ready look from your wardrobe',
      icon: Icons.style_outlined,
      accentIcon: Icons.chat_bubble_outline_rounded,
      hint: 'Try: "Cozy outfit for a rainy day"',
      gradientColors: [Color(0xFFFFE4F2), Color(0xFFFFFBFE)],
    ),
    TutorialPageData(
      title: 'Save and get inspired',
      subtitle: 'Favorite looks and style tips always in your profile',
      icon: Icons.bookmark_rounded,
      accentIcon: Icons.insights_outlined,
      hint: 'Recommendations improve with every new item',
      gradientColors: [Color(0xFFFFD6E8), Color(0xFFFFF0F5)],
    ),
  ];
}
