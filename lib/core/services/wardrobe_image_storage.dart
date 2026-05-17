import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Copies gallery picks into app-private storage so [File] paths stay valid.
class WardrobeImageStorage {
  static const _subdir = 'wardrobe_images';

  /// Reads [file] bytes and writes them under the app documents directory.
  static Future<String?> persistFromXFile(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;

      final docsDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${docsDir.path}/$_subdir');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final extension = _resolveExtension(file.path);
      final output = File(
        '${imagesDir.path}/wardrobe_${DateTime.now().millisecondsSinceEpoch}$extension',
      );
      await output.writeAsBytes(bytes, flush: true);
      return output.path;
    } catch (_) {
      return null;
    }
  }

  static String _resolveExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return '.jpg';
    final ext = path.substring(dot).toLowerCase();
    if (ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.webp') {
      return ext;
    }
    return '.jpg';
  }
}
