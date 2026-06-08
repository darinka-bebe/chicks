import '../../data/models/chat_message.dart';
import '../../data/models/favorite_outfit.dart';
import '../../data/models/outfit_history_entry.dart';
import '../../data/models/wardrobe_item.dart';
import '../../data/repositories/cloud/firestore_user_data_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/chat_history_repository.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/repositories/tutorial_repository.dart';
import '../../data/repositories/outfit_history_repository.dart';
import '../../data/repositories/profile_preferences_repository.dart';
import '../../data/repositories/user_preferences_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import '../../data/repositories/wardrobe_repository.dart';
import '../models/body_profile.dart';
import '../models/seasonal_color_type.dart';
import '../models/stylist_defaults.dart';
import '../sync/sync_document.dart';
import '../sync/sync_merge_engine.dart';
import '../sync/sync_meta_storage.dart';
import '../sync/sync_scope.dart';
import '../utils/logger.dart';
import '../utils/wardrobe_image_diagnostics.dart';
import 'wardrobe_image_migration_service.dart';
import '../../features/wardrobe/data/mock_wardrobe_data.dart';
import 'collection_names.dart';
import 'wardrobe_sync_service.dart';

/// Pull/push user data between Hive/SharedPreferences and Firestore.
class CloudSyncService {
  CloudSyncService._({
    FirestoreUserDataRepository? firestoreRepository,
    WardrobeRepository? wardrobeRepository,
    FavoritesRepository? favoritesRepository,
    OutfitHistoryRepository? outfitHistoryRepository,
    ChatHistoryRepository? chatHistoryRepository,
    UserProfileRepository? userProfileRepository,
    OnboardingRepository? onboardingRepository,
    UserPreferencesRepository? userPreferencesRepository,
    ProfilePreferencesRepository? profilePreferencesRepository,
  })  : _firestoreRepository =
            firestoreRepository ?? FirestoreUserDataRepository.instance,
        _wardrobeRepository = wardrobeRepository ?? WardrobeRepository.instance,
        _favoritesRepository = favoritesRepository ?? FavoritesRepository.instance,
        _outfitHistoryRepository =
            outfitHistoryRepository ?? OutfitHistoryRepository.instance,
        _chatHistoryRepository =
            chatHistoryRepository ?? ChatHistoryRepository.instance,
        _userProfileRepository =
            userProfileRepository ?? UserProfileRepository.instance,
        _onboardingRepository =
            onboardingRepository ?? OnboardingRepository.instance,
        _userPreferencesRepository =
            userPreferencesRepository ?? UserPreferencesRepository.instance,
        _profilePreferencesRepository =
            profilePreferencesRepository ?? ProfilePreferencesRepository.instance;

  static final CloudSyncService instance = CloudSyncService._();

  final FirestoreUserDataRepository _firestoreRepository;
  final WardrobeRepository _wardrobeRepository;
  final FavoritesRepository _favoritesRepository;
  final OutfitHistoryRepository _outfitHistoryRepository;
  final ChatHistoryRepository _chatHistoryRepository;
  final UserProfileRepository _userProfileRepository;
  final OnboardingRepository _onboardingRepository;
  final UserPreferencesRepository _userPreferencesRepository;
  final ProfilePreferencesRepository _profilePreferencesRepository;

