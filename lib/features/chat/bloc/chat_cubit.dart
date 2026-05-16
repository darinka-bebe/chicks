import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/openai_chat_service.dart';
import '../../../data/models/chat_message.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({OpenAiChatService? service})
      : _service = service ?? OpenAiChatService(),
        super(const ChatState());

  final OpenAiChatService _service;

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    final userMessage = ChatMessage.user(trimmed);
    final updatedMessages = [...state.messages, userMessage];

    emit(
      state.copyWith(
        messages: updatedMessages,
        isLoading: true,
        clearError: true,
      ),
    );

    try {
      final reply = await _service.completeConversation(updatedMessages);
      emit(
        state.copyWith(
          messages: [...state.messages, ChatMessage.assistant(reply)],
          isLoading: false,
        ),
      );
    } on OpenAiChatException catch (e) {
      emit(state.copyWith(isLoading: false, error: e.message));
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Не удалось отправить сообщение. Проверьте интернет.',
        ),
      );
    }
  }

  void clearError() {
    if (state.error != null) {
      emit(state.copyWith(clearError: true));
    }
  }
}
