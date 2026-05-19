import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/openai_chat_service.dart';
import '../../../core/services/stylist_pipeline_safety.dart';
import '../../../core/services/weather/weather_repository.dart';
import '../../../core/services/wardrobe_ai_context.dart';
import '../../../core/services/wardrobe_recommendation_sanitizer.dart';
import '../../../core/services/wardrobe_sync_service.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/wardrobe_item.dart';
import '../../../data/models/chat_message.dart';
import '../../../core/models/stylist_response.dart';
import '../../../core/models/weather_snapshot.dart';
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
    WardrobeAiContext.instance.addListener(_onWardrobeChanged);
    _restoreHistory();
  }

  final OpenAiChatService _service;
  final ChatHistoryRepository _historyRepository;
  final WeatherRepository _weatherRepository;
  final OutfitHistoryRepository _outfitHistoryRepository;

  @override
  Future<void> close() {
    WardrobeAiContext.instance.removeListener(_onWardrobeChanged);
    return super.close();
  }

  void _onWardrobeChanged() {
    _syncMessagesWithWardrobe();
  }

  Future<void> _syncMessagesWithWardrobe() async {
    if (isClosed || state.isRestoringHistory) return;

    try {
      final wardrobe = await WardrobeSyncService.loadFreshWardrobeForAi();
      final sanitized = WardrobeRecommendationSanitizer.sanitizeChatMessages(
        state.messages,
        wardrobe,
      );

      if (sanitized.length != state.messages.length ||
          !_messagesEqual(sanitized, state.messages)) {
        AppLogger.info(
          'ChatCubit: synced chat with wardrobe (${wardrobe.length} items)',
        );
        emit(state.copyWith(messages: sanitized));
        await _historyRepository.saveMessages(sanitized);
      }
    } catch (e, stack) {
      AppLogger.error(
        'ChatCubit: wardrobe sync failed',
        error: e,
        stackTrace: stack,
      );
    }
  }

  static bool _messagesEqual(List<ChatMessage> a, List<ChatMessage> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _restoreHistory() async {
    try {
      final messages = await _historyRepository.loadMessages();
      if (isClosed) return;

      final wardrobe = await WardrobeSyncService.loadFreshWardrobeForAi();
      final sanitized = WardrobeRecommendationSanitizer.sanitizeChatMessages(
        messages,
        wardrobe,
      );

      emit(
        ChatState(
          messages: sanitized,
          isRestoringHistory: false,
        ),
      );
      if (sanitized.length != messages.length ||
          !_messagesEqual(sanitized, messages)) {
        await _historyRepository.saveMessages(sanitized);
      }
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

    WeatherSnapshot weather = WeatherSnapshot.unavailable;
    try {
      weather = await _weatherRepository.getCurrent(forceRefresh: true);
    } catch (e, stack) {
      AppLogger.error(
        'ChatCubit: weather fetch failed — continuing without weather',
        error: e,
        stackTrace: stack,
      );
    }

    List<WardrobeItem> wardrobe = const [];
    try {
      wardrobe = await WardrobeSyncService.loadFreshWardrobeForAi();
    } catch (e, stack) {
      AppLogger.error(
        'ChatCubit: wardrobe load before send failed',
        error: e,
        stackTrace: stack,
      );
    }

    AppLogger.info(
      'ChatCubit: AI request wardrobeCount=${wardrobe.length} '
      'revision=${WardrobeAiContext.instance.revision} '
      'weather=${weather.isAvailable ? weather.compactUiLabel : "n/a"}',
    );

    try {
      final reply = await _service.completeConversation(
        withUserMessage,
        liveWeather: weather,
      );

      await _emitAssistantReply(
        userMessages: withUserMessage,
        reply: reply,
        weather: weather,
        userPrompt: trimmed,
      );
    } on OpenAiChatException catch (e, stack) {
      if (isClosed) return;
      AppLogger.error(
        'ChatCubit.sendMessage: OpenAI error',
        error: e,
        stackTrace: stack,
      );
      await _emitAssistantReply(
        userMessages: withUserMessage,
        reply: StylistPipelineSafety.fallbackResponse(),
        weather: weather,
        userPrompt: trimmed,
        showErrorBanner: true,
        errorBanner: e.message,
      );
    } catch (e, stack) {
      if (isClosed) return;
      AppLogger.error(
        'ChatCubit.sendMessage: pipeline failure — fallback reply',
        error: e,
        stackTrace: stack,
      );
      await _emitAssistantReply(
        userMessages: withUserMessage,
        reply: StylistPipelineSafety.fallbackResponse(),
        weather: weather,
        userPrompt: trimmed,
      );
    }
  }

  Future<void> _emitAssistantReply({
    required List<ChatMessage> userMessages,
    required StylistResponse reply,
    required WeatherSnapshot weather,
    required String userPrompt,
    bool showErrorBanner = false,
    String? errorBanner,
  }) async {
    final weatherLabel = weather.isAvailable ? weather.compactUiLabel : null;

    var recommendedIds = reply.recommendedItemIds;
    if (recommendedIds.isNotEmpty) {
      try {
        final wardrobe = await WardrobeSyncService.loadFreshWardrobeForAi();
        final filtered = WardrobeRecommendationSanitizer.filterIds(
          ids: recommendedIds,
          wardrobe: wardrobe,
        );
        if (filtered.length != recommendedIds.length) {
          AppLogger.info(
            'ChatCubit: stripped ${recommendedIds.length - filtered.length} '
            'stale id(s) before save (wardrobe=${wardrobe.length})',
          );
          AppLogger.debug(
            'ChatCubit: raw=${reply.recommendedItemIds} kept=$filtered',
          );
        }
        recommendedIds = filtered;
      } catch (e, stack) {
        AppLogger.error(
          'ChatCubit: could not verify recommendation ids',
          error: e,
          stackTrace: stack,
        );
        recommendedIds = const [];
      }
    }

    final assistantMessage = ChatMessage.assistant(
      reply.message.trim().isNotEmpty
          ? reply.message
          : StylistPipelineSafety.fallbackAssistantMessage,
      recommendedItemIds: recommendedIds,
      weatherLabel: weatherLabel,
    );

    final withAssistant = [...userMessages, assistantMessage];

    if (isClosed) return;
    emit(
      state.copyWith(
        messages: withAssistant,
        isLoading: false,
        currentWeather: weather.isAvailable ? weather : state.currentWeather,
        error: showErrorBanner ? errorBanner : null,
        clearError: !showErrorBanner,
      ),
    );
    await _persistMessages(withAssistant);

    if (reply.hasRecommendations) {
      await _recordOutfitHistory(
        userPrompt: userPrompt,
        assistantMessage: assistantMessage,
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

    var itemIds = entry.recommendedItemIds;
    if (itemIds.isNotEmpty) {
      try {
        final wardrobe = await WardrobeSyncService.loadFreshWardrobeForAi();
        itemIds = WardrobeRecommendationSanitizer.filterIds(
          ids: itemIds,
          wardrobe: wardrobe,
        );
      } catch (_) {
        itemIds = const [];
      }
    }

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
      recommendedItemIds: itemIds,
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
