import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/chat_message.dart';
import '../../favorites/favorites_controller.dart';
import '../../preferences/outfit_preferences_controller.dart';
import 'chat_message_bubble.dart';

class _MessageFeedbackState {
  const _MessageFeedbackState({
    required this.isFavorite,
    required this.isDisliked,
  });

  final bool isFavorite;
  final bool isDisliked;

  @override
  bool operator ==(Object other) {
    return other is _MessageFeedbackState &&
        other.isFavorite == isFavorite &&
        other.isDisliked == isDisliked;
  }

  @override
  int get hashCode => Object.hash(isFavorite, isDisliked);
}

/// One chat row — isolates favorite/dislike rebuilds from the rest of the list.
class ChatMessageListItem extends StatelessWidget {
  const ChatMessageListItem({
    super.key,
    required this.message,
    this.userPrompt,
    this.onToggleFavorite,
    this.onToggleDislike,
  });

  final ChatMessage message;
  final String? userPrompt;
  final void Function(ChatMessage message, String? userPrompt)? onToggleFavorite;
  final void Function(ChatMessage message, String? userPrompt)? onToggleDislike;

  @override
  Widget build(BuildContext context) {
    final isAssistant = message.role == ChatRole.assistant;
    final hasFeedback =
        isAssistant && (onToggleFavorite != null || onToggleDislike != null);

    if (!hasFeedback) {
      return ChatMessageBubble(message: message);
    }

    return Selector2<FavoritesController, OutfitPreferencesController,
        _MessageFeedbackState>(
      selector: (_, favorites, preferences) => _MessageFeedbackState(
        isFavorite: favorites.isSavedRecommendation(message.content),
        isDisliked: preferences.isDislikedRecommendation(message.content),
      ),
      builder: (context, feedback, _) {
        return ChatMessageBubble(
          message: message,
          isFavorite: feedback.isFavorite,
          isDisliked: feedback.isDisliked,
          onToggleFavorite: onToggleFavorite == null
              ? null
              : () => onToggleFavorite!(message, userPrompt),
          onToggleDislike: onToggleDislike == null
              ? null
              : () => onToggleDislike!(message, userPrompt),
        );
      },
    );
  }
}
