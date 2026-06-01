import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../utils/logger.dart';

/// Firebase Auth + Google Sign-In (google_sign_in 6.x API).
class FirebaseAuthService {
  FirebaseAuthService._();

  static final FirebaseAuthService instance = FirebaseAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  /// Ensures Firestore requests have a fresh auth token (avoids early permission-denied).
  Future<void> ensureIdTokenReady() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.getIdToken(true);
  }

  UserModel? currentUserModel() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserModel.fromFirebaseUser(user);
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Вход отменён', code: 'cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw AuthException('Не удалось получить профиль Google');
      }

      AppLogger.info(
        'FirebaseAuthService: signed in ${firebaseUser.email ?? firebaseUser.uid}',
      );
      return UserModel.fromFirebaseUser(firebaseUser);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseMessage(e), code: e.code);
    } catch (e, stack) {
      AppLogger.error('FirebaseAuthService.signInWithGoogle', error: e, stackTrace: stack);
      throw AuthException(_mapGenericError(e));
    }
  }

  Future<UserModel> signUpWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw AuthException('Не удалось создать аккаунт');
      }

      await user.updateDisplayName(displayName.trim());
      await user.reload();
      final refreshed = _auth.currentUser!;

      AppLogger.info('FirebaseAuthService: email sign up ${refreshed.email}');
      return UserModel.fromFirebaseUser(refreshed);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseMessage(e), code: e.code);
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
    AppLogger.info('FirebaseAuthService: signed out');
  }

  static String _mapFirebaseMessage(FirebaseAuthException e) {
    return switch (e.code) {
      'account-exists-with-different-credential' =>
        'Этот email уже привязан к другому способу входа',
      'invalid-credential' => 'Неверные данные входа Google',
      'operation-not-allowed' => 'Google Sign-In не включён в Firebase Console',
      'user-disabled' => 'Аккаунт заблокирован',
      'user-not-found' => 'Пользователь не найден',
      'wrong-password' => 'Неверный пароль',
      'email-already-in-use' => 'Email уже зарегистрирован',
      'invalid-email' => 'Некорректный email',
      'weak-password' => 'Пароль слишком простой (минимум 6 символов)',
      'network-request-failed' => 'Нет сети. Проверьте подключение',
      'too-many-requests' => 'Слишком много попыток. Попробуйте позже',
      _ => e.message?.isNotEmpty == true
          ? e.message!
          : 'Ошибка входа (${e.code})',
    };
  }

  static String _mapGenericError(Object e) {
    final text = e.toString().toLowerCase();
    if (text.contains('network') || text.contains('socket')) {
      return 'Нет сети. Проверьте подключение';
    }
    return 'Не удалось войти через Google';
  }
}
