import 'package:equatable/equatable.dart';

import '../../../data/models/chat_message.dart';

class ChatState extends Equatable {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isRestoringHistory;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isRestoringHistory = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isRestoringHistory,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isRestoringHistory: isRestoringHistory ?? this.isRestoringHistory,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, isRestoringHistory, error];
}
