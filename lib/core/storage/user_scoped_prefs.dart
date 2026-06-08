/// Builds SharedPreferences keys scoped to a Firebase user id.
abstract final class UserScopedPrefs {
  static String key(String base, String uid) {
    final trimmed = uid.trim();
    if (trimmed.isEmpty) return base;
    return '${base}_$trimmed';
  }
}
