import 'package:flutter/material.dart';

import '../../../data/models/chat_message.dart';
import 'chat_message_list_item.dart';
import 'chat_typing_indicator.dart';

/// Lazy chat list — isolated from weather/app-bar rebuilds.
class ChatMessagesList extends StatelessWidget {
  const ChatMessagesList({
    super.key,
    required this.scrollController,
    required this.messages,
    required this.isLoading,
    required this.onToggleFavorite,
    this.onToggleDislike,
  });

  final ScrollController scrollController;
  final List<ChatMessage> messages;
  final bool isLoading;
  final void Function(ChatMessage message, String? userPrompt)? onToggleFavorite;
  final void Function(ChatMessage message, String? userPrompt)? onToggleDislike;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      cacheExtent: 180,
      itemCount: messages.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= messages.length) {
          return const ChatTypingIndicator();
        }

        final message = messages[index];
        final isAssistant = message.role == ChatRole.assistant;
        String? userPrompt;
        if (isAssistant && index > 0) {
          final previous = messages[index - 1];
          if (previous.role == ChatRole.user) {
            userPrompt = previous.content;
          }
        }

        return RepaintBoundary(
          child: ChatMessageListItem(
            key: ValueKey<String>(message.id),
            message: message,
            userPrompt: userPrompt,
            onToggleFavorite: isAssistant ? onToggleFavorite : null,
            onToggleDislike: isAssistant ? onToggleDislike : null,
          ),
        );
      },
    );
  }
}
