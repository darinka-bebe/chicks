/// Validation and display rules for profile / auth user fields.
abstract final class UserProfileRules {
  static const Set<String> placeholderEmails = {
    'guest@chicks.app',
    'guest@example.com',
  };

  static const Set<String> genericDisplayNames = {
    'user',
    'guest',
    'пользователь',
    'гость',
  };

  static bool isPlaceholderEmail(String? email) {
    if (email == null) return true;
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return placeholderEmails.contains(normalized);
  }

  static bool isGenericDisplayName(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return true;
    return genericDisplayNames.contains(trimmed.toLowerCase());
  }

  /// Name for greeting on home screen; empty when user should set a real name.
  static String greetingName(String? displayName) {
    if (isGenericDisplayName(displayName)) return '';
    return displayName!.trim();
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
