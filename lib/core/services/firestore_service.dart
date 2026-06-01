import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../sync/sync_document.dart';
import '../utils/async_guard.dart';
import '../utils/logger.dart';
import 'firebase_bootstrap.dart';

/// Low-level Firestore access with offline-friendly settings.
class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  CollectionReference<Map<String, dynamic>> userCollection(
    String uid,
    String collectionName,
  ) {
    return firestore.collection('users').doc(uid).collection(collectionName);
  }

  DocumentReference<Map<String, dynamic>> userDocument(
    String uid,
    String collectionName,
    String docId,
  ) {
    return userCollection(uid, collectionName).doc(docId);
  }

  Future<List<SyncDocument>> fetchCollection({
    required String uid,
    required String collectionName,
  }) async {
    return _withChannelRetry(
      'fetchCollection/$collectionName',
      () async {
        final snapshot = await userCollection(uid, collectionName).get();
        final docs = <SyncDocument>[];

        for (final doc in snapshot.docs) {
          try {
            docs.add(
              SyncDocument.fromFirestore(doc.data(), docId: doc.id),
            );
          } catch (e, stack) {
            AppLogger.error(
              'FirestoreService.fetchCollection: corrupt doc ${doc.id}',
              error: e,
              stackTrace: stack,
            );
          }
        }

        AppLogger.debug(
          'FirestoreService.fetchCollection: $collectionName '
          'count=${docs.length} uid=$uid',
        );
        return docs;
      },
    );
  }

  Future<Map<String, dynamic>?> fetchDocument({
    required String uid,
    required String collectionName,
    required String docId,
  }) async {
    return _withChannelRetry(
      'fetchDocument/$collectionName/$docId',
      () async {
        final snapshot =
            await userDocument(uid, collectionName, docId).get();
        if (!snapshot.exists) return null;
        return snapshot.data();
      },
    );
  }

  Future<void> upsertDocument({
    required String uid,
    required String collectionName,
    required SyncDocument document,
  }) async {
    final docId = document.id.trim();
    if (docId.isEmpty) {
      throw ArgumentError('SyncDocument.id is required for upsert');
    }

    await _withChannelRetry(
      'upsertDocument/$collectionName/$docId',
      () => userDocument(uid, collectionName, docId).set(
        document.toFirestoreMap(),
        SetOptions(merge: true),
      ),
    );

    AppLogger.debug(
      'FirestoreService.upsertDocument: $collectionName/$docId '
      'deleted=${document.deleted} uid=$uid',
    );
  }

  Future<void> upsertBatch({
    required String uid,
    required String collectionName,
    required List<SyncDocument> documents,
  }) async {
    if (documents.isEmpty) return;

    await _withChannelRetry(
      'upsertBatch/$collectionName',
      () async {
        const chunkSize = 400;
        for (var i = 0; i < documents.length; i += chunkSize) {
          final chunk = documents.skip(i).take(chunkSize).toList();
          final batch = firestore.batch();

          for (final document in chunk) {
            final docId = document.id.trim();
            if (docId.isEmpty) continue;
            batch.set(
              userDocument(uid, collectionName, docId),
              document.toFirestoreMap(),
              SetOptions(merge: true),
            );
          }

          await batch.commit();
        }
      },
    );

    AppLogger.info(
      'FirestoreService.upsertBatch: $collectionName '
      'uploaded=${documents.length} uid=$uid',
    );
  }

  /// Hard-deletes documents at `users/{uid}/{collectionName}/{docId}`.
  Future<Map<String, bool>> deleteDocuments({
    required String uid,
    required String collectionName,
    required Iterable<String> docIds,
  }) async {
    final ids = docIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isEmpty) return {};

    final results = <String, bool>{};

    await _withChannelRetry(
      'deleteDocuments/$collectionName',
      () async {
        const chunkSize = 400;
        for (var i = 0; i < ids.length; i += chunkSize) {
          final chunk = ids.skip(i).take(chunkSize).toList();
          try {
            final batch = firestore.batch();
            for (final docId in chunk) {
              batch.delete(userDocument(uid, collectionName, docId));
            }
            await batch.commit();
            for (final docId in chunk) {
              results[docId] = true;
              AppLogger.info(
                'FirestoreService.deleteDocument: SUCCESS '
                'path=users/$uid/$collectionName/$docId',
              );
            }
          } catch (e, stack) {
            if (FirestoreBootstrap.isChannelError(e)) {
              rethrow;
            }
            for (final docId in chunk) {
              results[docId] = false;
              AppLogger.error(
                'FirestoreService.deleteDocument: FAILED '
                'path=users/$uid/$collectionName/$docId',
                error: e,
                stackTrace: stack,
              );
            }
          }
        }
      },
    );

    final succeeded = results.values.where((ok) => ok).length;
    AppLogger.info(
      'FirestoreService.deleteDocuments: $collectionName '
      'requested=${ids.length} succeeded=$succeeded uid=$uid',
    );
    return results;
  }

  Future<int> countCollection({
    required String uid,
    required String collectionName,
  }) async {
    return _withChannelRetry(
      'countCollection/$collectionName',
      () async {
        final snapshot = await userCollection(uid, collectionName).get();
        final count = snapshot.docs.length;
        AppLogger.debug(
          'FirestoreService.countCollection: $collectionName '
          'count=$count uid=$uid',
        );
        return count;
      },
    );
  }

  Future<bool> documentExists({
    required String uid,
    required String collectionName,
    required String docId,
  }) async {
    return _withChannelRetry(
      'documentExists/$collectionName/$docId',
      () async {
        final snapshot =
            await userDocument(uid, collectionName, docId).get();
        return snapshot.exists;
      },
    );
  }

  Future<T> _withChannelRetry<T>(
    String operation,
    Future<T> Function() action,
  ) async {
    Object? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        await FirestoreBootstrap.ensureReady();
        return await AsyncGuard.withTimeout(
          label: 'FirestoreService.$operation',
          timeout: AsyncGuard.firestoreTimeout,
          action: action,
        );
      } catch (e, stack) {
        lastError = e;
        if (FirestoreBootstrap.isPermissionDenied(e) && attempt < 3) {
          AppLogger.warning(
            'FirestoreService.$operation: permission retry $attempt/3 — refresh token',
          );
          try {
            await FirebaseAuth.instance.currentUser?.getIdToken(true);
          } catch (_) {
            // ignore token refresh errors
          }
          await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
          continue;
        }
        if (!FirestoreBootstrap.isChannelError(e) || attempt == 3) {
          AppLogger.error(
            'FirestoreService.$operation failed',
            error: e,
            stackTrace: stack,
          );
          rethrow;
        }
        AppLogger.warning(
          'FirestoreService.$operation: channel retry $attempt/3',
        );
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
    throw lastError ?? StateError('FirestoreService.$operation failed');
  }
}
