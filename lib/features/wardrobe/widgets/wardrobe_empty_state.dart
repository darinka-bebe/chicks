import 'package:flutter/material.dart';

import '../../../core/widgets/chicks_empty_state.dart';
import '../../../l10n/generated/app_localizations.dart';

class WardrobeEmptyState extends StatelessWidget {
  const WardrobeEmptyState({super.key, required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ChicksEmptyState(
      icon: Icons.checkroom_outlined,
      secondaryIcon: Icons.add_rounded,
      title: loc.wardrobeEmptyTitle,
      message: loc.wardrobeEmptyMessage,
      hint: loc.wardrobeEmptyHint,
      actionLabel: loc.wardrobeAddItem,
      onAction: onAddPressed,
    );
  }
}
