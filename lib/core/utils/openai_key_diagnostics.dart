/// Helpers for OpenAI key diagnostics (never log full secrets).
abstract final class OpenAiKeyDiagnostics {
  static String? normalize(String? raw) {
    if (raw == null) return null;
    var key = raw.trim();
    if (key.isEmpty) return null;

    if ((key.startsWith('"') && key.endsWith('"')) ||
        (key.startsWith("'") && key.endsWith("'"))) {
      key = key.substring(1, key.length - 1).trim();
    }

    return key.isEmpty ? null : key;
  }

  static String describe(String? key) {
    if (key == null || key.isEmpty) return 'missing';
    if (key.length < 8) return 'too_short(len=${key.length})';
    final prefix = key.substring(0, key.length >= 7 ? 7 : key.length);
    final suffix = key.substring(key.length - 4);
    return 'present prefix=$prefix… suffix=…$suffix len=${key.length}';
  }
}
