import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/openai_chat_service.dart';
import '../../../core/services/weather/weather_repository.dart';
import '../../../core/services/wardrobe_ai_context.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/chat_message.dart';
import '../../../core/services/outfit_history_factory.dart';
import '../../../data/models/outfit_history_entry.dart';
import '../../../data/repositories/chat_history_repository.dart';
import '../../../data/repositories/outfit_history_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({
    OpenAiChatService? service,
    ChatHistoryRepository? historyRepository,
    WeatherRepository? weatherRepository,
    OutfitHistoryRepository? outfitHistoryRepository,
  })  : _service = service ?? OpenAiChatService(),
        _historyRepository = historyRepository ?? ChatHistoryRepository(),
        _weatherRepository = weatherRepository ?? WeatherRepository.instance,
        _outfitHistoryRepository =
            outfitHistoryRepository ?? OutfitHistoryRepository.instance,
        super(const ChatState(isRestoringHistory: true)) {
    _restoreHistory();
  }

  final OpenAiChatService _service;
  final ChatHistoryRepository _historyRepository;
  final WeatherRepository _weatherRepository;
  final OutfitHistoryRepository _outfitHistoryRepository;

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
      await refreshWeather();
    } catch (_) {
      if (isClosed) return;
      emit(const ChatState(isRestoringHistory: false));
      await refreshWeather();
    }
  }

  Future<void> refreshWeather({bool forceRefresh = false}) async {
    if (isClosed) return;

    final weather = await _weatherRepository.getCurrent(
      forceRefresh: forceRefresh,
    );

    if (isClosed) return;

    final next = weather.isAvailable ? weather : null;
    if (!forceRefresh && next == state.currentWeather) return;

    emit(
      state.copyWith(
        currentWeather: next,
        isLoadingWeather: false,
      ),
    );
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
      final weather = await _weatherRepository.getCurrent(forceRefresh: true);

      AppLogger.debug(
        'ChatCubit: AI request wardrobeRevision='
        '${WardrobeAiContext.instance.revision} '
        'weather=${weather.isAvailable ? weather.compactUiLabel : "n/a"}',
      );

      final reply = await _service.completeConversation(
        withUserMessage,
        liveWeather: weather,
      );

      final weatherLabel =
          weather.isAvailable ? weather.compactUiLabel : null;

      final assistantMessage = ChatMessage.assistant(
        reply.message,
        recommendedItemIds: reply.recommendedItemIds,
        weatherLabel: weatherLabel,
      );

      final withAssistant = [...withUserMessage, assistantMessage];

      if (isClosed) return;
      emit(
        state.copyWith(
          messages: withAssistant,
          isLoading: false,
          currentWeather: weather.isAvailable ? weather : state.currentWeather,
        ),
      );
      await _persistMessages(withAssistant);

      if (reply.hasRecommendations) {
        await _recordOutfitHistory(
          userPrompt: trimmed,
          assistantMessage: assistantMessage,
        );
      }
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

  Future<void> _recordOutfitHistory({
    required String userPrompt,
    required ChatMessage assistantMessage,
  }) async {
    try {
      final entry = OutfitHistoryFactory.fromStylistExchange(
        assistantMessageId: assistantMessage.id,
        userPrompt: userPrompt,
        aiResponseText: assistantMessage.content,
        recommendedItemIds: assistantMessage.recommendedItemIds,
        weatherLabel: assistantMessage.weatherLabel,
        createdAt: assistantMessage.createdAt,
      );
      await _outfitHistoryRepository.addEntry(entry);
    } catch (e, stack) {
      AppLogger.error(
        'ChatCubit: failed to save outfit history',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Appends a history exchange to the active chat (or focuses if present).
  Future<void> openOutfitFromHistory(OutfitHistoryEntry entry) async {
    if (state.isRestoringHistory) return;

    final hasAssistant =
        state.messages.any((message) => message.id == entry.id);
    if (hasAssistant) return;

    final userMessage = ChatMessage(
      id: '${entry.id}_user',
      role: ChatRole.user,
      content: entry.userPrompt.isNotEmpty
          ? entry.userPrompt
          : 'Покажи этот образ снова',
      createdAt: entry.createdAt.subtract(const Duration(milliseconds: 1)),
    );

    final assistantMessage = ChatMessage(
      id: entry.id,
      role: ChatRole.assistant,
      content: entry.aiResponseText,
      createdAt: entry.createdAt,
      recommendedItemIds: entry.recommendedItemIds,
      weatherLabel: entry.weatherLabel,
    );

    final updated = [...state.messages, userMessage, assistantMessage];
    emit(state.copyWith(messages: updated, clearError: true));
    await _persistMessages(updated);
  }

  Future<void> clearChat() async {
    if (state.isLoading) return;

    await _historyRepository.clear();
    if (isClosed) return;
    emit(
      ChatState(
        currentWeather: state.currentWeather,
      ),
    );
  }

  void clearError() {
    if (state.error != null) {
      emit(state.copyWith(clearError: true));
    }
  }
}