  Future<CloudSyncPullResult> pullAndMergeAll({
    required String uid,
    required Future<void> Function() persistLocally,
  }) async {
    AppLogger.info('CloudSyncService.pullAndMergeAll: start uid=$uid');

    final restoredCounts = <String, int>{};
    var conflictCount = 0;

    final wardrobe = await _pullWardrobe(uid);
    restoredCounts[SyncScope.wardrobe.name] = wardrobe.restoredCount;
    conflictCount += wardrobe.conflictCount;

    final favorites = await _pullFavorites(uid);
    restoredCounts[SyncScope.favorites.name] = favorites.restoredCount;
    conflictCount += favorites.conflictCount;

    final history = await _pullOutfitHistory(uid);
    restoredCounts[SyncScope.outfitHistory.name] = history.restoredCount;
    conflictCount += history.conflictCount;

    final chat = await _pullChatHistory(uid);
    restoredCounts[SyncScope.chatHistory.name] = chat.restoredCount;
    conflictCount += chat.conflictCount;

    final profile = await _pullProfile(uid);
    restoredCounts[SyncScope.profile.name] = profile.restoredCount;
    conflictCount += profile.conflictCount;

    await persistLocally();

    await WardrobeSyncService.loadFreshWardrobeForAi();

    AppLogger.info(
      'CloudSyncService.pullAndMergeAll: success uid=$uid '
      'restored=$restoredCounts conflicts=$conflictCount',
    );

    return CloudSyncPullResult(
      restoredCounts: restoredCounts,
      conflictCount: conflictCount,
    );
  }

  Future<CloudSyncPushResult> pushAll({required String uid}) async {
    AppLogger.info('CloudSyncService.pushAll: start uid=$uid');

    final uploadedCounts = <String, int>{};

    uploadedCounts[SyncScope.wardrobe.name] = await _pushWardrobe(uid);
    uploadedCounts[SyncScope.favorites.name] = await _pushFavorites(uid);
    uploadedCounts[SyncScope.outfitHistory.name] =
        await _pushOutfitHistory(uid);
    uploadedCounts[SyncScope.chatHistory.name] = await _pushChatHistory(uid);
    uploadedCounts[SyncScope.profile.name] = await _pushProfile(uid);

    AppLogger.info(
      'CloudSyncService.pushAll: success uid=$uid uploaded=$uploadedCounts',
    );

    return CloudSyncPushResult(uploadedCounts: uploadedCounts);
  }

  Future<CloudSyncPushResult> pushScope({
    required String uid,
    required SyncScope scope,
  }) async {
    AppLogger.info('CloudSyncService.pushScope: start uid=$uid scope=$scope');

    final uploadedCounts = <String, int>{};
    switch (scope) {
      case SyncScope.wardrobe:
        uploadedCounts[scope.name] = await _pushWardrobe(uid);
      case SyncScope.favorites:
        uploadedCounts[scope.name] = await _pushFavorites(uid);
      case SyncScope.outfitHistory:
        uploadedCounts[scope.name] = await _pushOutfitHistory(uid);
      case SyncScope.chatHistory:
        uploadedCounts[scope.name] = await _pushChatHistory(uid);
      case SyncScope.profile:
        uploadedCounts[scope.name] = await _pushProfile(uid);
    }

    AppLogger.info(
      'CloudSyncService.pushScope: success uid=$uid uploaded=$uploadedCounts',
    );

    return CloudSyncPushResult(uploadedCounts: uploadedCounts);
  }

