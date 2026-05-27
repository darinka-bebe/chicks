import 'package:flutter/material.dart';

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
  static const slides = <TutorialPageData>[
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
}
