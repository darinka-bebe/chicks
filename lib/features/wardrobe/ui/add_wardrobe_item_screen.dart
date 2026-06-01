import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/gallery_image_picker_service.dart';
import '../../../core/services/openai_chat_service.dart';
import '../../../core/services/wardrobe_duplicate_detector.dart';
import '../../../core/utils/logger.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/theme/chicks_input_styles.dart';
import '../../../data/models/clothing_vision_analysis.dart';
import '../../../data/models/wardrobe_item.dart';
import '../../../data/repositories/clothing_vision_repository.dart';
import '../../../data/repositories/wardrobe_repository.dart';
import '../../../core/constants/wardrobe_catalog.dart';
import '../widgets/wardrobe_chip_selector.dart';

class AddWardrobeItemScreen extends StatefulWidget {
  const AddWardrobeItemScreen({super.key, this.editItem});

  /// When set, screen updates an existing wardrobe row instead of adding.
  final WardrobeItem? editItem;

  bool get isEditing => editItem != null;

  @override
  State<AddWardrobeItemScreen> createState() => _AddWardrobeItemScreenState();
}

class _AddWardrobeItemScreenState extends State<AddWardrobeItemScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _colorController = TextEditingController();
  final _picker = ImagePicker();
  final _visionRepository = ClothingVisionRepository();

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
  bool _isAnalyzing = false;
  bool _visionAnalysisFailed = false;
  WardrobeDuplicateMatch? _duplicateMatch;

  WardrobeItem? get _editingItem => widget.editItem;

  @override
  void initState() {
    super.initState();
    final editing = _editingItem;
    if (editing != null) {
      _titleController.text = editing.title;
      final color = editing.color.trim();
      _colorController.text =
          color.isEmpty || color == 'Не указан' ? '' : color;
      _category = WardrobeCatalog.categories.contains(editing.category)
          ? editing.category
          : WardrobeCatalog.categories.first;
      _imagePath = editing.imagePath;
      _selectedStyles = List<String>.from(editing.styles);
      _selectedOccasions = List<String>.from(editing.occasions);
      _selectedFit =
          editing.fit.trim().isEmpty ? [] : <String>[editing.fit.trim()];
      _selectedSeason = editing.season.trim().isEmpty
          ? [WardrobeCatalog.seasons.last]
          : <String>[editing.season.trim()];
      _selectedVibes = List<String>.from(editing.vibes);
    }
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

  Future<ImageImportMethod?> _askImportMethod() async {
    return showModalBottomSheet<ImageImportMethod>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Добавить фото',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppBrandColors.title,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'На эмуляторе надёжнее «Файл» → Downloads',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppBrandColors.pink),
                title: const Text('Галерея'),
                subtitle: const Text('Системный выбор фото'),
                onTap: () =>
                    Navigator.pop(sheetContext, ImageImportMethod.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.folder_open_outlined,
                    color: AppBrandColors.pink),
                title: const Text('Файл'),
                subtitle: const Text('Downloads, Documents, Files'),
                onTap: () =>
                    Navigator.pop(sheetContext, ImageImportMethod.files),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyPickedImage(String path) async {
    setState(() {
      _imagePath = path;
      _visionAnalysisFailed = false;
      _duplicateMatch = null;
    });
  }

  Future<void> _refreshDuplicateHint({ClothingVisionAnalysis? vision}) async {
    final excludeId = _editingItem?.id;
    final all = await WardrobeRepository.instance.loadItems();
    final wardrobe = excludeId == null
        ? all
        : all
            .where((row) => !WardrobeRepository.idEquals(row.id, excludeId))
            .toList();

    final match = WardrobeDuplicateDetector.evaluate(
      title: _titleController.text.trim(),
      category: _category,
      color: _colorController.text.trim().isEmpty
          ? 'Не указан'
          : _colorController.text.trim(),
      wardrobe: wardrobe,
      vision: vision,
    );

    if (!mounted) return;
    setState(() => _duplicateMatch = match);
  }

  Future<bool> _confirmSaveDespiteDuplicate(WardrobeDuplicateMatch match) async {
    final editing = widget.isEditing;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(editing ? 'Похожая вещь в гардеробе' : 'Вещь уже в гардеробе'),
        content: Text(
          'Совпадает с ${match.label}.\n\n'
          '${editing ? 'Если это другая вещь — нажмите «Всё равно сохранить».' : 'Если на фото другая вещь — нажмите «Всё равно добавить».'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              editing ? 'Всё равно сохранить' : 'Всё равно добавить',
              style: const TextStyle(color: AppBrandColors.pink),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _pickImage() async {
    final method = await _askImportMethod();
    if (method == null || !mounted) return;

    final result = switch (method) {
      ImageImportMethod.gallery => await GalleryImagePickerService.pickFromGallery(
          picker: _picker,
        ),
      ImageImportMethod.files => await GalleryImagePickerService.pickFromFiles(),
    };
    if (!mounted) return;

    switch (result.status) {
      case GalleryPickStatus.success:
        final path = result.localPath;
        if (path == null || path.isEmpty) {
          _showSnackBar(
            result.message ?? 'Не удалось сохранить фото',
            isError: true,
          );
          return;
        }
        await _applyPickedImage(path);
        if (!mounted) return;
        await precacheImage(FileImage(File(path)), context);
        if (!mounted) return;
        _showSnackBar(result.message ?? 'Фото добавлено', isError: false);
        await _runVisionAnalysis(path);
      case GalleryPickStatus.cancelled:
        break;
      case GalleryPickStatus.permissionDenied:
        _showSnackBar(
          result.message ?? 'Нет доступа к галерее',
          isError: true,
        );
        await GalleryImagePickerService.openAppSettingsIfNeeded();
      case GalleryPickStatus.failed:
        _showSnackBar(
          result.message ?? 'Ошибка при выборе фото',
          isError: true,
        );
    }
  }

  Future<void> _runVisionAnalysis(String imagePath) async {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _visionAnalysisFailed = false;
    });

    try {
      final analysis = await _visionRepository.analyzeImage(imagePath);
      if (!mounted) return;
      _applyVisionAnalysis(analysis);
      await _refreshDuplicateHint(vision: analysis);
      if (!mounted) return;
      if (_duplicateMatch != null) {
        _showSnackBar(
          'Это та же вещь, что уже в гардеробе — проверьте перед сохранением',
          isError: true,
        );
      } else {
        _showSnackBar(
          'AI заполнил поля — проверьте и отредактируйте при необходимости',
          isError: false,
        );
      }
    } on OpenAiChatException catch (e, stack) {
      AppLogger.error(
        'AddWardrobeItem: vision analysis failed',
        error: e,
        stackTrace: stack,
      );
      if (!mounted) return;
      setState(() => _visionAnalysisFailed = true);
      _showSnackBar(
        '${e.message} Можно заполнить вручную или повторить анализ.',
        isError: true,
      );
    } catch (e, stack) {
      AppLogger.error(
        'AddWardrobeItem: vision unexpected error',
        error: e,
        stackTrace: stack,
      );
      if (!mounted) return;
      setState(() => _visionAnalysisFailed = true);
      _showSnackBar(
        'Не удалось распознать вещь. Заполните поля вручную или повторите.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _applyVisionAnalysis(ClothingVisionAnalysis analysis) {
    setState(() {
      if (analysis.title.isNotEmpty) {
        _titleController.text = analysis.title;
      }
      if (analysis.color.isNotEmpty) {
        _colorController.text = analysis.color;
      }
      if (WardrobeCatalog.categories.contains(analysis.category)) {
        _category = analysis.category;
      }
      if (analysis.styles.isNotEmpty) {
        _selectedStyles = List<String>.from(analysis.styles);
      }
      if (analysis.seasons.isNotEmpty) {
        _selectedSeason = [analysis.seasons.first];
      }
      if (analysis.occasions.isNotEmpty) {
        _selectedOccasions = List<String>.from(analysis.occasions);
      }
      if (analysis.vibes.isNotEmpty) {
        _selectedVibes = List<String>.from(analysis.vibes);
      }
      if (analysis.fit.isNotEmpty) {
        _selectedFit = [analysis.fit];
      }
    });
  }

  void _showSnackBar(String text, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.redAccent : AppBrandColors.pink,
        ),
      );
  }

  bool _validateRequiredFields() {
    final title = _titleController.text.trim();
    final category = _category.trim();

    if (title.isEmpty) {
      AppLogger.debug('AddWardrobeItem: validation failed — empty title');
      _showSnackBar('Введите название', isError: true);
      _formKey.currentState?.validate();
      return false;
    }

    if (category.isEmpty) {
      AppLogger.debug('AddWardrobeItem: validation failed — empty category');
      _showSnackBar('Выберите категорию', isError: true);
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

    await _refreshDuplicateHint();
    if (!mounted) return;

    if (_duplicateMatch != null) {
      final proceed = await _confirmSaveDespiteDuplicate(_duplicateMatch!);
      if (!mounted || !proceed) return;
    }

    setState(() => _isSaving = true);
    AppLogger.info('AddWardrobeItem: saving…');

    try {
      final colorRaw = _colorController.text.trim();
      final editing = _editingItem;
      final item = WardrobeItem(
        id: editing?.id ?? WardrobeRepository.generateItemId(),
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
        imagePath: _imagePath ?? editing?.imagePath,
        imageUrl: editing?.imageUrl,
      );

      AppLogger.debug(
        'AddWardrobeItem: ${editing != null ? 'update' : 'create'} id=${item.id} '
        'title="${item.title}" category=${item.category}',
      );

      final persisted = editing != null
          ? await WardrobeRepository.instance.updateItem(item)
          : await WardrobeRepository.instance.addItem(item);

      if (!mounted) return;

      AppLogger.info(
        'AddWardrobeItem: saved id=${persisted.id}, closing screen',
      );
      context.pop(persisted);
    } catch (error, stackTrace) {
      AppLogger.error(
        'AddWardrobeItem: save failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      _showSnackBar('Не удалось сохранить вещь', isError: true);
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
          onPressed: _isSaving || _isAnalyzing ? null : () => context.pop(),
        ),
        title: Text(
          widget.isEditing ? 'Редактировать' : 'Новая вещь',
          style: const TextStyle(
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
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: _ImagePickerCard(
                imagePath: _imagePath,
                isAnalyzing: _isAnalyzing,
                analysisFailed: _visionAnalysisFailed,
                onPick: _isAnalyzing ? null : _pickImage,
              ),
            ),
            if (_isAnalyzing) ...[
              const SizedBox(height: 12),
              const _VisionAnalyzingBanner(),
            ],
            if (_visionAnalysisFailed && !_isAnalyzing && _imagePath != null) ...[
              const SizedBox(height: 12),
              _VisionRetryBanner(
                onRetry: () => _runVisionAnalysis(_imagePath!),
              ),
            ],
            if (_duplicateMatch != null && !_isAnalyzing) ...[
              const SizedBox(height: 12),
              _DuplicateWarningBanner(match: _duplicateMatch!),
            ],
            const SizedBox(height: 20),
            _ChicksTextField(
              controller: _titleController,
              label: 'Название',
              enabled: !_isAnalyzing,
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
              enabled: !_isAnalyzing,
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
              enabled: !_isAnalyzing,
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
                  enabled: !_isAnalyzing,
                  onChanged: (value) => setState(() => _selectedStyles = value),
                ),
                const SizedBox(height: 18),
                WardrobeChipSelector(
                  label: 'Повод',
                  subtitle: 'Можно выбрать несколько',
                  options: WardrobeCatalog.occasions,
                  selected: _selectedOccasions,
                  enabled: !_isAnalyzing,
                  onChanged: (value) =>
                      setState(() => _selectedOccasions = value),
                ),
                const SizedBox(height: 18),
                WardrobeChipSelector(
                  label: 'Посадка',
                  options: WardrobeCatalog.fits,
                  selected: _selectedFit,
                  allowMultiple: false,
                  enabled: !_isAnalyzing,
                  onChanged: (value) => setState(() => _selectedFit = value),
                ),
                const SizedBox(height: 18),
                WardrobeChipSelector(
                  label: 'Сезон',
                  options: WardrobeCatalog.seasons,
                  selected: _selectedSeason,
                  allowMultiple: false,
                  enabled: !_isAnalyzing,
                  onChanged: (value) => setState(() => _selectedSeason = value),
                ),
                const SizedBox(height: 18),
                WardrobeChipSelector(
                  label: 'Вайб',
                  subtitle: 'Можно выбрать несколько',
                  options: WardrobeCatalog.vibes,
                  selected: _selectedVibes,
                  enabled: !_isAnalyzing,
                  onChanged: (value) => setState(() => _selectedVibes = value),
                ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _isSaving || _isAnalyzing ? null : () => _saveItem(),
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

class _VisionAnalyzingBanner extends StatelessWidget {
  const _VisionAnalyzingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppBrandColors.iconBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppBrandColors.pink.withValues(alpha: 0.2),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppBrandColors.pink,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI анализирует вещь...',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppBrandColors.title,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DuplicateWarningBanner extends StatelessWidget {
  const _DuplicateWarningBanner({required this.match});

  final WardrobeDuplicateMatch match;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.orange.shade800, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Похоже, вы снова добавляете ту же вещь: ${match.label}. '
              'Если это другая вещь (например, другие джинсы) — сохраните, мы уточним название.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppBrandColors.title,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisionRetryBanner extends StatelessWidget {
  const _VisionRetryBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onRetry,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.refresh_rounded, color: Colors.grey[700], size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI не смог распознать вещь. Заполните вручную или повторите.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ),
              const Text(
                'Повторить',
                style: TextStyle(
                  color: AppBrandColors.pink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.imagePath,
    required this.onPick,
    this.isAnalyzing = false,
    this.analysisFailed = false,
  });

  final String? imagePath;
  final VoidCallback? onPick;
  final bool isAnalyzing;
  final bool analysisFailed;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    final hasImage = path != null && path.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isAnalyzing ? null : onPick,
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
                      if (isAnalyzing)
                        Container(
                          color: Colors.black.withValues(alpha: 0.35),
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.white,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'AI анализирует вещь...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!isAnalyzing)
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: _PhotoBadge(
                            label: analysisFailed
                                ? 'Изменить фото'
                                : 'Изменить фото',
                          ),
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
          'Галерея или файл',
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
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final bool enabled;

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
          enabled: widget.enabled,
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
    this.enabled = true,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool enabled;

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
          onChanged: enabled ? onChanged : null,
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
