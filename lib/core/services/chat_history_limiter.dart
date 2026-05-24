import '../../data/models/chat_message.dart';

/// Trims chat history before sending to OpenAI to control token usage.
abstract final class ChatHistoryLimiter {
  static const maxMessages = 12;
  static const maxAssistantChars = 900;

  static List<ChatMessage> trimForApi(List<ChatMessage> history) {
    if (history.length <= maxMessages) {
      return _truncateAssistantBodies(history);
    }

    return _truncateAssistantBodies(
      history.sublist(history.length - maxMessages),
    );
  }

  static List<ChatMessage> _truncateAssistantBodies(List<ChatMessage> messages) {
    return messages.map((message) {
      if (message.role != ChatRole.assistant) return message;
      if (message.content.length <= maxAssistantChars) return message;

      final trimmed =
          '${message.content.substring(0, maxAssistantChars).trim()}…';
      return ChatMessage(
        id: message.id,
        role: message.role,
        content: trimmed,
        createdAt: message.createdAt,
        recommendedItemIds: message.recommendedItemIds,
        weatherLabel: message.weatherLabel,
      );
    }).toList();
  }
}
