import 'package:flutter/material.dart';

import '../../../core/widgets/chicks_empty_state.dart';
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
    final (title, message, hint) = switch (reason) {
      WardrobeEmptyFilterReason.search => (
          'Ничего не найдено',
          'Попробуй другое слово — название, цвет или стиль',
          'Например: «белый», «casual», «уютный»',
        ),
      WardrobeEmptyFilterReason.favorites => (
          'Нет избранных вещей',
          'Отмечай ♥ на карточках — они появятся здесь',
          'Избранное хранится локально на устройстве',
        ),
      WardrobeEmptyFilterReason.filters => (
          'Нет вещей по фильтрам',
          'Измени категорию, сезон или стиль — или сбрось фильтры',
          null,
        ),
      WardrobeEmptyFilterReason.none => (
          'Пусто',
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
      actionLabel: 'Сбросить фильтры',
      onAction: onClearFilters,
    );
  }
}
