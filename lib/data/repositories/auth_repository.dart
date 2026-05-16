import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/logger.dart';
import '../models/user_model.dart';

/// Репозиторий авторизации (локальная реализация для запуска без Firebase).
class AuthRepository {
  AuthRepository._();

  static final AuthRepository instance = AuthRepository._();

  static const _loggedInKey = 'isLoggedIn';
  static const _nameKey = 'name';
  static const _emailKey = 'email';
  static const _photoUrlKey = 'photoUrl';

  final StreamController<UserModel> _authController =
      StreamController<UserModel>.broadcast();

  UserModel _currentUser = UserModel.empty;
  bool _initialized = false;

  UserModel get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser.isNotEmpty;

  Stream<UserModel> get authStateChanges => _authController.stream;

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_loggedInKey) ?? false;

    if (loggedIn) {
      _currentUser = UserModel(
        uid: 'local',
        displayName: prefs.getString(_nameKey) ?? 'User',
        email: prefs.getString(_emailKey) ?? '',
        photoUrl: prefs.getString(_photoUrlKey) ?? '',
      );
    } else {
      _currentUser = UserModel.empty;
    }

    _authController.add(_currentUser);
    _initialized = true;
  }

  Future<UserModel> signInWithGoogle() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey) ?? 'guest@chicks.app';
    final name = prefs.getString(_nameKey) ?? 'Guest';

    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_nameKey, name);

    _currentUser = UserModel(
      uid: 'local',
      displayName: name,
      email: email,
      photoUrl: prefs.getString(_photoUrlKey) ?? '',
    );

    _authController.add(_currentUser);
    AppLogger.info('AuthRepository sign in success $email');
    return _currentUser;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
    _currentUser = UserModel.empty;
    _authController.add(_currentUser);
  }

  Future<UserModel?> getCurrentFirestoreUser() async {
    return isLoggedIn ? _currentUser : null;
  }

  Future<void> updateProfile({
    required String displayName,
    required String photoUrl,
  }) async {
    if (!isLoggedIn) {
      throw Exception('User not authorized');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, displayName);
    await prefs.setString(_photoUrlKey, photoUrl);

    _currentUser = _currentUser.copyWith(
      displayName: displayName,
      photoUrl: photoUrl,
    );
    _authController.add(_currentUser);
  }
}
