import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/chat_message.dart';
import '../../favorites/favorites_controller.dart';
import 'chat_message_bubble.dart';

/// One chat row — isolates favorite-state rebuilds from the rest of the list.
class ChatMessageListItem extends StatelessWidget {
  const ChatMessageListItem({
    super.key,
    required this.message,
    this.userPrompt,
    this.onToggleFavorite,
  });

  final ChatMessage message;
  final String? userPrompt;
  final void Function(ChatMessage message, String? userPrompt)? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final isAssistant = message.role == ChatRole.assistant;

    if (!isAssistant || onToggleFavorite == null) {
      return ChatMessageBubble(message: message);
    }

    return Selector<FavoritesController, bool>(
      selector: (_, favorites) =>
          favorites.isSavedRecommendation(message.content),
      builder: (context, isFavorite, _) {
        return ChatMessageBubble(
          message: message,
          isFavorite: isFavorite,
          onToggleFavorite: () => onToggleFavorite!(message, userPrompt),
        );
      },
    );
  }
}
