import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/stylist_suggestion_chips.dart';
import '../../../core/localization/outfit_display.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../data/models/favorite_outfit.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../chat/widgets/chat_ai_message_content.dart';
import '../../outfit_history/widgets/outfit_history_item_thumbnails.dart';
import '../../wardrobe/wardrobe_controller.dart';
import '../favorites_controller.dart';

class FavoriteOutfitDetailsScreen extends StatelessWidget {
  const FavoriteOutfitDetailsScreen({super.key, required this.outfit});

  final FavoriteOutfit outfit;

  Future<void> _confirmDelete(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(loc.favoriteDeleteTitle),
        content: Text(
          loc.favoriteDeleteBody(OutfitDisplay.favoriteTitle(outfit)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              loc.delete,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await context
        .read<FavoritesController>()
        .removeByContentHash(outfit.contentHash);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(loc.favoriteDeleted),
            behavior: SnackBarBehavior.floating,
          ),
        );
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final wardrobeItems = context.watch<WardrobeController>().items;
    final locale = Localizations.localeOf(context).toString();
    final dateLabel =
        DateFormat('d MMMM yyyy, HH:mm', locale).format(outfit.createdAt);

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
        title: Text(
          loc.favoriteOutfitTitle,
          style: const TextStyle(
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppBrandColors.iconBackground,
                  AppBrandColors.pink.withValues(alpha: 0.18),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (outfit.hasRecommendations) ...[
                  OutfitHistoryItemThumbnails(
                    recommendedItemIds: outfit.recommendedItemIds,
                    wardrobeItems: wardrobeItems,
                    height: 88,
                    maxVisible: 4,
                  ),
                  const SizedBox(height: 14),
                ],
                const Icon(
                  Icons.favorite_rounded,
                  color: AppBrandColors.pink,
                  size: 28,
                ),
                const SizedBox(height: 12),
                Text(
                  OutfitDisplay.favoriteTitle(outfit),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppBrandColors.title,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dateLabel,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (outfit.hasContext) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...outfit.moods.map(
                  (tag) => _ContextChip(StylistContextCatalog.displayMood(tag)),
                ),
                ...outfit.occasions.map(
                  (tag) => _ContextChip(
                    StylistContextCatalog.displayOccasion(tag),
                  ),
                ),
                ...outfit.weather.map(
                  (tag) => _ContextChip(
                    StylistContextCatalog.displayWeather(tag),
                  ),
                ),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ChatAiMessageContent(content: outfit.recommendation),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(loc.removeFromFavorites),
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
