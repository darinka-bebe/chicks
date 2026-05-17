import 'package:flutter/material.dart';

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
  static const slides = [
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
}