  Future<SyncMergeResult<WardrobeItem>> _pullWardrobe(String uid) async {
    final remoteRaw = await _firestoreRepository.fetchWardrobe(uid);
    final remote = _filterRemoteForPull(
      remote: remoteRaw,
      scope: SyncScope.wardrobe,
      collectionLabel: CollectionNames.wardrobe,
    );
    AppLogger.info(
      'CloudSyncService._pullWardrobe: remoteRaw=${remoteRaw.length} '
      'remoteFiltered=${remote.length} uid=$uid',
    );
    WardrobeImageDiagnostics.logFirestorePayload(
      '_pullWardrobe',
      remote.map((doc) => doc.payload).toList(),
    );

    final local = await _wardrobeRepository.loadItems();
    final timestamps = SyncMetaStorage.readTimestamps(SyncScope.wardrobe);
    final localUpdatedAt = {
      for (final item in local)
        item.id: timestamps[item.id] != null
            ? SyncMetaStorage.timestampFor(SyncScope.wardrobe, item.id)
            : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    };

    final merged = SyncMergeEngine.mergeMaps<WardrobeItem>(
      localItems: local,
      remoteDocs: remote,
      idField: 'id',
      localUpdatedAt: localUpdatedAt,
      fromJson: WardrobeItem.fromJson,
      toJson: (item) => item.toJson(),
    );

    final withoutDemo = MockWardrobeData.excludeDemo(merged.items);
    final repairedItems = await WardrobeImageMigrationService.migrateAll(
      withoutDemo,
    );
    if (withoutDemo.length != repairedItems.length) {
      AppLogger.info(
        'CloudSyncService._pullWardrobe: skipped '
        '${repairedItems.length - withoutDemo.length} demo item(s) from cloud',
      );
    }
    WardrobeImageDiagnostics.logItems('_pullWardrobe(afterMerge)', repairedItems);

    await _wardrobeRepository.saveItemsLocally(repairedItems);
    await SyncMetaStorage.touchAll(
      SyncScope.wardrobe,
      repairedItems.map((item) => item.id),
    );

    _logRestored(SyncScope.wardrobe, merged.restoredCount, merged.conflictCount);
    return SyncMergeResult(
      items: repairedItems,
      restoredCount: merged.restoredCount,
      conflictCount: merged.conflictCount,
      removedCount: merged.removedCount,
    );
  }

  Future<SyncMergeResult<FavoriteOutfit>> _pullFavorites(String uid) async {
    final remoteRaw = await _firestoreRepository.fetchFavorites(uid);
    final remote = _filterRemoteForPull(
      remote: remoteRaw,
      scope: SyncScope.favorites,
      collectionLabel: CollectionNames.favorites,
    );
    final local = await _favoritesRepository.loadOutfits();
    final timestamps = SyncMetaStorage.readTimestamps(SyncScope.favorites);
    final localUpdatedAt = {
      for (final item in local)
        item.id: timestamps[item.id] != null
            ? SyncMetaStorage.timestampFor(SyncScope.favorites, item.id)
            : item.createdAt.toUtc(),
    };

    final merged = SyncMergeEngine.mergeMaps<FavoriteOutfit>(
      localItems: local,
      remoteDocs: remote,
      idField: 'id',
      localUpdatedAt: localUpdatedAt,
      fromJson: FavoriteOutfit.fromJson,
      toJson: (item) => item.toJson(),
      dedupeField: 'contentHash',
    );

    await _favoritesRepository.saveOutfitsLocally(merged.items);
    await SyncMetaStorage.touchAll(
      SyncScope.favorites,
      merged.items.map((item) => item.id),
    );

    _logRestored(SyncScope.favorites, merged.restoredCount, merged.conflictCount);
    return merged;
  }

  Future<SyncMergeResult<OutfitHistoryEntry>> _pullOutfitHistory(String uid) async {
    final remoteRaw = await _firestoreRepository.fetchOutfitHistory(uid);
    final remote = _filterRemoteForPull(
      remote: remoteRaw,
      scope: SyncScope.outfitHistory,
      collectionLabel: CollectionNames.outfitHistory,
    );
    final local = await _outfitHistoryRepository.loadEntries();
    final timestamps = SyncMetaStorage.readTimestamps(SyncScope.outfitHistory);
    final localUpdatedAt = {
      for (final item in local)
        item.id: timestamps[item.id] != null
            ? SyncMetaStorage.timestampFor(SyncScope.outfitHistory, item.id)
            : item.createdAt.toUtc(),
    };

    final merged = SyncMergeEngine.mergeMaps<OutfitHistoryEntry>(
      localItems: local,
      remoteDocs: remote,
      idField: 'id',
      localUpdatedAt: localUpdatedAt,
      fromJson: OutfitHistoryEntry.fromJson,
      toJson: (item) => item.toJson(),
    );

    await _outfitHistoryRepository.saveEntriesLocally(merged.items);
    await SyncMetaStorage.touchAll(
      SyncScope.outfitHistory,
      merged.items.map((item) => item.id),
    );

    _logRestored(
      SyncScope.outfitHistory,
      merged.restoredCount,
      merged.conflictCount,
    );
    return merged;
  }

