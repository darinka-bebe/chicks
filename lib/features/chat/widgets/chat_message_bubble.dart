import 'package:flutter/material.dart';

import '../../../core/theme/app_brand_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../data/models/chat_message.dart';
import 'chat_ai_message_content.dart';
import 'chat_weather_banner.dart';
import 'outfit_preview_metrics.dart';
import 'outfit_recommendation_row.dart';
import '../../../core/services/outfit_why_section_parser.dart';
import 'outfit_why_card.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.isFavorite = false,
    this.isDisliked = false,
    this.onToggleFavorite,
    this.onToggleDislike,
  });

  final ChatMessage message;
  final bool isFavorite;
  final bool isDisliked;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onToggleDislike;

  bool get _isUser => message.role == ChatRole.user;

  static double _maxBubbleWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width * 0.84;

  @override
  Widget build(BuildContext context) {
    final maxWidth = _maxBubbleWidth(context);

    return RepaintBoundary(
      child: Align(
        alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(maxWidth: maxWidth),
          clipBehavior: _isUser ? Clip.none : Clip.antiAlias,
          padding: EdgeInsets.symmetric(
            horizontal: _isUser ? 16 : 0,
            vertical: _isUser ? 12 : 14,
          ),
          decoration: BoxDecoration(
            color:
                _isUser ? AppBrandColors.userBubble : AppBrandColors.aiBubble,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(_isUser ? 20 : 6),
              bottomRight: Radius.circular(_isUser ? 6 : 20),
            ),
            border: _isUser
                ? null
                : Border.all(
                    color: AppBrandColors.pink.withValues(alpha: 0.08),
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isUser ? 0.06 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: _isUser ? _buildUserText() : _buildAiContent(context),
        ),
      ),
    );
  }

  Widget _buildUserText() {
    return Text(
      message.content,
      style: const TextStyle(
        fontSize: 15,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    );
  }

  Widget _buildAiContent(BuildContext context) {
    final loc = AppLocalizations.of(context);
    const contentPadding = EdgeInsets.symmetric(
      horizontal: OutfitPreviewMetrics.chatBubbleHorizontalPadding,
    );

    final parsed = OutfitWhySectionParser.parse(message.content);
    final hasOutfitCards = message.recommendedItemIds.isNotEmpty;
    var displayBody = parsed.hasWhySection ? parsed.body : message.content;
    if (hasOutfitCards) {
      displayBody =
          OutfitWhySectionParser.compactBodyWhenOutfitCardsShown(displayBody);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: contentPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppBrandColors.iconBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 15,
                      color: AppBrandColors.pink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.stylistLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (onToggleDislike != null)
                    _DislikeToggleButton(
                      isDisliked: isDisliked,
                      onPressed: onToggleDislike!,
                    ),
                  if (onToggleFavorite != null) ...[
                    if (onToggleDislike != null) const SizedBox(width: 2),
                    _FavoriteToggleButton(
                      isFavorite: isFavorite,
                      onPressed: onToggleFavorite!,
                    ),
                  ],
                ],
              ),
              if (message.weatherLabel != null &&
                  message.weatherLabel!.isNotEmpty)
                ChatWeatherBanner(
                  label: message.weatherLabel,
                  compact: true,
                ),
              if (displayBody.isNotEmpty) ...[
                const SizedBox(height: 10),
                ChatAiMessageContent(content: displayBody),
              ],
              if (parsed.hasWhySection)
                OutfitWhyCard(bullets: parsed.whyBullets),
            ],
          ),
        ),
        if (message.recommendedItemIds.isNotEmpty)
          OutfitRecommendationRow(
            key: ValueKey('outfit-${message.id}'),
            recommendedItemIds: message.recommendedItemIds,
          ),
      ],
    );
  }
}

class _DislikeToggleButton extends StatelessWidget {
  const _DislikeToggleButton({
    required this.isDisliked,
    required this.onPressed,
  });

  final bool isDisliked;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: isDisliked ? loc.removeDislike : loc.dislikeOutfit,
      child: IconButton(
        onPressed: onPressed,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        tooltip: isDisliked ? loc.removeDislike : loc.dislikeOutfit,
        icon: Icon(
          isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
          size: 21,
          color: isDisliked ? Colors.grey[700] : Colors.grey[500],
        ),
      ),
    );
  }
}

class _FavoriteToggleButton extends StatelessWidget {
  const _FavoriteToggleButton({
    required this.isFavorite,
    required this.onPressed,
  });

  final bool isFavorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: isFavorite ? loc.removeFromFavorites : loc.saveOutfit,
      child: IconButton(
        onPressed: onPressed,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        tooltip: isFavorite ? loc.removeFromFavorites : loc.saveOutfit,
        icon: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 22,
          color: AppBrandColors.pink,
        ),
      ),
    );
  }
}
