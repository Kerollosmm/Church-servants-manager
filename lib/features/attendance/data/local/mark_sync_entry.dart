import 'dart:convert';

/// The type of mutation queued for Firestore sync.
enum MarkSyncOperation { create, update, delete }

/// Represents a pending attendance mark mutation in the local sync queue.
///
/// Each entry captures all data needed to replay the mutation against Firestore
/// when connectivity is restored.
class MarkSyncEntry {
  final String id;
  final String teamId;
  final String sessionId;
  final String studentId;
  final MarkSyncOperation operation;

  /// The full mark payload. Null for [MarkSyncOperation.delete].
  final Map<String, dynamic>? markData;
  final DateTime queuedAt;

  const MarkSyncEntry({
    required this.id,
    required this.teamId,
    required this.sessionId,
    required this.studentId,
    required this.operation,
    this.markData,
    required this.queuedAt,
  });

  /// Deterministic key for deduplication in the sync queue.
  /// Later entries for the same mark overwrite earlier ones.
  String get deduplicationKey => '${teamId}_${sessionId}_$studentId';

  Map<String, dynamic> toJson() => {
    'id': id,
    'teamId': teamId,
    'sessionId': sessionId,
    'studentId': studentId,
    'operation': operation.name,
    'markData': markData,
    'queuedAt': queuedAt.toIso8601String(),
  };

  factory MarkSyncEntry.fromJson(Map<String, dynamic> json) {
    return MarkSyncEntry(
      id: json['id'] as String,
      teamId: json['teamId'] as String,
      sessionId: json['sessionId'] as String,
      studentId: json['studentId'] as String,
      operation: MarkSyncOperation.values.firstWhere(
        (e) => e.name == json['operation'],
        orElse: () => MarkSyncOperation.create,
      ),
      markData: json['markData'] != null
          ? Map<String, dynamic>.from(json['markData'] as Map)
          : null,
      queuedAt: DateTime.parse(json['queuedAt'] as String),
    );
  }

  String encode() => jsonEncode(toJson());

  static MarkSyncEntry decode(String source) =>
      MarkSyncEntry.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
