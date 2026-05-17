import 'package:hive/hive.dart';

part 'sync_entry.g.dart';

/// Represents a pending mutation in the local sync queue.
///
/// This model captures all the data needed to replay a mutation against Firestore
/// when connectivity is restored, providing a unified queue for offline-first actions.
@HiveType(typeId: 100) // Ensure typeId is unique across the app
class SyncEntry extends HiveObject {
  @HiveField(0)
  final String id;

  /// The type of action to be performed (e.g., 'MARK_ATTENDANCE', 'UPDATE_STUDENT')
  @HiveField(1)
  final String actionType;

  /// The JSON-serializable payload containing the mutation data
  @HiveField(2)
  final Map<String, dynamic> payload;

  @HiveField(3)
  final DateTime createdAt;

  /// Tracks how many times we've attempted to sync this entry
  @HiveField(4)
  int retryCount;

  /// Timestamp when this entry was moved to the dead-letter queue (null if still active).
  @HiveField(5)
  final DateTime? failedAt;

  SyncEntry({
    required this.id,
    required this.actionType,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.failedAt,
  });

  /// Deterministic key for deduplication.
  /// By default, overwriting the same `id` in Hive will update the entry.
  Map<String, dynamic> toJson() => {
    'id': id,
    'actionType': actionType,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
    'failedAt': failedAt?.toIso8601String(),
  };
}
