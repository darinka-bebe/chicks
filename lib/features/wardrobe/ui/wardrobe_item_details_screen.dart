import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_brand_colors.dart';
import '../../../data/models/wardrobe_item.dart';
import '../../../data/repositories/wardrobe_repository.dart';
import '../widgets/wardrobe_chip_selector.dart';

class WardrobeItemDetailsScreen extends StatelessWidget {
  const WardrobeItemDetailsScreen({super.key, required this.item});

  final WardrobeItem item;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Удалить вещь?'),
        content: Text('«${item.title}» будет удалена из гардероба.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await WardrobeRepository.instance.deleteItem(item.id);
    if (context.mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = item.imagePath;
    final hasImage = imagePath != null && imagePath.isNotEmpty;

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
          'Детали вещи',
          style: TextStyle(
            color: AppBrandColors.pink,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
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
                ? Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _iconPreview(),
                  )
                : _iconPreview(),
          ),
          const SizedBox(height: 24),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppBrandColors.title,
            ),
          ),
          const SizedBox(height: 16),
          _DetailRow(label: 'Категория', value: item.category),
          _DetailRow(label: 'Цвет', value: item.color),
          const SizedBox(height: 8),
          const Text(
            'Стиль и контекст',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppBrandColors.pink,
            ),
          ),
          const SizedBox(height: 12),
          _MetadataCard(
            label: 'Стиль / эстетика',
            values: item.styles,
          ),
          _MetadataCard(
            label: 'Повод',
            values: item.occasions,
          ),
          _MetadataCard(
            label: 'Посадка',
            values: item.fit.isNotEmpty ? [item.fit] : const [],
          ),
          _MetadataCard(
            label: 'Сезон',
            values: item.season.isNotEmpty ? [item.season] : const [],
          ),
          _MetadataCard(
            label: 'Вайб',
            values: item.vibes,
          ),
          if (!item.hasStyleMetadata)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                'Теги стиля не заданы — добавьте их при создании новой вещи.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Удалить вещь'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
            WardrobeMetadataChips(values: values),
          ],
        ),
      ),
    );
  }
}
