import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/firebase_auth_service.dart';
import '../../core/services/firebase_bootstrap.dart';
import '../../core/services/profile_avatar_storage.dart';
import '../../core/services/profile_bootstrap_service.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/user_profile_rules.dart';
import '../models/user_model.dart';
import 'profile_preferences_repository.dart';

class AuthException implements Exception {
  AuthException(this.message, {this.code});

  final String message;
  final String? code;

  bool get isCancelled => code == 'cancelled';

  @override
  String toString() => message;
}

/// Firebase Auth + local profile overlays (avatar path, cached name).
class AuthRepository {
  AuthRepository._();

  static final AuthRepository instance = AuthRepository._();

  static const _loggedInKey = 'isLoggedIn';
  static const _nameKey = 'name';
  static const _emailKey = 'email';
  static const _photoUrlKey = 'photoUrl';
  static const _uidKey = 'user_uid_v1';

  final FirebaseAuthService _firebaseAuth = FirebaseAuthService.instance;

  final StreamController<UserModel> _authController =
      StreamController<UserModel>.broadcast();

  StreamSubscription<firebase.User?>? _firebaseSubscription;

  UserModel _currentUser = UserModel.empty;
  bool _initialized = false;

  UserModel get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser.isNotEmpty;

  Stream<UserModel> get authStateChanges => _authController.stream;

  Future<void> initialize() async {
    if (_initialized) return;

    await FirebaseBootstrap.ensureInitialized();

    final firebaseUser = _firebaseAuth.currentFirebaseUser;
    if (firebaseUser != null) {
      _currentUser = await _mergeWithLocalProfile(
        UserModel.fromFirebaseUser(firebaseUser),
      );
      await _persistSession(_currentUser);
    } else {
      final prefs = await SharedPreferences.getInstance();
      final loggedIn = prefs.getBool(_loggedInKey) ?? false;
      _currentUser =
          loggedIn ? await _loadUserFromPrefs(prefs) : UserModel.empty;
    }

    _authController.add(_currentUser);

    _firebaseSubscription?.cancel();
    _firebaseSubscription = _firebaseAuth.authStateChanges.listen(
      _onFirebaseUserChanged,
      onError: (Object e, StackTrace stack) {
        AppLogger.error('AuthRepository: auth stream error', error: e, stackTrace: stack);
      },
    );

    _initialized = true;
    AppLogger.info(
      'AuthRepository: init done (loggedIn=${_currentUser.isNotEmpty})',
    );
  }

  Future<void> _onFirebaseUserChanged(firebase.User? firebaseUser) async {
    if (firebaseUser == null) {
      if (_currentUser.isEmpty) return;
      _currentUser = UserModel.empty;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_loggedInKey, false);
      _authController.add(_currentUser);
      return;
    }

    final merged = await _mergeWithLocalProfile(
      UserModel.fromFirebaseUser(firebaseUser),
    );
    if (merged == _currentUser) return;

