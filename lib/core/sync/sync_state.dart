import 'package:equatable/equatable.dart';

/// UI-facing cloud sync status.
enum SyncPhase { idle, syncing, success, error, offline }

class SyncState extends Equatable {
  const SyncState({
    this.phase = SyncPhase.idle,
    this.message,
    this.lastSuccessAt,
    this.lastError,
    this.uid,
    this.restoredCounts = const {},
    this.uploadedCounts = const {},
    this.conflictCount = 0,
  });

  final SyncPhase phase;
  final String? message;
  final DateTime? lastSuccessAt;
  final String? lastError;
  final String? uid;
  final Map<String, int> restoredCounts;
  final Map<String, int> uploadedCounts;
  final int conflictCount;

  bool get isSyncing => phase == SyncPhase.syncing;
  bool get canRetry => phase == SyncPhase.error;

  SyncState copyWith({
    SyncPhase? phase,
    String? message,
    DateTime? lastSuccessAt,
    String? lastError,
    String? uid,
    Map<String, int>? restoredCounts,
    Map<String, int>? uploadedCounts,
    int? conflictCount,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return SyncState(
      phase: phase ?? this.phase,
      message: clearMessage ? null : (message ?? this.message),
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
      uid: uid ?? this.uid,
      restoredCounts: restoredCounts ?? this.restoredCounts,
      uploadedCounts: uploadedCounts ?? this.uploadedCounts,
      conflictCount: conflictCount ?? this.conflictCount,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        message,
        lastSuccessAt,
        lastError,
        uid,
        restoredCounts,
        uploadedCounts,
        conflictCount,
      ];
}
