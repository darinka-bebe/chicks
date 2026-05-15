import 'package:firebase_auth/firebase_auth.dart';

import '../../core/services/firebase_auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/utils/logger.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository._();

  static final AuthRepository instance = AuthRepository._();

  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel get currentUser {
    final firebaseUser = _authService.currentUser;

    if (firebaseUser == null) {
      return UserModel.empty;
    }

    return UserModel.fromFirebaseUser(firebaseUser);
  }

  bool get isLoggedIn => _authService.currentUser != null;

  Stream<UserModel> get authStateChanges {
    return _authService.authStateChanges.map((firebaseUser) {
      if (firebaseUser == null) {
        return UserModel.empty;
      }

      return UserModel.fromFirebaseUser(firebaseUser);
    });
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      final UserCredential? credential =
          await _authService.signInWithGoogle();

      if (credential == null || credential.user == null) {
        return UserModel.empty;
      }

      final firebaseUser = credential.user!;

      final user = UserModel.fromFirebaseUser(firebaseUser);

      await _firestoreService.saveUser(user);

      final firestoreUser =
          await _firestoreService.getUser(firebaseUser.uid);

      AppLogger.info(
        'AuthRepository sign in success ${firebaseUser.email}',
      );

      return firestoreUser ?? user;
    } on FirebaseAuthException catch (error, stackTrace) {
      AppLogger.error(
        'Firebase auth error',
        error: error,
        stackTrace: stackTrace,
      );

      throw Exception(error.message ?? 'Authentication error');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Google sign in error',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Sign out error',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }


Future<UserModel?> getCurrentFirestoreUser() async {
    try {
      final firebaseUser = _authService.currentUser;

      if (firebaseUser == null) {
        return null;
      }

      return await _firestoreService.getUser(firebaseUser.uid);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String displayName,
    required String photoUrl,
  }) async {
    final firebaseUser = _authService.currentUser;

    if (firebaseUser == null) {
      throw Exception('User not authorized');
    }

    await _firestoreService.updateUser(
      firebaseUser.uid,
      {
        'displayName': displayName,
        'photoUrl': photoUrl,
      },
    );
  }
}