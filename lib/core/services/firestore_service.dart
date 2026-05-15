import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/user_model.dart';
import '../utils/logger.dart';
import 'collection_names.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(CollectionNames.users);

  Future<void> saveUser(UserModel user) async {
    try {
      final existingUser = await getUser(user.uid);

      final updatedUser = user.copyWith(
        createdAt: existingUser?.createdAt ?? DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _usersCollection.doc(user.uid).set(
            updatedUser.toJson(),
            SetOptions(merge: true),
          );

      AppLogger.info('Firestore: user saved ${user.uid}');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Firestore save user error',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
       }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return UserModel.fromJson(doc.data()!);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Firestore get user error',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> updateUser(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await _usersCollection.doc(uid).update(data);

      AppLogger.info('Firestore: user updated $uid');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Firestore update user error',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
       }
  }

  Future<bool> userExists(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }
}