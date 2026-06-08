import 'dart:io';

import 'package:image/image.dart' as img;

/// Flattens launcher icon onto solid black (fixes transparent iOS corners).
void main(List<String> args) {
  final source = args.isNotEmpty
      ? args[0]
      : '../.cursor/projects/Users-natala-Downloads-chicks-lib/assets/image-a44b745b-0053-4123-9e69-7f09d56f4ef3.png';
  final dest = args.length > 1 ? args[1] : 'assets/icon/app_icon.png';

  final bytes = File(source).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    stderr.writeln('Could not decode PNG: $source');
    exit(1);
  }

  const size = 1024;
  final canvas = img.Image(width: size, height: size);
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 255));

  final scale = size / decoded.width;
  final resized = decoded.width == size && decoded.height == size
      ? decoded
      : img.copyResize(
          decoded,
          width: size,
          height: size,
          interpolation: img.Interpolation.cubic,
        );

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final pixel = resized.getPixel(x, y);
      final alpha = pixel.a;
      if (alpha == 0) continue;

      final blended = img.ColorRgba8(
        ((pixel.r * alpha) + (0 * (255 - alpha))) ~/ 255,
        ((pixel.g * alpha) + (0 * (255 - alpha))) ~/ 255,
        ((pixel.b * alpha) + (0 * (255 - alpha))) ~/ 255,
        255,
      );
      canvas.setPixel(x, y, blended);
    }
  }

  File(dest).writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln('Saved $dest (${File(dest).lengthSync()} bytes, scale=$scale)');
}
