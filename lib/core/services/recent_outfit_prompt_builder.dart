import '../models/recent_outfit_signals.dart';

/// Tells the model not to repeat recent outfit combinations.
abstract final class RecentOutfitPromptBuilder {
  static String buildSystemSection(RecentOutfitSignals signals) {
    if (!signals.hasSignals) return '';

  final buffer = StringBuffer()
      ..writeln('РАЗНООБРАЗИЕ И АНТИ-ПОВТОР:')
      ..writeln(
        '- Не повторяй недавние сочетания вещей из истории чата и избранного.',
      );

    if (signals.recentItemIds.isNotEmpty) {
      buffer.writeln(
        '- Недавно уже использовались id: '
        '${signals.recentItemIds.take(10).join(', ')} — замени хотя бы 1–2 вещи.',
      );
    }

    buffer.writeln(
      '- Предложи свежий характер лука при том же запросе (другие цвета, слой или обувь).',
    );

    return buffer.toString().trim();
  }
}
