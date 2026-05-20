import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/wardrobe_item.dart';
import '../../../data/repositories/wardrobe_repository.dart';
import '../wardrobe_controller.dart';
import '../widgets/wardrobe_empty_state.dart';
import '../widgets/wardrobe_insights_banner.dart';
import '../widgets/wardrobe_item_card.dart';

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
        context.read<WardrobeController>().reloadFromStorage();
      }
    });
  }

  @override
  void dispose() {
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

    await context.read<WardrobeController>().onItemDeleted(itemId);

    setState(() {
      _deletingItemId = null;
      _deleteAnimValue = 1;
    });

    _deleteController?.dispose();
    _deleteController = null;

    _entranceAnimations = List.generate(
      context.read<WardrobeController>().items.isEmpty
          ? 1
          : context.read<WardrobeController>().items.length,
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
    _showSnack('«${created.title}» добавлена в гардероб');
  }

  Future<void> _openItemDetails(WardrobeItem item) async {
    AppLogger.info(
      'WardrobeScreen: open details id=${item.id} title="${item.title}"',
    );

    final deletedId = await context.pushNamed<String>(
      RouteNames.wardrobeItemDetailsName,
      extra: item,
    );

    if (!mounted) return;

    if (deletedId != null && deletedId.isNotEmpty) {
      await _runDeleteAnimation(deletedId);
      if (mounted) {
        _showSnack('Вещь удалена');
      }
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

  Widget _buildGrid(List<WardrobeItem> items) {
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
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final wardrobeItem = items[index];
          return WardrobeItemCard(
            key: ValueKey<String>(wardrobeItem.id),
            item: wardrobeItem,
            animationValue: _cardAnimationValue(wardrobeItem, index, items),
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
      final items = widget.items!;
      return Scaffold(
        backgroundColor: AppBrandColors.background,
        appBar: _buildAppBar(context, hasItems: items.isNotEmpty),
        floatingActionButton: _buildFab(context),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCountLabel(items.length),
            const WardrobeInsightsBanner(),
            Expanded(child: _buildGrid(items)),
          ],
        ),
      );
    }

    final wardrobe = context.watch<WardrobeController>();
    final items = wardrobe.items;

    if (!wardrobe.isLoaded && wardrobe.isLoading) {
      return const Scaffold(
        backgroundColor: AppBrandColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppBrandColors.pink),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppBrandColors.background,
        appBar: _buildAppBar(context, hasItems: items.isNotEmpty),
        floatingActionButton: _buildFab(context),
        body: items.isEmpty
          ? WardrobeEmptyState(onAddPressed: _openAddItem)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCountLabel(items.length),
                const WardrobeInsightsBanner(),
                Expanded(child: _buildGrid(items)),
              ],
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
      title: const Text(
        'Твой гардероб',
        style: TextStyle(
          color: AppBrandColors.pink,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: 'Анализ гардероба',
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

  Widget _buildCountLabel(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Text(
        '$count ${_itemsLabel(count)}',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _itemsLabel(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod100 >= 11 && mod100 <= 14) return 'вещей';
    if (mod10 == 1) return 'вещь';
    if (mod10 >= 2 && mod10 <= 4) return 'вещи';
    return 'вещей';
  }
}
