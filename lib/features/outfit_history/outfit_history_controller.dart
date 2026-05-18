import 'package:flutter/foundation.dart';

import '../../data/models/outfit_history_entry.dart';
import '../../data/repositories/outfit_history_repository.dart';

/// Global outfit history state for list and detail screens.
class OutfitHistoryController extends ChangeNotifier {
  OutfitHistoryController({OutfitHistoryRepository? repository})
      : _repository = repository ?? OutfitHistoryRepository.instance;

  final OutfitHistoryRepository _repository;

  List<OutfitHistoryEntry> _entries = [];
  bool _isLoaded = false;
  bool _isLoading = false;

  List<OutfitHistoryEntry> get entries => List.unmodifiable(_entries);
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;

  Future<void> ensureLoaded() async {
    if (_isLoaded) return;
    await refresh();
  }

  Future<void> refresh() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      _entries = await _repository.loadEntries();
      _isLoaded = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> recordEntry(OutfitHistoryEntry entry) async {
    await _repository.addEntry(entry);
    if (_isLoaded) {
      _entries = [entry, ..._entries];
      notifyListeners();
    }
  }

  Future<bool> deleteEntry(String id) async {
    final removed = await _repository.deleteEntry(id);
    if (removed && _isLoaded) {
      _entries = _entries.where((item) => item.id != id).toList();
      notifyListeners();
    }
    return removed;
  }
}
