/// Data domains that participate in Firestore cloud sync.
enum SyncScope {
  wardrobe,
  favorites,
  outfitHistory,
  chatHistory,
  profile,
}

extension SyncScopeX on SyncScope {
  String get firestoreCollectionName {
    switch (this) {
      case SyncScope.wardrobe:
        return 'wardrobe';
      case SyncScope.favorites:
        return 'favorites';
      case SyncScope.outfitHistory:
        return 'outfit_history';
      case SyncScope.chatHistory:
        return 'chat_history';
      case SyncScope.profile:
        return 'profile';
    }
  }
}
