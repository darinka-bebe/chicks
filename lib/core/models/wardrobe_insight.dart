import 'package:flutter/material.dart';

import '../localization/app_locale.dart';

/// A single wardrobe balance / gap insight for the UI.
enum WardrobeInsightKind {
  gap,
  balance,
  color,
  style,
  highlight,
  tip,
  silhouette,
  recommendation,
}

class WardrobeInsight {
  const WardrobeInsight({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    this.isAiEnhanced = false,
  });

  final String id;
  final String title;
  final String body;
  final WardrobeInsightKind kind;
  final bool isAiEnhanced;

  IconData get icon => switch (kind) {
        WardrobeInsightKind.gap => Icons.add_circle_outline_rounded,
        WardrobeInsightKind.balance => Icons.balance_rounded,
        WardrobeInsightKind.color => Icons.palette_outlined,
        WardrobeInsightKind.style => Icons.style_outlined,
        WardrobeInsightKind.highlight => Icons.auto_awesome_outlined,
        WardrobeInsightKind.tip => Icons.lightbulb_outline_rounded,
        WardrobeInsightKind.silhouette => Icons.accessibility_new_rounded,
        WardrobeInsightKind.recommendation => Icons.tips_and_updates_outlined,
      };

  String get categoryLabel => switch (kind) {
        WardrobeInsightKind.style =>
          AppLocale.pick(ru: 'Стиль', en: 'Style', kk: 'Стиль'),
        WardrobeInsightKind.color =>
          AppLocale.pick(ru: 'Палитра', en: 'Palette', kk: 'Палитра'),
        WardrobeInsightKind.balance =>
          AppLocale.pick(ru: 'Баланс', en: 'Balance', kk: 'Баланс'),
        WardrobeInsightKind.silhouette =>
          AppLocale.pick(ru: 'Силуэт', en: 'Silhouette', kk: 'Силуэт'),
        WardrobeInsightKind.recommendation =>
          AppLocale.pick(ru: 'Совет', en: 'Tip', kk: 'Кеңес'),
        WardrobeInsightKind.gap =>
          AppLocale.pick(ru: 'Пробел', en: 'Gap', kk: 'Бос орын'),
        WardrobeInsightKind.highlight =>
          AppLocale.pick(ru: 'Акцент', en: 'Highlight', kk: 'Акцент'),
        WardrobeInsightKind.tip =>
          AppLocale.pick(ru: 'Инсайт', en: 'Insight', kk: 'Инсайт'),
      };
}
