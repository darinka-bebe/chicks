import 'package:flutter/material.dart';

/// A single wardrobe balance / gap insight for the UI.
enum WardrobeInsightKind {
  gap,
  balance,
  color,
  style,
  highlight,
  tip,
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
      };
}
