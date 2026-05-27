import 'package:flutter/material.dart';

import '../../../core/widgets/chicks_empty_state.dart';

class WardrobeEmptyState extends StatelessWidget {
  const WardrobeEmptyState({super.key, required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return ChicksEmptyState(
      icon: Icons.checkroom_outlined,
      secondaryIcon: Icons.add_rounded,
      title: 'Гардероб пока пуст',
      message:
          'Добавь свои вещи, чтобы AI мог собирать персональные образы',
      hint: 'Добавь хотя бы 5 вещей — рекомендации станут точнее',
      actionLabel: 'Добавить вещь',
      onAction: onAddPressed,
    );
  }
}
