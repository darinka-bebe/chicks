import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../data/models/outfit_history_entry.dart';
import '../../chat/widgets/chat_ai_message_content.dart';
import '../../chat/widgets/chat_weather_banner.dart';
import '../../chat/widgets/outfit_recommendation_row.dart';
import '../../chat/widgets/wardrobe_snapshot_scope.dart';
import '../outfit_history_controller.dart';
import '../widgets/outfit_history_item_thumbnails.dart';

class OutfitHistoryDetailsScreen extends StatelessWidget {
  const OutfitHistoryDetailsScreen({super.key, required this.entry});

  final OutfitHistoryEntry entry;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Удалить из истории?'),
        content: Text('«${entry.title}» будет удалён из истории образов.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await context.read<OutfitHistoryController>().deleteEntry(entry.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Удалено из истории'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      context.pop(true);
    }
  }

  void _openInChat(BuildContext context) {
    context.pop();
    context.pushNamed(RouteNames.chatName, extra: entry);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        DateFormat('d MMMM yyyy, HH:mm').format(entry.createdAt);
    final snapshot = WardrobeSnapshotScope.maybeOf(context);

    return Scaffold(
      backgroundColor: AppBrandColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppBrandColors.pink,
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Образ',
          style: TextStyle(
            color: AppBrandColors.pink,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppBrandColors.pink.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (snapshot != null)
                  OutfitHistoryItemThumbnails(
                    recommendedItemIds: entry.recommendedItemIds,
                    wardrobeItems: snapshot.items,
                    height: 88,
                    maxVisible: 4,
                  )
                else
                  const SizedBox(height: 72),
                const SizedBox(height: 14),
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppBrandColors.title,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dateLabel,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                if (entry.userPrompt.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Запрос: ${entry.userPrompt}',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (entry.weatherLabel != null && entry.weatherLabel!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ChatWeatherBanner(label: entry.weatherLabel, compact: false),
          ],
          if (entry.hasContext) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...entry.moods.map((tag) => _ContextChip(tag)),
                ...entry.occasions.map((tag) => _ContextChip(tag)),
                ...entry.weather.map((tag) => _ContextChip(tag)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppBrandColors.pink.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Рекомендация стилиста',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppBrandColors.pink,
                  ),
                ),
                const SizedBox(height: 10),
                ChatAiMessageContent(content: entry.aiResponseText),
                if (entry.hasRecommendations && snapshot != null) ...[
                  OutfitRecommendationRow(
                    recommendedItemIds: entry.recommendedItemIds,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _openInChat(context),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
            label: const Text('Открыть в чате'),
            style: FilledButton.styleFrom(
              backgroundColor: AppBrandColors.pink,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Удалить из истории'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextChip extends StatelessWidget {
  const _ContextChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppBrandColors.iconBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppBrandColors.pink,
        ),
      ),
    );
  }
}
