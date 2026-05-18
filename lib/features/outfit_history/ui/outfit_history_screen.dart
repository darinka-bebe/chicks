import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_brand_colors.dart';
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
          ? const Center(
              child: CircularProgressIndicator(color: AppBrandColors.pink),
            )
          : entries.isEmpty
              ? _OutfitHistoryEmptyState(
                  onOpenChat: () {
                    context.pop();
                    context.pushNamed(RouteNames.chatName);
                  },
                )
              : RefreshIndicator(
                  color: AppBrandColors.pink,
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < entries.length - 1 ? 14 : 0,
                        ),
                        child: OutfitHistoryCard(
                          key: ValueKey<String>(entry.id),
                          entry: entry,
                          wardrobeItems: _wardrobeItems,
                          onTap: () => _openDetails(entry),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _OutfitHistoryEmptyState extends StatelessWidget {
  const _OutfitHistoryEmptyState({required this.onOpenChat});

  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppBrandColors.iconBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 40,
                color: AppBrandColors.pink,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Твои AI-образы появятся здесь ✨',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppBrandColors.title,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Каждая рекомендация стилиста с вещами из гардероба сохраняется автоматически',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onOpenChat,
              style: FilledButton.styleFrom(
                backgroundColor: AppBrandColors.pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('К чату со стилистом'),
            ),
          ],
        ),
      ),
    );
  }
}
