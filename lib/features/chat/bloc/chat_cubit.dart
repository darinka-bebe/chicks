import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/openai_chat_service.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/repositories/chat_history_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({
    OpenAiChatService? service,
    ChatHistoryRepository? historyRepository,
  })  : _service = service ?? OpenAiChatService(),
        _historyRepository = historyRepository ?? ChatHistoryRepository(),
        super(const ChatState(isRestoringHistory: true)) {
    _restoreHistory();
  }

  final OpenAiChatService _service;
  final ChatHistoryRepository _historyRepository;

  Future<void> _restoreHistory() async {
    try {
      final messages = await _historyRepository.loadMessages();
      if (isClosed) return;
      emit(
        ChatState(
          messages: messages,
          isRestoringHistory: false,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(const ChatState(isRestoringHistory: false));
    }
  }

  Future<void> _persistMessages(List<ChatMessage> messages) async {
    await _historyRepository.saveMessages(messages);
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isLoading || state.isRestoringHistory) {
      return;
    }

    final userMessage = ChatMessage.user(trimmed);
    final withUserMessage = [...state.messages, userMessage];

    emit(
      state.copyWith(
        messages: withUserMessage,
        isLoading: true,
        clearError: true,
      ),
    );
    await _persistMessages(withUserMessage);

    try {
      // Wardrobe context is loaded fresh from local storage on each request
      // inside OpenAiChatService.buildSystemMessages().
      final reply = await _service.completeConversation(withUserMessage);
      final withAssistant = [...withUserMessage, ChatMessage.assistant(reply)];

      if (isClosed) return;
      emit(
        state.copyWith(
          messages: withAssistant,
          isLoading: false,
        ),
      );
      await _persistMessages(withAssistant);
    } on OpenAiChatException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Не удалось отправить сообщение. Проверьте интернет.',
        ),
      );
    }
  }

  Future<void> clearChat() async {
    if (state.isLoading) return;

    await _historyRepository.clear();
    if (isClosed) return;
    emit(const ChatState());
  }

  void clearError() {
    if (state.error != null) {
      emit(state.copyWith(clearError: true));
    }
  }
}
