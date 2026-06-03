import 'package:hive/hive.dart';

part 'mark_sync_entry.g.dart';

/// The type of mutation queued for Firestore sync.
@HiveType(typeId: 52)
enum MarkSyncOperation {
  @HiveField(0)
  create,
  @HiveField(1)
  update,
  @HiveField(2)
  delete,
}

/// Represents a pending attendance mark mutation in the local sync queue.
///
/// Each entry captures all data needed to replay the mutation against Firestore
/// when connectivity is restored.
@HiveType(typeId: 51)
class MarkSyncEntry {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String teamId;
  @HiveField(2)
  final String sessionId;
  @HiveField(3)
  final String studentId;
  @HiveField(4)
  final MarkSyncOperation operation;

  /// The full mark payload. Null for [MarkSyncOperation.delete].
  @HiveField(5)
  final Map<String, dynamic>? markData;
  @HiveField(6)
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
}
