import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../utils/logger.dart';

/// Logs and validates picked images (emulator-friendly debugging).
abstract final class ImageImportDiagnostics {
  static Future<ImageValidationResult> validatePath(String path) async {
    AppLogger.debug('ImageImportDiagnostics: validate path=$path');

    if (path.trim().isEmpty) {
      return const ImageValidationResult(
        exists: false,
        decodeOk: false,
        byteLength: 0,
        message: 'Путь к файлу пустой',
      );
    }

    final file = File(path);
    final exists = await file.exists();
    AppLogger.debug('ImageImportDiagnostics: exists=$exists');

    if (!exists) {
      return ImageValidationResult(
        exists: false,
        decodeOk: false,
        byteLength: 0,
        message: 'Файл не найден: $path',
      );
    }

    final byteLength = await file.length();
    AppLogger.debug('ImageImportDiagnostics: size=$byteLength bytes');

    if (byteLength == 0) {
      return const ImageValidationResult(
        exists: true,
        decodeOk: false,
        byteLength: 0,
        message: 'Файл пустой (0 bytes)',
      );
    }

    try {
      final bytes = await file.readAsBytes();
      final decodeOk = await _verifyDecode(bytes);
      AppLogger.info(
        'ImageImportDiagnostics: decodeOk=$decodeOk path=$path',
      );
      return ImageValidationResult(
        exists: true,
        decodeOk: decodeOk,
        byteLength: byteLength,
        message: decodeOk ? 'OK' : 'Не удалось декодировать изображение',
      );
    } catch (e, stack) {
      AppLogger.error(
        'ImageImportDiagnostics: read/decode failed',
        error: e,
        stackTrace: stack,
      );
      return ImageValidationResult(
        exists: true,
        decodeOk: false,
        byteLength: byteLength,
        message: 'Ошибка чтения: $e',
      );
    }
  }

  static Future<bool> _verifyDecode(List<int> bytes) async {
    if (bytes.isEmpty) return false;
    try {
      final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      final codec = await ui.instantiateImageCodec(data);
      codec.dispose();
      return true;
    } catch (e) {
      AppLogger.error(
        'ImageImportDiagnostics: instantiateImageCodec failed',
        error: e,
      );
      return false;
    }
  }
}

class ImageValidationResult {
  const ImageValidationResult({
    required this.exists,
    required this.decodeOk,
    required this.byteLength,
    required this.message,
  });

  final bool exists;
  final bool decodeOk;
  final int byteLength;
  final String message;

  bool get isValid => exists && decodeOk && byteLength > 0;
}
