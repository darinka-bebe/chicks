import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/wardrobe_image_storage.dart';
import '../../../core/utils/logger.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/theme/chicks_input_styles.dart';
import '../../../data/models/wardrobe_item.dart';
import '../../../data/repositories/wardrobe_repository.dart';
import '../../../core/constants/wardrobe_catalog.dart';
import '../widgets/wardrobe_chip_selector.dart';

class AddWardrobeItemScreen extends StatefulWidget {
  const AddWardrobeItemScreen({super.key});

  @override
  State<AddWardrobeItemScreen> createState() => _AddWardrobeItemScreenState();
}

class _AddWardrobeItemScreenState extends State<AddWardrobeItemScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _colorController = TextEditingController();
  final _picker = ImagePicker();

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  String? _imagePath;
  String _category = WardrobeCatalog.categories.first;
  List<String> _selectedStyles = [];
  List<String> _selectedOccasions = [];
  List<String> _selectedFit = [];
  List<String> _selectedSeason = [WardrobeCatalog.seasons.last];
  List<String> _selectedVibes = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _titleController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (picked == null || !mounted) return;

      final savedPath = await WardrobeImageStorage.persistFromXFile(picked);
      if (!mounted) return;

      if (savedPath == null) {
        _showMessage('Не удалось загрузить изображение');
        return;
      }

      setState(() => _imagePath = savedPath);
    } catch (_) {
      if (mounted) {
        _showMessage('Ошибка доступа к галерее');
      }
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  bool _validateRequiredFields() {
    final title = _titleController.text.trim();
    final category = _category.trim();

    if (title.isEmpty) {
      AppLogger.debug('AddWardrobeItem: validation failed — empty title');
      _showMessage('Введите название');
      _formKey.currentState?.validate();
      return false;
    }

    if (category.isEmpty) {
      AppLogger.debug('AddWardrobeItem: validation failed — empty category');
      _showMessage('Выберите категорию');
      return false;
    }

    return true;
  }

  Future<void> _saveItem() async {
    AppLogger.debug('AddWardrobeItem: save button pressed');

    if (_isSaving) {
      AppLogger.debug('AddWardrobeItem: save ignored — already saving');
      return;
    }

    if (!_validateRequiredFields()) return;

    setState(() => _isSaving = true);
    AppLogger.info('AddWardrobeItem: saving…');

    try {
      final colorRaw = _colorController.text.trim();
      final item = WardrobeItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        category: _category,
        color: colorRaw.isEmpty ? 'Не указан' : colorRaw,
        season: _selectedSeason.isNotEmpty
            ? _selectedSeason.first
            : WardrobeCatalog.seasons.last,
        fit: _selectedFit.isNotEmpty ? _selectedFit.first : '',
        styles: List<String>.from(_selectedStyles),
        occasions: List<String>.from(_selectedOccasions),
        vibes: List<String>.from(_selectedVibes),
        imagePath: _imagePath,
      );

      AppLogger.debug(
        'AddWardrobeItem: created item id=${item.id} '
        'title="${item.title}" category=${item.category}',
      );

      await WardrobeRepository.instance.addItem(item);

      if (!mounted) return;

      AppLogger.info('AddWardrobeItem: saved, closing screen');
      context.pop(item);
    } catch (error, stackTrace) {
      AppLogger.error(
        'AddWardrobeItem: save failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      _showMessage('Не удалось сохранить вещь');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppBrandColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          color: AppBrandColors.pink,
          onPressed: _isSaving ? null : () => context.pop(),
        ),
        title: const Text(
          'Новая вещь',
          style: TextStyle(
            color: AppBrandColors.pink,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: _ImagePickerCard(
                imagePath: _imagePath,
                onPick: _pickImage,
              ),
            ),
            const SizedBox(height: 20),
            _ChicksTextField(
              controller: _titleController,
              label: 'Название',
              hint: 'Например, белая рубашка',
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите название';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _ChicksDropdownField(
              label: 'Категория',
              value: _category,
              items: WardrobeCatalog.categories,
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 14),
            _ChicksTextField(
              controller: _colorController,
              label: 'Цвет',
              hint: 'Например, бежевый (необязательно)',
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            const _SectionHeader(
              title: 'Стиль и контекст',
              subtitle: 'Поможет AI-стилисту подбирать образы точнее',
            ),
            const SizedBox(height: 14),
            _MetadataPanel(
              children: [
                WardrobeChipSelector(
                  label: 'Стиль / эстетика',
                  subtitle: 'Можно выбрать несколько',
                  options: WardrobeCatalog.styles,
                  selected: _selectedStyles,
                  onChanged: (value) => setState(() => _selectedStyles = value),
                ),
                const SizedBox(height: 18),
                WardrobeChipSelector(
                  label: 'Повод',
                  subtitle: 'Можно выбрать несколько',
                  options: WardrobeCatalog.occasions,
                  selected: _selectedOccasions,
                  onChanged: (value) =>
                      setState(() => _selectedOccasions = value),
                ),
                const SizedBox(height: 18),
                WardrobeChipSelector(
                  label: 'Посадка',
                  options: WardrobeCatalog.fits,
                  selected: _selectedFit,
                  allowMultiple: false,
                  onChanged: (value) => setState(() => _selectedFit = value),
                ),
                const SizedBox(height: 18),
                WardrobeChipSelector(
                  label: 'Сезон',
                  options: WardrobeCatalog.seasons,
                  selected: _selectedSeason,
                  allowMultiple: false,
                  onChanged: (value) => setState(() => _selectedSeason = value),
                ),
                const SizedBox(height: 18),
                WardrobeChipSelector(
                  label: 'Вайб',
                  subtitle: 'Можно выбрать несколько',
                  options: WardrobeCatalog.vibes,
                  selected: _selectedVibes,
                  onChanged: (value) => setState(() => _selectedVibes = value),
                ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _isSaving ? null : () => _saveItem(),
              style: FilledButton.styleFrom(
                backgroundColor: AppBrandColors.pink,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Сохранить',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppBrandColors.pink,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }
}

class _MetadataPanel extends StatelessWidget {
  const _MetadataPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.imagePath,
    required this.onPick,
  });

  final String? imagePath;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    final hasImage = path != null && path.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: hasImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      ),
                      const Positioned(
                        right: 12,
                        bottom: 12,
                        child: _PhotoBadge(label: 'Изменить фото'),
                      ),
                    ],
                  )
                : _placeholder(),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppBrandColors.iconBackground,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.add_a_photo_outlined,
            color: AppBrandColors.pink,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Добавить фото',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppBrandColors.title,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Из галереи',
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        ),
      ],
    );
  }
}

class _PhotoBadge extends StatelessWidget {
  const _PhotoBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class _ChicksTextField extends StatefulWidget {
  const _ChicksTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;

  @override
  State<_ChicksTextField> createState() => _ChicksTextFieldState();
}

class _ChicksTextFieldState extends State<_ChicksTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppBrandColors.title,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          validator: widget.validator,
          enabled: true,
          readOnly: false,
          enableInteractiveSelection: true,
          keyboardType: TextInputType.text,
          textInputAction: widget.textInputAction,
          style: ChicksInputStyles.value,
          decoration: ChicksInputStyles.decoration(hintText: widget.hint),
        ),
      ],
    );
  }
}

class _ChicksDropdownField extends StatelessWidget {
  const _ChicksDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppBrandColors.title,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey(value),
          initialValue: value,
          style: ChicksInputStyles.value,
          dropdownColor: Colors.white,
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: ChicksInputStyles.value),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: ChicksInputStyles.filledShell(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
          ),
        ),
      ],
    );
  }
}
