import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/widgets/chicks_skeleton.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/outfit_history_entry.dart';
import '../../favorites/favorites_controller.dart';
import '../../preferences/outfit_preferences_controller.dart';
import '../widgets/wardrobe_snapshot_scope.dart';
import '../bloc/chat_cubit.dart';
import '../bloc/chat_state.dart';
import '../widgets/chat_empty_state.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_messages_list.dart';
import '../widgets/chat_weather_banner.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.restoreEntry, this.initialPrompt});

  final OutfitHistoryEntry? restoreEntry;
  final String? initialPrompt;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  final _inputBarKey = GlobalKey<ChatInputBarState>();
  bool _historyRestoreDone = false;
  bool _initialPromptInserted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeInsertInitialPrompt());
  }

  void _maybeInsertInitialPrompt() {
    if (_initialPromptInserted) return;
    final prompt = widget.initialPrompt?.trim() ?? '';
    if (prompt.isEmpty) return;
    final inputState = _inputBarKey.currentState;
    if (inputState == null) return;
    inputState.insertPrompt(prompt);
    _initialPromptInserted = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _scrollToBottom(animated: false);
  }

  Future<void> _confirmClearChat(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Очистить чат?'),
        content: const Text(
          'Вся переписка со стилистом будет удалена с этого устройства.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Очистить',
              style: TextStyle(color: AppBrandColors.pink),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<ChatCubit>().clearChat();
    }
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    ChatMessage aiMessage,
    String? userPrompt,
  ) async {
    final favorites = context.read<FavoritesController>();
    final preferences = context.read<OutfitPreferencesController>();

    try {
      final nowSaved = await favorites.toggleRecommendation(
        recommendation: aiMessage.content,
        userPrompt: userPrompt,
        recommendedItemIds: aiMessage.recommendedItemIds,
      );
      if (nowSaved) {
        await preferences.removeDislike(aiMessage.content);
      }
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              nowSaved ? 'Образ сохранён' : 'Удалено из избранного',
            ),
            behavior: SnackBarBehavior.floating,
            action: nowSaved
                ? SnackBarAction(
                    label: 'Открыть',
                    textColor: Colors.white,
                    onPressed: () =>
                        context.pushNamed(RouteNames.favoritesName),
                  )
                : null,
          ),
        );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось обновить избранное'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleDislike(
    BuildContext context,
    ChatMessage aiMessage,
    String? userPrompt,
  ) async {
    final preferences = context.read<OutfitPreferencesController>();
    final favorites = context.read<FavoritesController>();
    final wardrobe = WardrobeSnapshotScope.maybeOf(context)?.items ?? const [];

    try {
      final nowDisliked = await preferences.toggleDislike(
        recommendation: aiMessage.content,
        recommendedItemIds: aiMessage.recommendedItemIds,
        wardrobe: wardrobe,
        userPrompt: userPrompt,
      );
      if (nowDisliked) {
        await favorites.refresh();
      }
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              nowDisliked
                  ? 'Учтём: не будем предлагать похожие образы'
                  : 'Дизлайк снят',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось сохранить отзыв'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeInsertInitialPrompt());
    return BlocProvider(
      create: (_) => ChatCubit(),
      child: BlocListener<ChatCubit, ChatState>(
        listenWhen: (prev, curr) =>
            prev.isRestoringHistory && !curr.isRestoringHistory,
        listener: (context, state) async {
          final entry = widget.restoreEntry;
          if (entry == null || _historyRestoreDone) return;
          _historyRestoreDone = true;
          await context.read<ChatCubit>().openOutfitFromHistory(entry);
          if (mounted) _scrollToBottom();
        },
        child: BlocListener<ChatCubit, ChatState>(
          listenWhen: (prev, curr) =>
              prev.messages.length != curr.messages.length ||
              (prev.isLoading && !curr.isLoading),
          listener: (context, state) {
            _scrollToBottom();
          },
          child: BlocListener<ChatCubit, ChatState>(
          listenWhen: (prev, curr) =>
              prev.error != curr.error && curr.error != null,
          listener: (context, state) {
            final cubit = context.read<ChatCubit>();
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    state.error!.contains('network') ||
                            state.error!.contains('Network') ||
                            state.error!.contains('сеть') ||
                            state.error!.contains('интернет')
                        ? 'Проблема с сетью — проверь подключение'
                        : state.error!,
                  ),
                  backgroundColor: const Color(0xFFE57373),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 6),
                  action: SnackBarAction(
                    label: 'Повторить',
                    textColor: Colors.white,
                    onPressed: () {
                      cubit.clearError();
                      cubit.retryLastMessage();
                    },
                  ),
                ),
              );
          },
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: AppBrandColors.background,
            appBar: _ChatAppBar(
              onClear: () => _confirmClearChat(context),
            ),
            body: Column(
              children: [
                const _ChatWeatherStrip(),
                Expanded(
                  child: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    behavior: HitTestBehavior.translucent,
                    child: _ChatMessageArea(
                      scrollController: _scrollController,
                      inputBarKey: _inputBarKey,
                      onToggleFavorite: _toggleFavorite,
                      onToggleDislike: _toggleDislike,
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: BlocSelector<ChatCubit, ChatState, bool>(
                selector: (state) =>
                    !state.isLoading && !state.isRestoringHistory,
                builder: (context, enabled) {
                  return ChatInputBar(
                    key: _inputBarKey,
                    enabled: enabled,
                    onSend: context.read<ChatCubit>().sendMessage,
                  );
                },
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar({required this.onClear});

  final VoidCallback onClear;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ChatCubit, ChatState, bool>(
      selector: (state) =>
          state.messages.isNotEmpty &&
          !state.isLoading &&
          !state.isRestoringHistory,
      builder: (context, canClear) {
        return AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppBrandColors.pink,
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Чат со стилистом',
            style: TextStyle(
              color: AppBrandColors.pink,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Избранные образы',
              icon: const Icon(
                Icons.favorite_rounded,
                color: AppBrandColors.pink,
              ),
              onPressed: () => context.pushNamed(RouteNames.favoritesName),
            ),
            if (canClear)
              IconButton(
                tooltip: 'Очистить чат',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppBrandColors.pink,
                ),
                onPressed: onClear,
              ),
          ],
        );
      },
    );
  }
}

class _ChatWeatherStrip extends StatelessWidget {
  const _ChatWeatherStrip();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ChatCubit, ChatState, String?>(
      selector: (state) {
        if (state.isRestoringHistory) return null;
        final weather = state.currentWeather;
        if (weather == null || !weather.isAvailable) return null;
        return weather.compactUiLabel;
      },
      builder: (context, label) {
        if (label == null || label.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: ChatWeatherBanner(label: label),
        );
      },
    );
  }
}

class _ChatMessageArea extends StatelessWidget {
  const _ChatMessageArea({
    required this.scrollController,
    required this.inputBarKey,
    required this.onToggleFavorite,
    required this.onToggleDislike,
  });

  final ScrollController scrollController;
  final GlobalKey<ChatInputBarState> inputBarKey;
  final void Function(BuildContext, ChatMessage, String?) onToggleFavorite;
  final void Function(BuildContext, ChatMessage, String?) onToggleDislike;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ChatCubit, ChatState, _ChatListData>(
      selector: (state) => _ChatListData(
        isRestoringHistory: state.isRestoringHistory,
        messages: state.messages,
        isLoading: state.isLoading,
      ),
      builder: (context, data) {
        if (data.isRestoringHistory) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ChicksSkeleton(width: 220, height: 14, borderRadius: 8),
                SizedBox(height: 16),
                ChicksSkeleton(width: 280, height: 72, borderRadius: 16),
                SizedBox(height: 12),
                ChicksSkeleton(width: 240, height: 72, borderRadius: 16),
              ],
            ),
          );
        }

        if (data.messages.isEmpty && !data.isLoading) {
          return ChatEmptyState(
            onSuggestionTap: (prompt) {
              inputBarKey.currentState?.insertPrompt(prompt);
            },
          );
        }

        return WardrobeSnapshotLoader(
          child: ChatMessagesList(
            scrollController: scrollController,
            messages: data.messages,
            isLoading: data.isLoading,
            onToggleFavorite: (message, userPrompt) =>
                onToggleFavorite(context, message, userPrompt),
            onToggleDislike: (message, userPrompt) =>
                onToggleDislike(context, message, userPrompt),
          ),
        );
      },
    );
  }
}

class _ChatListData {
  const _ChatListData({
    required this.isRestoringHistory,
    required this.messages,
    required this.isLoading,
  });

  final bool isRestoringHistory;
  final List<ChatMessage> messages;
  final bool isLoading;

  @override
  bool operator ==(Object other) {
    return other is _ChatListData &&
        other.isRestoringHistory == isRestoringHistory &&
        other.isLoading == isLoading &&
        identical(other.messages, messages);
  }

  @override
  int get hashCode => Object.hash(isRestoringHistory, isLoading, messages);
}
