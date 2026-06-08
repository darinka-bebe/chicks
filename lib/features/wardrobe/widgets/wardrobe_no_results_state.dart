import 'package:flutter/material.dart';

import '../../../core/widgets/chicks_empty_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/wardrobe_filter.dart';

class WardrobeNoResultsState extends StatelessWidget {
  const WardrobeNoResultsState({
    super.key,
    required this.reason,
    required this.onClearFilters,
  });

  final WardrobeEmptyFilterReason reason;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final (title, message, hint) = switch (reason) {
      WardrobeEmptyFilterReason.search => (
          loc.wardrobeNoResultsTitle,
          loc.wardrobeNoResultsMessage,
          loc.wardrobeNoResultsHint,
        ),
      WardrobeEmptyFilterReason.favorites => (
          loc.wardrobeNoFavoritesTitle,
          loc.wardrobeNoFavoritesMessage,
          loc.wardrobeNoFavoritesHint,
        ),
      WardrobeEmptyFilterReason.filters => (
          loc.wardrobeNoFilterTitle,
          loc.wardrobeNoFilterMessage,
          null,
        ),
      WardrobeEmptyFilterReason.none => (
          loc.wardrobeNoResultsTitle,
          '',
          null,
        ),
    };

    return ChicksEmptyState(
      icon: Icons.search_off_rounded,
      secondaryIcon: Icons.tune_rounded,
      title: title,
      message: message,
      hint: hint,
      actionLabel: loc.wardrobeFilterReset,
      onAction: onClearFilters,
    );
  }
}
