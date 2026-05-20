/// Validation and display rules for profile / auth user fields.
abstract final class UserProfileRules {
  static const Set<String> placeholderEmails = {
    'guest@chicks.app',
    'guest@example.com',
  };

  static bool isPlaceholderEmail(String? email) {
    if (email == null) return true;
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return placeholderEmails.contains(normalized);
  }

  /// Email safe to show in UI (empty when placeholder or invalid).
  static String visibleEmail(String? email) {
    if (isPlaceholderEmail(email)) return '';
    return email!.trim();
  }

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static String sanitizeStoredEmail(String? email) {
    return isPlaceholderEmail(email) ? '' : (email?.trim() ?? '');
  }
}
