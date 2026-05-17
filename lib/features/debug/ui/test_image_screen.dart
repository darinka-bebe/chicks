import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/gallery_image_picker_service.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../core/utils/logger.dart';

/// Isolated image_picker test — no wardrobe model persistence.
///
/// Open via route `/debug/test-image`.
class TestImageScreen extends StatefulWidget {
  const TestImageScreen({super.key});

  @override
  State<TestImageScreen> createState() => _TestImageScreenState();
}

class _TestImageScreenState extends State<TestImageScreen> {
  final ImagePicker _picker = ImagePicker();

  bool _isPicking = false;
  String? _savedPath;
  String? _lastError;
  String _log = 'Tap "Pick Image" to start.\n';

  void _appendLog(String message) {
    final line = '[${DateTime.now().toIso8601String()}] $message';
    AppLogger.debug('TestImageScreen: $message');
    setState(() {
      _log = '$_log$line\n';
    });
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : AppBrandColors.pink,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: isError ? 5 : 3),
        ),
      );
  }

  Future<void> _pickImage(ImageImportMethod method) async {
    if (_isPicking) return;

    setState(() {
      _isPicking = true;
      _lastError = null;
      _savedPath = null;
    });

    _appendLog('import started: $method');

    try {
      final result = switch (method) {
        ImageImportMethod.gallery =>
          await GalleryImagePickerService.pickFromGallery(picker: _picker),
        ImageImportMethod.files =>
          await GalleryImagePickerService.pickFromFiles(),
      };

      if (!mounted) return;

      _appendLog('status: ${result.status} path: ${result.localPath}');

      switch (result.status) {
        case GalleryPickStatus.success:
          final path = result.localPath;
          if (path == null || path.isEmpty) {
            _lastError = 'Success but path is null';
            _showSnackBar('Путь к файлу пустой', isError: true);
            break;
          }
          setState(() => _savedPath = path);
          _showSnackBar(result.message ?? 'Фото сохранено', isError: false);
          _appendLog('preview path: $path');
        case GalleryPickStatus.cancelled:
          _showSnackBar(
            result.message ?? 'Фото не выбрано',
            isError: false,
          );
        case GalleryPickStatus.permissionDenied:
          _lastError = result.message;
          _showSnackBar(
            result.message ?? 'Нет доступа к галерее',
            isError: true,
          );
          await GalleryImagePickerService.openAppSettingsIfNeeded();
        case GalleryPickStatus.failed:
          _lastError = result.message;
          _showSnackBar(
            result.message ?? 'Ошибка при выборе фото',
            isError: true,
          );
      }
    } catch (e, st) {
      _appendLog('exception: $e');
      AppLogger.error('TestImageScreen._pickImage', error: e, stackTrace: st);
      _lastError = e.toString();
      _showSnackBar('Pick failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedPath = _savedPath;

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
          'Image Picker Test',
          style: TextStyle(
            color: AppBrandColors.pink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (kDebugMode)
            Text(
              'Debug build • ${Platform.operatingSystem}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _isPicking
                ? null
                : () => _pickImage(ImageImportMethod.gallery),
            icon: _isPicking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.photo_library_outlined),
            label: Text(_isPicking ? 'Picking…' : 'Gallery'),
            style: FilledButton.styleFrom(
              backgroundColor: AppBrandColors.pink,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isPicking
                ? null
                : () => _pickImage(ImageImportMethod.files),
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('File (Downloads / SAF)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppBrandColors.pink,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          if (_lastError != null) ...[
            const SizedBox(height: 12),
            Text(
              'Last error: $_lastError',
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          if (savedPath != null && savedPath.isNotEmpty) ...[
            const Text(
              'Preview (saved in app storage)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(savedPath),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, error, __) {
                  AppLogger.error('Image.file preview error', error: error);
                  return _previewError('Preview failed: $error');
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Path: $savedPath',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Debug log',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _log,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: Colors.grey[800],
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewError(String message) {
    return Container(
      height: 220,
      color: AppBrandColors.iconBackground,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
      ),
    );
  }
}
