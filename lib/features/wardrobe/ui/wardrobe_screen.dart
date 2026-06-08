import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/wardrobe_catalog.dart';
import '../../../core/router/route_names.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/widgets/chicks_error_state.dart';
import '../../../core/widgets/chicks_skeleton.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/wardrobe_item.dart';
import '../../../data/repositories/wardrobe_repository.dart';
import '../wardrobe_controller.dart';
import '../data/wardrobe_filter.dart';
import '../widgets/wardrobe_empty_state.dart';
import '../widgets/wardrobe_filter_bar.dart';
import '../widgets/wardrobe_insights_banner.dart';
import '../widgets/wardrobe_item_card.dart';
import '../widgets/wardrobe_no_results_state.dart';
import '../widgets/wardrobe_search_bar.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({
    super.key,
    this.items,
  });

  /// Optional override for tests or empty-state preview.
  final List<WardrobeItem>? items;

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen>
    with TickerProviderStateMixin {
  AnimationController? _entranceController;
  List<Animation<double>> _entranceAnimations = [];
  bool _isPlayingEntrance = false;
  bool _didPlayEntrance = false;

  String? _deletingItemId;
  AnimationController? _deleteController;
  double _deleteAnimValue = 1;

  final Map<String, AnimationController> _insertControllers = {};

  final _searchController = TextEditingController();
  WardrobeFilterCriteria _filterCriteria = const WardrobeFilterCriteria();

  WardrobeController? _wardrobe;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _wardrobe ??= context.read<WardrobeController>();
  }

  @override
  void activate() {
    super.activate();
    if (widget.items != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route?.isCurrent ?? false) {
        context.read<WardrobeController>().reloadIfRevisionChanged();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _entranceController?.dispose();
    _deleteController?.dispose();
    for (final c in _insertControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (widget.items != null) {
      _applyItems(widget.items!, animateEntrance: !_didPlayEntrance);
      return;
    }
    await context.read<WardrobeController>().ensureLoaded();
    if (!mounted) return;
    final items = context.read<WardrobeController>().items;
    _applyItems(items, animateEntrance: !_didPlayEntrance);
  }

  void _applyItems(List<WardrobeItem> items, {required bool animateEntrance}) {
    _entranceController?.dispose();
    _entranceController = null;
    _entranceAnimations = [];

    final count = items.isEmpty ? 1 : items.length;

    if (animateEntrance && items.isNotEmpty) {
      _entranceController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _isPlayingEntrance = false);
          }
        });

      _entranceAnimations = List.generate(count, (index) {
        final start = (index * 0.08).clamp(0.0, 0.7);
        final end = (start + 0.45).clamp(0.0, 1.0);
        return CurvedAnimation(
          parent: _entranceController!,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );
      });

      _isPlayingEntrance = true;
      _didPlayEntrance = true;
      setState(() {});
      _entranceController!.forward();
      return;
    }

    _isPlayingEntrance = false;
    if (!_didPlayEntrance && items.isNotEmpty) {
      _didPlayEntrance = true;
    }

    _entranceAnimations = List.generate(
      count,
      (_) => const AlwaysStoppedAnimation<double>(1.0),
    );
    setState(() {});
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppBrandColors.pink,
        ),
      );
  }

  Future<void> _runInsertAnimation(String itemId) async {
    _insertControllers[itemId]?.dispose();
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _insertControllers[itemId] = controller;

    controller.addListener(() {
      if (mounted) setState(() {});
    });

    await controller.forward();
    if (!mounted) return;

    controller.dispose();
    _insertControllers.remove(itemId);
    if (mounted) setState(() {});
  }

  Future<void> _runDeleteAnimation(String itemId) async {
    final controller = context.read<WardrobeController>();
    _deleteController?.dispose();
    _deleteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _deleteController!.addListener(() {
      if (mounted) {
        setState(() {
          _deleteAnimValue = 1 - _deleteController!.value;
        });
      }
    });

    setState(() {
      _deletingItemId = itemId;
      _deleteAnimValue = 1;
    });

    await _deleteController!.forward();
    if (!mounted) return;

    await controller.onItemDeleted(itemId);
    if (!mounted) return;

    setState(() {
      _deletingItemId = null;
      _deleteAnimValue = 1;
    });

    _deleteController?.dispose();
    _deleteController = null;

    _entranceAnimations = List.generate(
      controller.items.isEmpty ? 1 : controller.items.length,
      (_) => const AlwaysStoppedAnimation<double>(1.0),
    );
  }

  Future<void> _openAddItem() async {
    final created = await context.pushNamed<WardrobeItem>(
      RouteNames.addWardrobeItemName,
    );
    if (!mounted || created == null) return;

    final controller = context.read<WardrobeController>();
    await controller.onItemAdded(created);
    if (!mounted) return;

    await _runInsertAnimation(created.id);
    _showSnack(
      AppLocalizations.of(context).wardrobeItemAdded(
        WardrobeCatalog.displayItemTitle(created),
      ),
    );
  }

  Future<void> _openItemDetails(WardrobeItem item) async {
    AppLogger.info(
      'WardrobeScreen: open details id=${item.id} title="${item.title}"',
    );

    final result = await context.pushNamed<Object?>(
      RouteNames.wardrobeItemDetailsName,
      extra: item,
    );

    if (!mounted) return;

    if (result is String && result.isNotEmpty) {
      await _runDeleteAnimation(result);
      if (mounted) {
        _showSnack(AppLocalizations.of(context).wardrobeItemDeleted);
      }
      return;
    }

    if (result is WardrobeItem) {
      final controller = context.read<WardrobeController>();
      await controller.onItemUpdated(result);
      if (!mounted) return;
      _applyItems(controller.items, animateEntrance: false);
      _showSnack(
        AppLocalizations.of(context).wardrobeItemUpdated(
          WardrobeCatalog.displayItemTitle(result),
        ),
      );
      return;
    }

    await context.read<WardrobeController>().reloadFromStorage();
    if (mounted) {
      _applyItems(
        context.read<WardrobeController>().items,
        animateEntrance: false,
      );
    }
  }

  double _cardAnimationValue(
    WardrobeItem item,
    int index,
    List<WardrobeItem> items,
  ) {
    if (_deletingItemId != null &&
        WardrobeRepository.idEquals(item.id, _deletingItemId!)) {
      return _deleteAnimValue;
    }

    final insertController = _insertControllers[item.id];
    if (insertController != null) {
      return Curves.easeOut.transform(insertController.value);
    }

    if (_isPlayingEntrance && index < _entranceAnimations.length) {
      return _entranceAnimations[index].value;
    }

    return 1;
  }

  void _updateFilter(WardrobeFilterCriteria next) {
    setState(() => _filterCriteria = next);
    AppLogger.debug(
      'WardrobeScreen: filters updated '
      'search="${next.query}" category=${next.category} season=${next.season} '
      'color=${next.color} style=${next.style} favoritesOnly=${next.favoritesOnly}',
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _filterCriteria = _filterCriteria.cleared().copyWith(
            favoriteIds: _filterCriteria.favoriteIds,
          );
    });
    AppLogger.debug('WardrobeScreen: filters cleared');
  }

  List<WardrobeItem> _filteredItems(
    List<WardrobeItem> source,
    Set<String> favoriteIds,
  ) {
    return WardrobeFilterEngine.apply(
      items: source,
      criteria: _filterCriteria.copyWith(favoriteIds: favoriteIds),
    );
  }

  Widget _buildBrowseHeader({
    required int totalCount,
    required int visibleCount,
    required Set<String> availableColors,
    required Set<String> availableStyles,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: WardrobeSearchBar(
            controller: _searchController,
            onChanged: (value) =>
                _updateFilter(_filterCriteria.copyWith(query: value)),
            onClear: _clearFilters,
          ),
        ),
        WardrobeFilterBar(
          criteria: _filterCriteria,
          availableColors: availableColors,
          availableStyles: availableStyles,
          onCriteriaChanged: _updateFilter,
          onClearAll: _clearFilters,
        ),
        const SizedBox(height: 12),
        _buildCountLabel(visibleCount, totalCount: totalCount),
        const WardrobeInsightsBanner(),
      ],
    );
  }

  Widget _buildGrid(
    List<WardrobeItem> items, {
    required WardrobeEmptyFilterReason emptyReason,
    required bool showFavoritesToggle,
    required bool Function(String id) isFavorite,
    Future<void> Function(String id)? onFavoriteToggle,
  }) {
    if (items.isEmpty && emptyReason != WardrobeEmptyFilterReason.none) {
      return WardrobeNoResultsState(
        reason: emptyReason,
        onClearFilters: _clearFilters,
      );
    }

    if (items.isEmpty) {
      return WardrobeEmptyState(onAddPressed: _openAddItem);
    }

    final gridKey = ValueKey<String>(
      items.map((item) => item.id).join('|'),
    );

    Widget grid() {
      return GridView.builder(
        key: gridKey,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.7,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final wardrobeItem = items[index];
          return WardrobeItemCard(
            key: ValueKey<String>(wardrobeItem.id),
            item: wardrobeItem,
            animationValue: _cardAnimationValue(wardrobeItem, index, items),
            isFavorite: isFavorite(wardrobeItem.id),
            onFavoriteToggle: showFavoritesToggle && onFavoriteToggle != null
                ? () => onFavoriteToggle(wardrobeItem.id)
                : null,
            onTap: () => _openItemDetails(wardrobeItem),
          );
        },
      );
    }

    final entrance = _entranceController;
    if (_isPlayingEntrance && entrance != null) {
      return AnimatedBuilder(animation: entrance, builder: (_, __) => grid());
    }

    if (_insertControllers.isNotEmpty || _deleteController != null) {
      return AnimatedBuilder(
        animation: Listenable.merge([
          ..._insertControllers.values,
          if (_deleteController != null) _deleteController!,
        ]),
        builder: (_, __) => grid(),
      );
    }

    return grid();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items != null) {
      final allItems = widget.items!;
      final filtered = _filteredItems(allItems, {});
      final emptyReason = WardrobeFilterEngine.emptyReason(
        criteria: _filterCriteria,
        totalCount: allItems.length,
        filteredCount: filtered.length,
      );

      return Scaffold(
        backgroundColor: AppBrandColors.background,
        appBar: _buildAppBar(context, hasItems: allItems.isNotEmpty),
        floatingActionButton: _buildFab(context),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (allItems.isNotEmpty)
              _buildBrowseHeader(
                totalCount: allItems.length,
                visibleCount: filtered.length,
                availableColors: WardrobeFilterEngine.uniqueColors(allItems),
                availableStyles: WardrobeFilterEngine.uniqueStyles(allItems),
              ),
            Expanded(
              child: _buildGrid(
                filtered,
                emptyReason: emptyReason,
                showFavoritesToggle: false,
                isFavorite: (_) => false,
              ),
            ),
          ],
        ),
      );
    }

    final wardrobe = context.watch<WardrobeController>();
    final allItems = wardrobe.items;
    final filtered = _filteredItems(allItems, wardrobe.favoriteIds);
    final emptyReason = WardrobeFilterEngine.emptyReason(
      criteria: _filterCriteria.copyWith(favoriteIds: wardrobe.favoriteIds),
      totalCount: allItems.length,
      filteredCount: filtered.length,
    );

    if (_filterCriteria.favoriteIds != wardrobe.favoriteIds) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _filterCriteria = _filterCriteria.copyWith(
            favoriteIds: wardrobe.favoriteIds,
          );
        });
      });
    }

    final isInitialLoading = !wardrobe.isLoaded && wardrobe.isLoading;
    final hasError = wardrobe.loadError != null;
    final hasItems = allItems.isNotEmpty;

    Widget body;
    if (isInitialLoading) {
      body = const ChicksWardrobeGridSkeleton(key: ValueKey('wardrobe-loading'));
    } else if (hasError) {
      body = ChicksRefreshableScroll(
        key: const ValueKey('wardrobe-error'),
        onRefresh: wardrobe.refresh,
        child: ChicksErrorState(
          message: wardrobe.loadError!,
          onRetry: wardrobe.refresh,
        ),
      );
    } else if (!hasItems) {
      body = ChicksRefreshableScroll(
        key: const ValueKey('wardrobe-empty'),
        onRefresh: wardrobe.refresh,
        child: WardrobeEmptyState(onAddPressed: _openAddItem),
      );
    } else {
      body = RefreshIndicator(
        key: const ValueKey('wardrobe-list'),
        color: AppBrandColors.pink,
        onRefresh: wardrobe.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _buildBrowseHeader(
                totalCount: allItems.length,
                visibleCount: filtered.length,
                availableColors: WardrobeFilterEngine.uniqueColors(allItems),
                availableStyles: WardrobeFilterEngine.uniqueStyles(allItems),
              ),
            ),
            if (filtered.isEmpty &&
                emptyReason != WardrobeEmptyFilterReason.none)
              SliverFillRemaining(
                hasScrollBody: false,
                child: WardrobeNoResultsState(
                  reason: emptyReason,
                  onClearFilters: _clearFilters,
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: WardrobeEmptyState(onAddPressed: _openAddItem),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.7,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final wardrobeItem = filtered[index];
                      return WardrobeItemCard(
                        key: ValueKey<String>(wardrobeItem.id),
                        item: wardrobeItem,
                        animationValue: _cardAnimationValue(
                          wardrobeItem,
                          index,
                          filtered,
                        ),
                        isFavorite: wardrobe.isFavorite(wardrobeItem.id),
                        onFavoriteToggle: () async {
                          await wardrobe.toggleFavorite(wardrobeItem.id);
                        },
                        onTap: () => _openItemDetails(wardrobeItem),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppBrandColors.background,
      appBar: _buildAppBar(context, hasItems: hasItems),
      floatingActionButton: _buildFab(context),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: body,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required bool hasItems,
  }) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        color: AppBrandColors.pink,
        onPressed: () => context.pop(),
      ),
      title: Text(
        AppLocalizations.of(context).wardrobeTitle,
        style: const TextStyle(
          color: AppBrandColors.pink,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: AppLocalizations.of(context).wardrobeInsightsTooltip,
          onPressed: !hasItems
              ? null
              : () => context.pushNamed(RouteNames.wardrobeInsightsName),
          icon: const Icon(Icons.insights_outlined),
          color: AppBrandColors.pink,
        ),
      ],
    );
  }

  Widget _buildFab(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: FloatingActionButton(
        onPressed: _openAddItem,
        backgroundColor: AppBrandColors.pink,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _buildCountLabel(int count, {int? totalCount}) {
    final label = totalCount != null && totalCount != count
        ? WardrobeCatalog.countShownLabel(count, totalCount)
        : WardrobeCatalog.itemsLabel(count);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

}
