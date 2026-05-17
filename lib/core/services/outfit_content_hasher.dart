/// Stable hash for outfit recommendation deduplication.
abstract final class OutfitContentHasher {
  static String normalize(String content) {
    return content
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[*#>`\[\]]'), '');
  }

  static String hash(String content) {
    final normalized = normalize(content);
    var fnv = 0x811c9dc5;
    for (final unit in normalized.codeUnits) {
      fnv ^= unit;
      fnv = (fnv * 0x01000193) & 0xFFFFFFFF;
    }
    return fnv.toRadixString(16).padLeft(8, '0');
  }
}
