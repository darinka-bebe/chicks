/// Firestore document envelope with sync metadata.
class SyncDocument {
  const SyncDocument({
    required this.id,
    required this.payload,
    required this.updatedAt,
    this.deleted = false,
  });

  final String id;
  final Map<String, dynamic> payload;
  final DateTime updatedAt;
  final bool deleted;

  static const updatedAtField = 'updatedAt';
  static const deletedField = 'deleted';

  Map<String, dynamic> toFirestoreMap() {
    return {
      ...payload,
      updatedAtField: updatedAt.toUtc().toIso8601String(),
      deletedField: deleted,
    };
  }

  factory SyncDocument.fromFirestore(Map<String, dynamic> data, {String? docId}) {
    final id = _readId(data['id']) ?? docId ?? '';
    final updatedAtRaw = data[updatedAtField];
    final updatedAt = _parseDate(updatedAtRaw) ??
        _parseDate(data['createdAt']) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  final payload = Map<String, dynamic>.from(data)
      ..remove(updatedAtField)
      ..remove(deletedField);

    if (id.isNotEmpty) {
      payload['id'] = id;
    }

    return SyncDocument(
      id: id,
      payload: payload,
      updatedAt: updatedAt,
      deleted: data[deletedField] == true,
    );
  }

  static String? _readId(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    return DateTime.tryParse(value.toString())?.toUtc();
  }
}
