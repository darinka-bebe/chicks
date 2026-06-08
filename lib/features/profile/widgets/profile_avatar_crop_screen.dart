import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_brand_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/utils/logger.dart';

/// Bottom-sheet crop editor for profile avatar (1:1, not full screen).
class ProfileAvatarCropSheet extends StatefulWidget {
  const ProfileAvatarCropSheet({super.key, required this.sourcePath});

  final String sourcePath;

  @override
  State<ProfileAvatarCropSheet> createState() => _ProfileAvatarCropSheetState();
}

class _ProfileAvatarCropSheetState extends State<ProfileAvatarCropSheet> {
  final _cropController = CropController();
  Uint8List? _imageBytes;
  String? _loadError;
  bool _isSaving = false;
  bool _cropReady = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final file = File(widget.sourcePath);
      if (!await file.exists()) {
        if (!mounted) return;
        final loc = AppLocalizations.of(context);
        setState(() => _loadError = loc.profileAvatarFileNotFound);
        return;
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        if (!mounted) return;
        final loc = AppLocalizations.of(context);
        setState(() => _loadError = loc.profileAvatarEmptyFile);
        return;
      }
      if (!mounted) return;
      setState(() => _imageBytes = bytes);
    } catch (e, stack) {
      AppLogger.error(
        'ProfileAvatarCropSheet: load failed',
        error: e,
        stackTrace: stack,
      );
      if (!mounted) return;
      final loc = AppLocalizations.of(context);
      setState(() => _loadError = loc.profileAvatarOpenFailed);
    }
  }

  Future<void> _onCropped(Uint8List cropped) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final jpeg = _encodeAvatarJpeg(cropped);
      if (jpeg == null || jpeg.isEmpty) {
        throw StateError('jpeg encode failed');
      }

      final dir = await getTemporaryDirectory();
      final outPath =
          '${dir.path}/avatar_crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(outPath).writeAsBytes(jpeg, flush: true);
      if (!mounted) return;
      Navigator.of(context).pop(outPath);
    } catch (e, stack) {
      AppLogger.error(
        'ProfileAvatarCropSheet: save failed',
        error: e,
        stackTrace: stack,
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.profileAvatarCropSaveFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Uint8List? _encodeAvatarJpeg(Uint8List raw) {
    final decoded = img.decodeImage(raw);
    if (decoded == null) return null;

    const maxSide = 1024;
    var working = decoded;
    if (decoded.width > maxSide || decoded.height > maxSide) {
      working = decoded.width >= decoded.height
          ? img.copyResize(decoded, width: maxSide)
          : img.copyResize(decoded, height: maxSide);
    }

    return Uint8List.fromList(img.encodeJpg(working, quality: 92));
  }

  void _applyCrop() {
    if (!_cropReady || _isSaving || _imageBytes == null) return;
    _cropController.crop();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.72;
    final cropHeight = (MediaQuery.sizeOf(context).width * 1.05)
        .clamp(280.0, maxSheetHeight - 120);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                      Expanded(
                        child: Text(
                          loc.profileAvatarCropTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppBrandColors.title,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed:
                            _cropReady && !_isSaving ? _applyCrop : null,
                        child: Text(
                          _isSaving ? '…' : loc.profileAvatarCropDone,
                          style: TextStyle(
                            color: _cropReady && !_isSaving
                                ? AppBrandColors.pink
                                : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: cropHeight,
                    width: double.infinity,
                    child: ColoredBox(
                      color: Colors.black,
                      child: _buildCropArea(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCropArea() {
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _loadError!,
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final bytes = _imageBytes;
    if (bytes == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppBrandColors.pink),
      );
    }

    return Crop(
      image: bytes,
      controller: _cropController,
      aspectRatio: 1,
      interactive: true,
      fixCropRect: false,
      withCircleUi: false,
      initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
        size: 0.88,
        aspectRatio: 1,
      ),
      baseColor: Colors.black,
      maskColor: Colors.black.withValues(alpha: 0.5),
      progressIndicator: const SizedBox.shrink(),
      radius: 0,
      onStatusChanged: (status) {
        final ready = status == CropStatus.ready;
        if (ready != _cropReady && mounted) {
          setState(() => _cropReady = ready);
        }
      },
      onCropped: (result) {
        switch (result) {
          case CropSuccess(:final croppedImage):
            _onCropped(croppedImage);
          case CropFailure(:final cause, :final stackTrace):
            AppLogger.error(
              'ProfileAvatarCropSheet: crop failed',
              error: cause,
              stackTrace: stackTrace,
            );
            if (!mounted) return;
            setState(() => _isSaving = false);
            final loc = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc.profileAvatarCropFailed),
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
      },
    );
  }
}
