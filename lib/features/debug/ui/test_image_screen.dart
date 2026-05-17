import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_brand_colors.dart';
import '../../../core/utils/logger.dart';

/// Isolated image_picker test — no wardrobe, no persistence.
///
/// Open via Profile → "Image Picker Test" or route `/debug/test-image`.
class TestImageScreen extends StatefulWidget {
  const TestImageScreen({super.key});

  @override
  State<TestImageScreen> createState() => _TestImageScreenState();
}

class _TestImageScreenState extends State<TestImageScreen> {
  final ImagePicker _picker = ImagePicker();

  bool _isPicking = false;
  Uint8List? _previewBytes;
  String _log = 'Tap "Pick Image" to start.\n';
  String? _xFilePath;
  String? _savedPath;
  String? _lastError;

  void _appendLog(String message) {
    final line = '[${DateTime.now().toIso8601String()}] $message';
    AppLogger.debug('TestImageScreen: $message');
    setState(() {
      _log = '$_log$line\n';
    });
  }

  void _showError(String message, {Object? error, StackTrace? stack}) {
    AppLogger.error(
      'TestImageScreen: $message',
      error: error,
      stackTrace: stack,
    );
    if (!mounted) return;
    setState(() => _lastError = message);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
  }

  Future<void> _pickImage() async {
    if (_isPicking) return;

    setState(() {
      _isPicking = true;
      _lastError = null;
      _previewBytes = null;
      _xFilePath = null;
      _savedPath = null;
    });

    _appendLog('STEP 1: pickImage(gallery) started');

    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (!mounted) return;

      if (picked == null) {
        _appendLog('STEP 2: user cancelled — no image selected');
        return;
      }

      _appendLog('STEP 2: XFile received');
      _appendLog('  name: ${picked.name}');
      _appendLog('  path: ${picked.path}');
      _appendLog('  mimeType: ${picked.mimeType ?? "null"}');

      setState(() => _xFilePath = picked.path);

      _appendLog('STEP 3: readAsBytes()');
      final bytes = await picked.readAsBytes();
      _appendLog('  bytes length: ${bytes.length}');

      if (bytes.isEmpty) {
        _showError('readAsBytes returned empty (0 bytes)');
        return;
      }

      String? fileExistsNote;
      try {
        final path = picked.path;
        if (path.isNotEmpty) {
          final file = File(path);
          final exists = file.existsSync();
          final length = exists ? file.lengthSync() : 0;
          fileExistsNote = 'File("$path") exists=$exists length=$length';
          _appendLog('STEP 4: $fileExistsNote');
          setState(() => _savedPath = path);
        } else {
          _appendLog('STEP 4: XFile.path is empty (content URI only)');
        }
      } catch (e, st) {
        _appendLog('STEP 4: File(path) check failed: $e');
        AppLogger.error('File check failed', error: e, stackTrace: st);
      }

      _appendLog('STEP 5: setState — preview via Image.memory');
      setState(() => _previewBytes = bytes);
      _appendLog('STEP 6: done — preview should be visible');
    } catch (e, st) {
      _appendLog('CRASH POINT: exception in _pickImage');
      _appendLog('  $e');
      _showError('Pick failed: $e', error: e, stack: st);
    } finally {
      if (mounted) setState(() => _isPicking = false);
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
            onPressed: _isPicking ? null : _pickImage,
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
            label: Text(_isPicking ? 'Picking…' : 'Pick Image'),
            style: FilledButton.styleFrom(
              backgroundColor: AppBrandColors.pink,
              foregroundColor: Colors.white,
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
          if (_previewBytes != null) ...[
            const Text(
              'Preview (Image.memory — bytes)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                _previewBytes!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, error, __) {
                  AppLogger.error('Image.memory error', error: error);
                  return _previewError('Image.memory failed: $error');
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_savedPath != null && _savedPath!.isNotEmpty) ...[
            const Text(
              'Preview (Image.file — path)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(_savedPath!),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, error, __) {
                  AppLogger.error('Image.file error', error: error);
                  return _previewError('Image.file failed: $error');
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'XFile.path: ${_xFilePath ?? "—"}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
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