  Future<SyncMergeResult<ChatMessage>> _pullChatHistory(String uid) async {
    final remoteRaw = await _firestoreRepository.fetchChatHistory(uid);
    final remote = _filterRemoteForPull(
      remote: remoteRaw,
      scope: SyncScope.chatHistory,
      collectionLabel: CollectionNames.chatHistory,
    );
    final local = await _chatHistoryRepository.loadMessages();
    final timestamps = SyncMetaStorage.readTimestamps(SyncScope.chatHistory);
    final localUpdatedAt = {
      for (final item in local)
        item.id: timestamps[item.id] != null
            ? SyncMetaStorage.timestampFor(SyncScope.chatHistory, item.id)
            : item.createdAt.toUtc(),
    };

    final merged = SyncMergeEngine.mergeMaps<ChatMessage>(
      localItems: local,
      remoteDocs: remote,
      idField: 'id',
      localUpdatedAt: localUpdatedAt,
      fromJson: ChatMessage.fromJson,
      toJson: (item) => item.toJson(),
    );

    await _chatHistoryRepository.saveMessagesLocally(merged.items);
    await SyncMetaStorage.touchAll(
      SyncScope.chatHistory,
      merged.items.map((item) => item.id),
    );

    _logRestored(
      SyncScope.chatHistory,
      merged.restoredCount,
      merged.conflictCount,
    );
    return merged;
  }

  Future<SyncMergeResult<Map<String, dynamic>>> _pullProfile(String uid) async {
    final remoteRaw = await _firestoreRepository.fetchProfile(uid);

    final local = await _buildLocalProfile(uid);
    final localUpdatedAt = {
      CollectionNames.profileMainDocId: SyncMetaStorage.timestampFor(
        SyncScope.profile,
        CollectionNames.profileMainDocId,
      ),
    };

    final remoteDocs = remoteRaw == null
        ? <SyncDocument>[]
        : [
            SyncDocument.fromFirestore(
              remoteRaw,
              docId: CollectionNames.profileMainDocId,
            ),
          ];

    final merged = SyncMergeEngine.mergeMaps<Map<String, dynamic>>(
      localItems: [local],
      remoteDocs: remoteDocs,
      idField: 'id',
      localUpdatedAt: localUpdatedAt,
      fromJson: (json) => json,
      toJson: (item) => item,
    );

    if (merged.items.isNotEmpty) {
      await _applyProfileLocally(merged.items.first, uid: uid);
      await SyncMetaStorage.touch(
        SyncScope.profile,
        CollectionNames.profileMainDocId,
      );
    }

    _logRestored(SyncScope.profile, merged.restoredCount, merged.conflictCount);
    return merged;
  }