    _currentUser = merged;
    await _persistSession(_currentUser);
    _authController.add(_currentUser);
  }

  /// Clears invalid placeholder emails, repairs avatar path, re-syncs Firebase user.
  Future<void> repairStoredSession() async {
    await FirebaseBootstrap.ensureInitialized();

    final prefs = await SharedPreferences.getInstance();
    final rawEmail = prefs.getString(_emailKey);
    final sanitizedEmail = UserProfileRules.sanitizeStoredEmail(rawEmail);

    if (rawEmail != null && sanitizedEmail != rawEmail) {
      if (sanitizedEmail.isEmpty) {
        await prefs.remove(_emailKey);
      } else {
        await prefs.setString(_emailKey, sanitizedEmail);
      }
    }

    final storedUid = prefs.getString(_uidKey)?.trim() ?? _currentUser.uid;
    final rawPhoto = prefs.getString(_photoUrlKey) ?? '';
    final photoUrl = await ProfileAvatarStorage.resolveValidLocalPath(
      rawPhoto,
      uid: storedUid.isNotEmpty ? storedUid : null,
    );
    if (photoUrl != rawPhoto) {
      await prefs.setString(_photoUrlKey, photoUrl);
    }
    if (storedUid.isNotEmpty && photoUrl.isNotEmpty) {
      await ProfileAvatarStorage.pruneLegacyAvatars(
        uid: storedUid,
        keepPath: photoUrl,
      );
    }

    final firebaseUser = _firebaseAuth.currentFirebaseUser;
    if (firebaseUser != null) {
      final merged = await _mergeWithLocalProfile(
        UserModel.fromFirebaseUser(firebaseUser),
      );
      if (merged != _currentUser) {
        _currentUser = merged;
        await _persistSession(_currentUser);
        _authController.add(_currentUser);
      }
      return;
    }

    final loggedIn = prefs.getBool(_loggedInKey) ?? false;
    if (!loggedIn) return;

    final email = UserProfileRules.sanitizeStoredEmail(prefs.getString(_emailKey));
    if (email.isEmpty) {
      await prefs.setBool(_loggedInKey, false);
      _currentUser = UserModel.empty;
      _authController.add(_currentUser);
      return;
    }

    final fromPrefs = await _loadUserFromPrefs(prefs);
    if (fromPrefs != _currentUser) {
      _currentUser = fromPrefs;
      _authController.add(_currentUser);
    }
  }

  Future<UserModel> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final trimmedName = displayName.trim();
    final normalizedEmail = UserProfileRules.normalizeEmail(email);

    if (trimmedName.isEmpty) {
      throw AuthException('Введите имя');
    }
    if (!normalizedEmail.contains('@') || normalizedEmail.length < 5) {
      throw AuthException('Некорректный email');
    }
    if (UserProfileRules.isPlaceholderEmail(normalizedEmail)) {
      throw AuthException('Используйте реальный email');
    }
    if (password.length < 6) {
      throw AuthException('Пароль минимум 6 символов');
    }

    final model = await _firebaseAuth.signUpWithEmail(
      displayName: trimmedName,
      email: normalizedEmail,
      password: password,
    );

    _currentUser = await _mergeWithLocalProfile(model);
    await _persistSession(_currentUser);
    _authController.add(_currentUser);
    await _afterSuccessfulAuth();
    AppLogger.info('AuthRepository: sign up $normalizedEmail');
    return _currentUser;
  }

  /// Google Sign-In via Firebase Auth.
  Future<UserModel> signInWithGoogle() async {
    final model = await _firebaseAuth.signInWithGoogle();
    _currentUser = await _mergeWithLocalProfile(model);
    await _persistSession(_currentUser);
    _authController.add(_currentUser);
    await _afterSuccessfulAuth();
    return _currentUser;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
    _currentUser = UserModel.empty;
    _authController.add(_currentUser);
  }

  Future<UserModel?> getCurrentFirestoreUser() async {
    return isLoggedIn ? _currentUser : null;
  }

  Future<void> updatePhotoPath(String photoPath) async {
    if (!isLoggedIn) {
      throw AuthException('User not authorized');
    }

    final trimmed = photoPath.trim();
    final resolved = trimmed.toLowerCase().startsWith('http')
        ? trimmed
        : await ProfileAvatarStorage.ensurePermanentAvatarPath(
            trimmed,
            uid: _currentUser.uid,
          );

    if (resolved.isEmpty) {
      throw AuthException('Не удалось сохранить фото профиля');
    }

    _currentUser = _currentUser.copyWith(
      photoUrl: resolved,
      avatarRevision: _currentUser.avatarRevision + 1,
    );
    await _persistSession(_currentUser);
    _authController.add(_currentUser);
    AppLogger.info('AuthRepository: avatar path updated → $resolved');
  }

  Future<void> updateDisplayName(String displayName) async {
    await updateProfileDetails(displayName: displayName);
  }

  Future<void> updateProfileDetails({
    required String displayName,
    String? username,
  }) async {
    if (!isLoggedIn) {
      throw AuthException('User not authorized');
    }

    final trimmedName = displayName.trim();
    if (trimmedName.isEmpty) {
      throw AuthException('Введите имя');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, trimmedName);

    final firebaseUser = _firebaseAuth.currentFirebaseUser;
    if (firebaseUser != null) {
      try {
        await firebaseUser.updateDisplayName(trimmedName);
        await firebaseUser.reload();
      } catch (e, stack) {
        AppLogger.error(
          'AuthRepository: Firebase displayName update failed',
          error: e,
          stackTrace: stack,
        );
      }
    }

    var usernameValue = _currentUser.username;
    if (username != null) {
      await ProfilePreferencesRepository.instance.saveUsername(
        uid: _currentUser.uid,
        username: username,
      );
      usernameValue = username.trim();
    } else {
      usernameValue =
          await ProfilePreferencesRepository.instance.getUsername(_currentUser.uid);
    }

    _currentUser = _currentUser.copyWith(
      displayName: trimmedName,
      username: usernameValue,
    );
    await _persistSession(_currentUser);
    _authController.add(_currentUser);
    AppLogger.info('AuthRepository: profile details updated');
  }

  Future<void> updateProfile({
    required String displayName,
    required String photoUrl,
  }) async {
    if (!isLoggedIn) {
      throw AuthException('User not authorized');
    }

    final resolved = await ProfileAvatarStorage.ensurePermanentAvatarPath(
      photoUrl,
      uid: _currentUser.uid,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, displayName.trim());
    await prefs.setString(_photoUrlKey, resolved);

    _currentUser = _currentUser.copyWith(
      displayName: displayName.trim(),
      photoUrl: resolved,
    );
    _authController.add(_currentUser);
  }

  Future<UserModel> _loadUserFromPrefs(SharedPreferences prefs) async {
    final email = UserProfileRules.sanitizeStoredEmail(prefs.getString(_emailKey));
    final name = prefs.getString(_nameKey)?.trim() ?? '';
    final uid = prefs.getString(_uidKey)?.trim().isNotEmpty == true
        ? prefs.getString(_uidKey)!
        : (email.isNotEmpty ? 'local_${email.hashCode.abs()}' : 'local');

    final rawPhoto = prefs.getString(_photoUrlKey) ?? '';
    final photoUrl = await ProfileAvatarStorage.resolveValidLocalPath(
      rawPhoto,
      uid: uid,
    );
    if (photoUrl != rawPhoto) {
      await prefs.setString(_photoUrlKey, photoUrl);
    }

    final username =
        await ProfilePreferencesRepository.instance.getUsername(uid);

    return UserModel(
      uid: uid,
      displayName: name.isNotEmpty ? name : 'Пользователь',
      username: username,
      email: email,
      photoUrl: photoUrl,
    );
  }

  Future<void> _afterSuccessfulAuth() async {
    await ProfileBootstrapService.restoreUserData();
  }

  Future<void> _persistSession(UserModel user) async {
    if (user.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final email = UserProfileRules.sanitizeStoredEmail(user.email);
    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_uidKey, user.uid);
    await prefs.setString(_nameKey, user.displayName);
    if (email.isNotEmpty) {
      await prefs.setString(_emailKey, email);
    } else {
      await prefs.remove(_emailKey);
    }
    await prefs.setString(_photoUrlKey, user.photoUrl);
  }

  /// Prefer local avatar file; Firebase email is source of truth.
  Future<UserModel> _mergeWithLocalProfile(UserModel firebaseUser) async {
    final prefs = await SharedPreferences.getInstance();
    final localPhoto = await ProfileAvatarStorage.resolveValidLocalPath(
      prefs.getString(_photoUrlKey) ?? '',
      uid: firebaseUser.uid,
    );

    final photoUrl = localPhoto.isNotEmpty
        ? localPhoto
        : firebaseUser.photoUrl;

    final savedName = prefs.getString(_nameKey)?.trim() ?? '';
    final displayName = savedName.isNotEmpty && savedName != 'Пользователь'
        ? savedName
        : firebaseUser.displayName;

    final firebaseEmail =
        UserProfileRules.sanitizeStoredEmail(firebaseUser.email);
    final prefsEmail =
        UserProfileRules.sanitizeStoredEmail(prefs.getString(_emailKey));
    final email = firebaseEmail.isNotEmpty ? firebaseEmail : prefsEmail;

    final username = await ProfilePreferencesRepository.instance
        .getUsername(firebaseUser.uid);

    return firebaseUser.copyWith(
      displayName: displayName,
      username: username,
      email: email,
      photoUrl: photoUrl,
      lastLoginAt: DateTime.now(),
    );
  }
}
