import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/widgets/chicks_empty_state.dart';
import '../../../core/widgets/chicks_error_state.dart';
import '../../../core/widgets/chicks_skeleton.dart';
import '../../../data/models/favorite_outfit.dart';
import '../../wardrobe/wardrobe_controller.dart';
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
      context.read<WardrobeController>().ensureLoaded();
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
    final loc = AppLocalizations.of(context);
    final favorites = context.watch<FavoritesController>();
    final wardrobeItems = context.watch<WardrobeController>().items;
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
        title: Text(
          loc.favoritesTitle,
          style: const TextStyle(
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
              child: ListView.separated(
                key: const ValueKey('favorites-loading'),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (_, __) => const ChicksListCardSkeleton(),
              ),
            )
          : favorites.loadError != null
              ? AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: ChicksRefreshableScroll(
                    key: const ValueKey('favorites-error'),
                    onRefresh: favorites.refresh,
                    child: ChicksErrorState(
                      message: favorites.loadError!,
                      onRetry: favorites.refresh,
                    ),
                  ),
                )
              : outfits.isEmpty
                  ? AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: ChicksRefreshableScroll(
                        key: const ValueKey('favorites-empty'),
                        onRefresh: favorites.refresh,
                        child: ChicksEmptyState(
                          icon: Icons.favorite_border_rounded,
                          secondaryIcon: Icons.bookmark_added_outlined,
                          title: loc.favoritesEmptyTitle,
                          message: loc.favoritesEmptySubtitle,
                          hint: loc.favoritesEmptyHint,
                          actionLabel: loc.favoritesEmptyAction,
                          onAction: () => context.pop(),
                        ),
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: RefreshIndicator(
                        key: const ValueKey('favorites-list'),
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
                              wardrobeItems: wardrobeItems,
                              onTap: () => _openDetails(outfit),
                            );
                          },
                        ),
                      ),
                    ),
    );
  }
}