  Future<int> _pushWardrobe(String uid) async {
    var items = await _wardrobeRepository.loadItems();
    final withUrls = await WardrobeImageMigrationService.migrateAll(items);
    if (_wardrobeImagesChanged(items, withUrls)) {
      await _wardrobeRepository.saveItemsLocally(withUrls);
      items = withUrls;
    }

    final pendingDeletes = SyncMetaStorage.readPendingDeletes(SyncScope.wardrobe);

  if (pendingDeletes.isNotEmpty) {
      final beforeCount = await _firestoreRepository.countWardrobe(uid);
      AppLogger.info(
        'CloudSyncService._pushWardrobe: hard-delete start '
        'pending=${pendingDeletes.length} firestoreBefore=$beforeCount uid=$uid',
      );

      for (final deletedId in pendingDeletes) {
        AppLogger.info(
          'CloudSyncService._pushWardrobe: delete request '
          'localId=$deletedId firestoreDocId=$deletedId '
          'path=users/$uid/${CollectionNames.wardrobe}/$deletedId',
        );
      }

      final deleteResults = await _firestoreRepository.deleteDocuments(
        uid: uid,
        collectionName: CollectionNames.wardrobe,
        docIds: pendingDeletes,
      );

      for (final entry in deleteResults.entries) {
        final docId = entry.key;
        final ok = entry.value;
        if (ok) {
          final stillExists =
              await _firestoreRepository.wardrobeDocumentExists(uid, docId);
          AppLogger.info(
            'CloudSyncService._pushWardrobe: delete verified '
            'docId=$docId existsAfterDelete=$stillExists',
          );
          if (!stillExists) {
            await SyncMetaStorage.clearPendingDelete(SyncScope.wardrobe, docId);
            await SyncMetaStorage.removeTimestamp(SyncScope.wardrobe, docId);
          }
        } else {
          AppLogger.warning(
            'CloudSyncService._pushWardrobe: delete failed docId=$docId '
            '(will retry on next push)',
          );
        }
      }

      final afterCount = await _firestoreRepository.countWardrobe(uid);
      AppLogger.info(
        'CloudSyncService._pushWardrobe: hard-delete done '
        'firestoreBefore=$beforeCount firestoreAfter=$afterCount '
        'removed=${beforeCount - afterCount} uid=$uid',
      );
    }

    final remainingDeletes =
        SyncMetaStorage.readPendingDeletes(SyncScope.wardrobe);
    final docs = <SyncDocument>[];

    for (final item in items) {
      if (remainingDeletes.contains(item.id)) continue;

      final updatedAt = SyncMetaStorage.timestampFor(SyncScope.wardrobe, item.id);
      docs.add(
        SyncDocument(
          id: item.firestoreDocId,
          payload: item.toFirestoreJson(),
          updatedAt: updatedAt.isAfter(
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          )
              ? updatedAt
              : DateTime.now().toUtc(),
          deleted: false,
        ),
      );
    }

    if (docs.isNotEmpty) {
      await _firestoreRepository.upsertDocuments(
        uid: uid,
        collectionName: CollectionNames.wardrobe,
        documents: docs,
      );
    }

    AppLogger.info(
      'CloudSyncService._pushWardrobe: uploaded items=${docs.length} '
      'pendingDeletesRemaining=${remainingDeletes.length} uid=$uid',
    );
    return docs.length + pendingDeletes.length;
  }

  Future<int> _pushFavorites(String uid) async {
    return _pushEntityList(
      uid: uid,
      scope: SyncScope.favorites,
      collectionName: CollectionNames.favorites,
      items: await _favoritesRepository.loadOutfits(),
      idFor: (item) => item.id,
      toJson: (item) => item.toJson(),
      fallbackUpdatedAt: (item) => item.createdAt.toUtc(),
    );
  }

  Future<int> _pushOutfitHistory(String uid) async {
    return _pushEntityList(
      uid: uid,
      scope: SyncScope.outfitHistory,
      collectionName: CollectionNames.outfitHistory,
      items: await _outfitHistoryRepository.loadEntries(),
      idFor: (item) => item.id,
      toJson: (item) => item.toJson(),
      fallbackUpdatedAt: (item) => item.createdAt.toUtc(),
    );
  }

  Future<int> _pushChatHistory(String uid) async {
    return _pushEntityList(
      uid: uid,
      scope: SyncScope.chatHistory,
      collectionName: CollectionNames.chatHistory,
      items: await _chatHistoryRepository.loadMessages(),
      idFor: (item) => item.id,
      toJson: (item) => item.toJson(),
      fallbackUpdatedAt: (item) => item.createdAt.toUtc(),
    );
  }

