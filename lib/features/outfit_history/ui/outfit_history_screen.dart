import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/widgets/chicks_empty_state.dart';
import '../../../core/widgets/chicks_error_state.dart';
import '../../../core/widgets/chicks_skeleton.dart';
import '../../../data/models/outfit_history_entry.dart';
import '../../../data/models/wardrobe_item.dart';
import '../../wardrobe/wardrobe_controller.dart';
import '../outfit_history_controller.dart';
import '../widgets/outfit_history_card.dart';

class OutfitHistoryScreen extends StatefulWidget {
  const OutfitHistoryScreen({super.key});

  @override
  State<OutfitHistoryScreen> createState() => _OutfitHistoryScreenState();
}

class _OutfitHistoryScreenState extends State<OutfitHistoryScreen> {
  List<WardrobeItem> _wardrobeItems = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final history = context.read<OutfitHistoryController>();
    final wardrobe = context.read<WardrobeController>();
    await history.refresh();
    await wardrobe.ensureLoaded();
    if (!mounted) return;
    setState(() => _wardrobeItems = wardrobe.items);
  }

  Future<void> _refresh() async {
    final history = context.read<OutfitHistoryController>();
    final wardrobe = context.read<WardrobeController>();
    await history.refresh();
    await wardrobe.reloadFromStorage();
    if (!mounted) return;
    setState(() => _wardrobeItems = wardrobe.items);
  }

  Future<void> _openDetails(OutfitHistoryEntry entry) async {
    final changed = await context.pushNamed<bool>(
      RouteNames.outfitHistoryDetailsName,
      extra: entry,
    );
    if (changed == true && mounted) {
      await _refresh();
    }
  }

  void _openChat() {
    context.pop();
    context.pushNamed(RouteNames.chatName);
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<OutfitHistoryController>();
    final entries = history.entries;
    final isLoading = !history.isLoaded;

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
          'История образов',
          style: TextStyle(
            color: AppBrandColors.pink,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: ListView.builder(
                key: const ValueKey('history-loading'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: ChicksListCardSkeleton(),
              ),
            ),
            )
          : history.loadError != null
              ? AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: ChicksRefreshableScroll(
                    key: const ValueKey('history-error'),
                    onRefresh: _refresh,
                    child: ChicksErrorState(
                      message: history.loadError!,
                      onRetry: _refresh,
                    ),
                  ),
                )
              : entries.isEmpty
              ? AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: ChicksRefreshableScroll(
                    key: const ValueKey('history-empty'),
                    onRefresh: _refresh,
                    child: ChicksEmptyState(
                      icon: Icons.history_rounded,
                      secondaryIcon: Icons.auto_awesome_outlined,
                      title: 'No saved outfits yet',
                      message:
                          'Каждая рекомендация стилиста с вещами из гардероба сохраняется автоматически',
                      hint: 'Попробуй: «Уютный образ на дождливый день»',
                      actionLabel: 'К чату со стилистом',
                      onAction: _openChat,
                    ),
                  ),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: RefreshIndicator(
                    key: const ValueKey('history-list'),
                    color: AppBrandColors.pink,
                    onRefresh: _refresh,
                    child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < entries.length - 1 ? 14 : 0,
                        ),
                        child: Dismissible(
                          key: ValueKey<String>('dismiss-${entry.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (_) async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Удалить образ?'),
                                content: const Text(
                                  'Запись исчезнет из истории.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, false),
                                    child: const Text('Отмена'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, true),
                                    child: const Text(
                                      'Удалить',
                                      style: TextStyle(
                                        color: AppBrandColors.pink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            return confirmed == true;
                          },
                          onDismissed: (_) {
                            context
                                .read<OutfitHistoryController>()
                                .deleteEntry(entry.id);
                          },
                          child: OutfitHistoryCard(
                            key: ValueKey<String>(entry.id),
                            entry: entry,
                            wardrobeItems: _wardrobeItems,
                            onTap: () => _openDetails(entry),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                ),
    );
  }
}
