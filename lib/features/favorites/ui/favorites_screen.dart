import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/widgets/chicks_empty_state.dart';
import '../../../core/widgets/chicks_error_state.dart';
import '../../../core/widgets/chicks_skeleton.dart';
import '../../../data/models/favorite_outfit.dart';
import '../favorites_controller.dart';
import '../widgets/favorite_outfit_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesController>().ensureLoaded();
    });
  }

  Future<void> _openDetails(FavoriteOutfit outfit) async {
    final changed = await context.pushNamed<bool>(
      RouteNames.favoriteOutfitDetailsName,
      extra: outfit,
    );
    if (changed == true && mounted) {
      await context.read<FavoritesController>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesController>();
    final outfits = favorites.outfits;
    final isLoading = !favorites.isLoaded;

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
          'Избранные образы',
          style: TextStyle(
            color: AppBrandColors.pink,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, __) => const ChicksListCardSkeleton(),
            )
          : favorites.loadError != null
              ? ChicksRefreshableScroll(
                  onRefresh: favorites.refresh,
                  child: ChicksErrorState(
                    message: favorites.loadError!,
                    onRetry: favorites.refresh,
                  ),
                )
              : outfits.isEmpty
              ? ChicksRefreshableScroll(
                  onRefresh: favorites.refresh,
                  child: ChicksEmptyState(
                    icon: Icons.favorite_border_rounded,
                    secondaryIcon: Icons.bookmark_added_outlined,
                    title: 'Пока нет избранных образов',
                    message:
                        'Сохраняй понравившиеся образы из чата — они появятся здесь',
                    actionLabel: 'К чату со стилистом',
                    onAction: () => context.pop(),
                  ),
                )
              : RefreshIndicator(
                  color: AppBrandColors.pink,
                  onRefresh: favorites.refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: outfits.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final outfit = outfits[index];
                      return FavoriteOutfitCard(
                        key: ValueKey(outfit.contentHash),
                        outfit: outfit,
                        onTap: () => _openDetails(outfit),
                      );
                    },
                  ),
                ),
    );
  }
}
