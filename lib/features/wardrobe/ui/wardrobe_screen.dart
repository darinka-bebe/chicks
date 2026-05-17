import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/wardrobe_item.dart';
import '../../../data/repositories/wardrobe_repository.dart';
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
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  List<Animation<double>> _itemAnimations = [];
  bool _isPlayingEntranceAnimation = false;
  bool _didPlayEntranceAnimation = false;

  List<WardrobeItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    if (widget.items != null) {
      _syncItems(widget.items!, animateEntrance: !_didPlayEntranceAnimation);
      return;
    }

    final items = await WardrobeRepository.instance.loadItems();
    if (!mounted) return;
    _syncItems(items, animateEntrance: !_didPlayEntranceAnimation);
  }

  void _onEntranceAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _isPlayingEntranceAnimation = false);
    }
  }

  void _syncItems(List<WardrobeItem> items, {required bool animateEntrance}) {
    AppLogger.debug(
      'WardrobeScreen._syncItems: count=${items.length} '
      'animateEntrance=$animateEntrance',
    );

    _animationController?.removeStatusListener(_onEntranceAnimationStatus);
    _animationController?.dispose();
    _animationController = null;
    _itemAnimations = [];

    final count = items.isEmpty ? 1 : items.length;

    if (animateEntrance && items.isNotEmpty) {
      _animationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      )..addStatusListener(_onEntranceAnimationStatus);

      _itemAnimations = List.generate(count, (index) {
        final start = (index * 0.08).clamp(0.0, 0.7);
        final end = (start + 0.45).clamp(0.0, 1.0);
        return CurvedAnimation(
          parent: _animationController!,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );
      });

      _isPlayingEntranceAnimation = true;
      _didPlayEntranceAnimation = true;

      setState(() {
        _items = List<WardrobeItem>.from(items);
        _isLoading = false;
      });

      _animationController!.forward();
      return;
    }

    _isPlayingEntranceAnimation = false;
    if (!_didPlayEntranceAnimation && items.isNotEmpty) {
      _didPlayEntranceAnimation = true;
    }

    _itemAnimations = List.generate(
      count,
      (_) => const AlwaysStoppedAnimation<double>(1.0),
    );

    setState(() {
      _items = List<WardrobeItem>.from(items);
      _isLoading = false;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _onItemAdded(WardrobeItem item) async {
    AppLogger.info('WardrobeScreen: received new item ${item.id}, syncing…');

    final items = await WardrobeRepository.instance.loadItems();
    if (!mounted) return;

    AppLogger.debug('WardrobeScreen: repository returned ${items.length} items');

    _syncItems(items, animateEntrance: false);
    _showSnack('«${item.title}» добавлена в гардероб');
  }

  Future<void> _openAddItem() async {
    AppLogger.debug('WardrobeScreen: opening add item');
    final created = await context.pushNamed<WardrobeItem>(
      RouteNames.addWardrobeItemName,
    );
    if (!mounted) return;

    if (created != null) {
      await _onItemAdded(created);
      return;
    }

    AppLogger.debug('WardrobeScreen: add screen closed without item');
  }

  Future<void> _openItemDetails(WardrobeItem item) async {
    final changed = await context.pushNamed<bool>(
      RouteNames.wardrobeItemDetailsName,
      extra: item,
    );
    if (changed == true && mounted) {
      await _loadItems();
    }
  }

  Widget _buildGrid(List<WardrobeItem> items) {
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
          final animationValue = _isPlayingEntranceAnimation
              ? _itemAnimations[index].value
              : 1.0;

          return WardrobeItemCard(
            key: ValueKey<String>(wardrobeItem.id),
            item: wardrobeItem,
            animationValue: animationValue,
            onTap: () => _openItemDetails(wardrobeItem),
          );
        },
      );
    }

    final controller = _animationController;
    if (_isPlayingEntranceAnimation && controller != null) {
      return AnimatedBuilder(
        animation: controller,
        builder: (context, _) => grid(),
      );
    }

    return grid();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppBrandColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppBrandColors.pink),
        ),
      );
    }

    final items = _items;

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
          'Твой гардероб',
          style: TextStyle(
            color: AppBrandColors.pink,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddItem,
        backgroundColor: AppBrandColors.pink,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: items.isEmpty
          ? _WardrobeEmptyState(onAddPressed: _openAddItem)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    '${items.length} ${_itemsLabel(items.length)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: _buildGrid(items)),
              ],
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

class _WardrobeEmptyState extends StatelessWidget {
  const _WardrobeEmptyState({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppBrandColors.iconBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.checkroom_outlined,
                size: 44,
                color: AppBrandColors.pink,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Гардероб пока пуст',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppBrandColors.title,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Добавь первую вещь — стилист сможет подбирать образы под твой гардероб.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Добавить вещь'),
              style: FilledButton.styleFrom(
                backgroundColor: AppBrandColors.pink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
