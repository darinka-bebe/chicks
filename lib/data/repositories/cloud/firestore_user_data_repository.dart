import '../../../core/services/collection_names.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/sync/sync_document.dart';

/// Firestore read/write layer scoped to `users/{uid}/…` collections.
class FirestoreUserDataRepository {
  FirestoreUserDataRepository._({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService.instance;

  static final FirestoreUserDataRepository instance =
      FirestoreUserDataRepository._();

  final FirestoreService _firestore;

  Future<List<SyncDocument>> fetchWardrobe(String uid) =>
      _firestore.fetchCollection(
        uid: uid,
        collectionName: CollectionNames.wardrobe,
      );

  Future<List<SyncDocument>> fetchFavorites(String uid) =>
      _firestore.fetchCollection(
        uid: uid,
        collectionName: CollectionNames.favorites,
      );

  Future<List<SyncDocument>> fetchOutfitHistory(String uid) =>
      _firestore.fetchCollection(
        uid: uid,
        collectionName: CollectionNames.outfitHistory,
      );

  Future<List<SyncDocument>> fetchChatHistory(String uid) =>
      _firestore.fetchCollection(
        uid: uid,
        collectionName: CollectionNames.chatHistory,
      );

  Future<Map<String, dynamic>?> fetchProfile(String uid) =>
      _firestore.fetchDocument(
        uid: uid,
        collectionName: CollectionNames.profile,
        docId: CollectionNames.profileMainDocId,
      );

  Future<void> upsertDocuments({
    required String uid,
    required String collectionName,
    required List<SyncDocument> documents,
  }) =>
      _firestore.upsertBatch(
        uid: uid,
        collectionName: collectionName,
        documents: documents,
      );

  Future<void> upsertProfile({
    required String uid,
    required SyncDocument document,
  }) =>
      _firestore.upsertDocument(
        uid: uid,
        collectionName: CollectionNames.profile,
        document: document,
      );

  Future<Map<String, bool>> deleteDocuments({
    required String uid,
    required String collectionName,
    required Iterable<String> docIds,
  }) =>
      _firestore.deleteDocuments(
        uid: uid,
        collectionName: collectionName,
        docIds: docIds,
      );

  Future<int> countWardrobe(String uid) => _firestore.countCollection(
        uid: uid,
        collectionName: CollectionNames.wardrobe,
      );

  Future<bool> wardrobeDocumentExists(String uid, String docId) =>
      _firestore.documentExists(
        uid: uid,
        collectionName: CollectionNames.wardrobe,
        docId: docId,
      );
}