  Future<int> _pushProfile(String uid) async {
    final profile = await _buildLocalProfile(uid);
    final updatedAt = SyncMetaStorage.timestampFor(
      SyncScope.profile,
      CollectionNames.profileMainDocId,
    );

    await _firestoreRepository.upsertProfile(
      uid: uid,
      document: SyncDocument(
        id: CollectionNames.profileMainDocId,
        payload: profile,
        updatedAt: updatedAt.isAfter(
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        )
            ? updatedAt
            : DateTime.now().toUtc(),
      ),
    );

    AppLogger.info('CloudSyncService: uploaded profile uid=$uid');
    return 1;
  }

  Future<int> _pushEntityList<T>({
    required String uid,
    required SyncScope scope,
    required String collectionName,
    required List<T> items,
    required String Function(T item) idFor,
    required Map<String, dynamic> Function(T item) toJson,
    required DateTime Function(T item) fallbackUpdatedAt,
  }) async {
    final pendingDeletes = SyncMetaStorage.readPendingDeletes(scope);

    if (pendingDeletes.isNotEmpty) {
      AppLogger.info(
        'CloudSyncService._pushEntityList: hard-delete start '
        'collection=$collectionName pending=${pendingDeletes.length} uid=$uid',
      );

      for (final deletedId in pendingDeletes) {
        AppLogger.info(
          'CloudSyncService._pushEntityList: delete request '
          'localId=$deletedId firestoreDocId=$deletedId '
          'path=users/$uid/$collectionName/$deletedId',
        );
      }

      final deleteResults = await _firestoreRepository.deleteDocuments(
        uid: uid,
        collectionName: collectionName,
        docIds: pendingDeletes,
      );

      for (final entry in deleteResults.entries) {
        if (entry.value) {
          await SyncMetaStorage.clearPendingDelete(scope, entry.key);
          await SyncMetaStorage.removeTimestamp(scope, entry.key);
        } else {
          AppLogger.warning(
            'CloudSyncService._pushEntityList: delete failed '
            'collection=$collectionName docId=${entry.key}',
          );
        }
      }
    }

    final remainingDeletes = SyncMetaStorage.readPendingDeletes(scope);
    final docs = <SyncDocument>[];

    for (final item in items) {
      final id = idFor(item);
      if (remainingDeletes.contains(id)) continue;

      final updatedAt = SyncMetaStorage.timestampFor(scope, id);
      docs.add(
        SyncDocument(
          id: id,
          payload: toJson(item),
          updatedAt: updatedAt.isAfter(
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          )
              ? updatedAt
              : fallbackUpdatedAt(item),
          deleted: false,
        ),
      );
    }

    if (docs.isNotEmpty) {
      await _firestoreRepository.upsertDocuments(
        uid: uid,
        collectionName: collectionName,
        documents: docs,
      );
    }

    AppLogger.info(
      'CloudSyncService._pushEntityList: uploaded $collectionName '
      'items=${docs.length} pendingDeletesRemaining=${remainingDeletes.length}',
    );
    return docs.length + pendingDeletes.length;
  }

  List<SyncDocument> _filterRemoteForPull({
    required List<SyncDocument> remote,
    required SyncScope scope,
    required String collectionLabel,
  }) {
    final pendingDeletes = SyncMetaStorage.readPendingDeletes(scope);
    return remote.where((doc) {
      if (pendingDeletes.contains(doc.id)) {
        AppLogger.warning(
          'CloudSyncService pull $collectionLabel: skip doc ${doc.id} '
          '(pending local delete)',
        );
        return false;
      }
      if (doc.deleted) {
        AppLogger.debug(
          'CloudSyncService pull $collectionLabel: skip tombstone ${doc.id}',
        );
        return false;
      }
      return true;
    }).toList();
  }

