import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_brand_colors.dart';
import '../bloc/chat_cubit.dart';
import '../bloc/chat_state.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _confirmClearChat(BuildContext context) async {
    final cubit = context.read<ChatCubit>();
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
      await cubit.clearChat();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatCubit(),
      child: BlocConsumer<ChatCubit, ChatState>(
        listenWhen: (prev, curr) =>
            prev.messages.length != curr.messages.length ||
            prev.isLoading != curr.isLoading ||
            prev.isRestoringHistory != curr.isRestoringHistory ||
            prev.error != curr.error,
        listener: (context, state) {
          _scrollToBottom();
          if (state.error != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'OK',
                    textColor: Colors.white,
                    onPressed: () => context.read<ChatCubit>().clearError(),
                  ),
                ),
              );
          }
        },
        builder: (context, state) {
          final canClear = state.messages.isNotEmpty &&
              !state.isLoading &&
              !state.isRestoringHistory;

          return Scaffold(
            backgroundColor: AppBrandColors.background,
            appBar: AppBar(
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
                if (canClear)
                  IconButton(
                    tooltip: 'Очистить чат',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppBrandColors.pink,
                    ),
                    onPressed: () => _confirmClearChat(context),
                  ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: state.isRestoringHistory
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppBrandColors.pink,
                          ),
                        )
                      : state.messages.isEmpty && !state.isLoading
                          ? _EmptyChatHint()
                          : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount:
                              state.messages.length + (state.isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < state.messages.length) {
                              return ChatMessageBubble(
                                message: state.messages[index],
                              );
                            }
                            return const ChatTypingIndicator();
                          },
                        ),
                ),
                ChatInputBar(
                  enabled: !state.isLoading && !state.isRestoringHistory,
                  onSend: context.read<ChatCubit>().sendMessage,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyChatHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppBrandColors.iconBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: AppBrandColors.pink,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Привет! Я твой ИИ-стилист 💗',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppBrandColors.title,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Выбери подсказку ниже или спроси про образ с учётом настроения, погоды и повода.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
