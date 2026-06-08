import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/wardrobe_catalog.dart';
import '../../../core/router/route_names.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/widgets/wardrobe_item_image.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/wardrobe_item.dart';
import '../../../data/repositories/wardrobe_repository.dart';
import '../wardrobe_controller.dart';
import '../widgets/wardrobe_chip_selector.dart';

class WardrobeItemDetailsScreen extends StatefulWidget {
  const WardrobeItemDetailsScreen({super.key, required this.item});

  final WardrobeItem item;

  @override
  State<WardrobeItemDetailsScreen> createState() =>
      _WardrobeItemDetailsScreenState();
}

class _WardrobeItemDetailsScreenState extends State<WardrobeItemDetailsScreen> {
  bool _isDeleting = false;
  bool _isFavorite = false;

  WardrobeItem get item => widget.item;

  @override
  void initState() {
    super.initState();
    AppLogger.info(
      'WardrobeItemDetails: open id=${item.id} title="${item.title}"',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final wardrobe = context.read<WardrobeController>();
      setState(() => _isFavorite = wardrobe.isFavorite(item.id));
    });
  }

  Future<void> _toggleFavorite() async {
    if (_isDeleting) return;
    final wardrobe = context.read<WardrobeController>();
    final added = await wardrobe.toggleFavorite(item.id);
    if (!mounted) return;
    setState(() => _isFavorite = added);
  }

  Future<void> _openEdit() async {
    if (_isDeleting) return;

    final updated = await context.pushNamed<WardrobeItem>(
      RouteNames.addWardrobeItemName,
      extra: item,
    );
    if (!mounted || updated == null) return;
    context.pop(updated);
  }

  Future<void> _confirmDelete() async {
    if (_isDeleting) return;

    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black38,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(loc.wardrobeDeleteTitle),
        content: Text(loc.wardrobeDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              loc.delete,
              style: const TextStyle(color: AppBrandColors.pink),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      final persisted =
          await WardrobeRepository.instance.findItemById(item.id);
      final deleteId = persisted?.id ?? item.id;

      AppLogger.info(
        'WardrobeItemDetails: delete id=$deleteId '
        '(screen id=${item.id}, persisted=${persisted != null})',
      );

      final deleted = await WardrobeRepository.instance.deleteItem(deleteId);
      if (!mounted) return;

      if (!deleted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).wardrobeDeleteFailed),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.redAccent,
            ),
          );
        return;
      }

      AppLogger.info('WardrobeItemDetails: deleted $deleteId');
      context.pop(deleteId);
    } catch (e, stack) {
      AppLogger.error(
        'WardrobeItemDetails: delete failed',
        error: e,
        stackTrace: stack,
      );
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Не удалось удалить вещь'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final hasImage = item.hasDisplayImage;

    return Scaffold(
      backgroundColor: AppBrandColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppBrandColors.pink,
          onPressed: _isDeleting ? null : () => context.pop(),
        ),
        title: Text(
          loc.wardrobeDetailsTitle,
          style: const TextStyle(
            color: AppBrandColors.pink,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _isFavorite
                ? loc.wardrobeRemoveFromFavorites
                : loc.wardrobeAddToFavorites,
            onPressed: _isDeleting ? null : _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: AppBrandColors.pink,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: hasImage
                    ? WardrobeItemImage(item: item, iconSize: 72)
                    : _iconPreview(),
              ),
              const SizedBox(height: 24),
              Text(
                WardrobeCatalog.displayItemTitle(item),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppBrandColors.title,
                ),
              ),
              const SizedBox(height: 16),
              _DetailRow(
                label: loc.wardrobeFieldCategory,
                value: WardrobeCatalog.displayCategory(item.category),
              ),
              _DetailRow(
                label: loc.wardrobeFieldColor,
                value: WardrobeCatalog.displayColor(item.color),
              ),
              const SizedBox(height: 8),
              Text(
                loc.wardrobeStyleContext,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppBrandColors.pink,
                ),
              ),
              const SizedBox(height: 12),
              _MetadataCard(
                label: loc.wardrobeStyleAesthetic,
                values: item.styles,
              ),
              _MetadataCard(
                label: loc.wardrobeOccasion,
                values: item.occasions,
              ),
              _MetadataCard(
                label: loc.wardrobeFit,
                values: item.fit.isNotEmpty ? [item.fit] : const [],
              ),
              _MetadataCard(
                label: loc.wardrobeSeason,
                values: item.season.isNotEmpty ? [item.season] : const [],
              ),
              _MetadataCard(label: loc.wardrobeVibe, values: item.vibes),
              if (!item.hasStyleMetadata)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    loc.wardrobeNoStyleTags,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isDeleting ? null : _openEdit,
                icon: const Icon(Icons.edit_outlined),
                label: Text(loc.wardrobeEdit),
                style: FilledButton.styleFrom(
                  backgroundColor: AppBrandColors.pink,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isDeleting ? null : _confirmDelete,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded),
                label: Text(
                  _isDeleting ? loc.wardrobeDeleting : loc.wardrobeDeleteItem,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey.shade300),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
          if (_isDeleting)
            Container(
              color: Colors.black.withValues(alpha: 0.08),
              alignment: Alignment.center,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppBrandColors.pink),
                      const SizedBox(height: 14),
                      Text(
                        loc.wardrobeDeleting,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _iconPreview() {
    return Container(
      color: AppBrandColors.iconBackground,
      alignment: Alignment.center,
      child: Icon(
        item.placeholderIcon,
        size: 96,
        color: AppBrandColors.pink.withValues(alpha: 0.85),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppBrandColors.title,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.label, required this.values});

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            WardrobeMetadataChips(
              values: values,
              valueLabel: WardrobeCatalog.displayMetadata,
            ),
          ],
        ),
      ),
    );
  }
}