  Future<Map<String, dynamic>> _buildLocalProfile(String uid) async {
    final colorType = await _userProfileRepository.getColorType();
    final bodyProfile = await _userProfileRepository.getBodyProfile();
    final stylistDefaults = (await _userPreferencesRepository.getStylistDefaults(
      uid: uid,
    ))
        .sanitized();

    return {
      'id': CollectionNames.profileMainDocId,
      'colorType': colorType?.storageKey,
      'colorQuizCompleted':
          await _userProfileRepository.isColorTypeQuizCompleted(),
      'bodyProfile': bodyProfile?.toJson(),
      'bodyQuizCompleted':
          await _userProfileRepository.isBodyTypeQuizCompleted(),
      'onboardingCompleted': await _onboardingRepository.isCompleted(),
      'tutorialCompleted': await TutorialRepository.instance.isCompleted(
        uid: uid,
      ),
      'username': uid.isEmpty
          ? ''
          : await _profilePreferencesRepository.getUsername(uid),
      'city': uid.isEmpty
          ? ''
          : await _profilePreferencesRepository.getCity(uid),
      'displayName': AuthRepository.instance.currentUser.displayName,
      'stylistDefaults': stylistDefaults.toJson(),
    };
  }

  Future<void> _applyProfileLocally(
    Map<String, dynamic> profile, {
    required String uid,
  }) async {
    final colorKey = profile['colorType'] as String?;
    final colorType = SeasonalColorType.fromStorageKey(colorKey);
    if (colorType != null) {
      await _userProfileRepository.saveColorTypeLocally(colorType);
    }

    if (profile['colorQuizCompleted'] == true) {
      await _userProfileRepository.setColorTypeQuizCompletedLocally(
        completed: true,
      );
    }

    final bodyRaw = profile['bodyProfile'];
    if (bodyRaw is Map) {
      await _userProfileRepository.saveBodyProfileLocally(
        BodyProfile.fromJson(Map<String, dynamic>.from(bodyRaw)),
      );
    }

    if (profile['bodyQuizCompleted'] == true) {
      await _userProfileRepository.setBodyTypeQuizCompletedLocally(
        completed: true,
      );
    }

    if (profile['onboardingCompleted'] == true) {
      await _onboardingRepository.setCompletedLocally(completed: true);
    }

    if (profile['tutorialCompleted'] == true && uid.isNotEmpty) {
      await TutorialRepository.instance.setCompletedLocally(
        completed: true,
        uid: uid,
      );
    }

    final username = profile['username'] as String? ?? '';
    if (uid.isNotEmpty && username.trim().isNotEmpty) {
      await _profilePreferencesRepository.saveUsername(
        uid: uid,
        username: username,
      );
    }

    final city = profile['city'] as String? ?? '';
    if (uid.isNotEmpty) {
      await _profilePreferencesRepository.saveCity(
        uid: uid,
        city: city,
      );
    }

    final stylistRaw = profile['stylistDefaults'];
    if (stylistRaw is Map && uid.isNotEmpty) {
      await _userPreferencesRepository.saveStylistDefaultsLocally(
        uid,
        StylistDefaults.fromJson(Map<String, dynamic>.from(stylistRaw))
            .sanitized(),
      );
    }
  }

  void _logRestored(SyncScope scope, int restored, int conflicts) {
    AppLogger.info(
      'CloudSyncService: restored scope=$scope count=$restored conflicts=$conflicts',
    );
  }

  static bool _wardrobeImagesChanged(
    List<WardrobeItem> before,
    List<WardrobeItem> after,
  ) {
    if (before.length != after.length) return true;
    for (var i = 0; i < before.length; i++) {
      if (before[i].id != after[i].id) return true;
      if (before[i].imageUrl != after[i].imageUrl) return true;
      if (before[i].imagePath != after[i].imagePath) return true;
    }
    return false;
  }
}

class CloudSyncPullResult {
  const CloudSyncPullResult({
    required this.restoredCounts,
    required this.conflictCount,
  });

  final Map<String, int> restoredCounts;
  final int conflictCount;
}

class CloudSyncPushResult {
  const CloudSyncPushResult({required this.uploadedCounts});

  final Map<String, int> uploadedCounts;
}
