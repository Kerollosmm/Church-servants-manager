import 'package:church_management_system/core/constants/sync_action_type.dart';
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
  final Map<String, Object?> payload;

  @HiveField(3)
  final DateTime createdAt;

  /// Tracks how many times we've attempted to sync this entry
  @HiveField(4)
  int retryCount;

  /// Timestamp when this entry was moved to the dead-letter queue (null if still active).
  @HiveField(5)
  DateTime? failedAt;

  /// User who initiated this mutation (for scoping and isolation)
  @HiveField(6)
  final String? userId;

  /// The last error message when a sync attempt failed
  @HiveField(7)
  String? lastErrorMessage;

  @HiveField(8)
  final int? schemaVersion;

  SyncEntry({
    required this.id,
    required this.actionType,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.failedAt,
    this.userId,
    this.lastErrorMessage,
    this.schemaVersion = 2,
  });

  factory SyncEntry.create({
    required String id,
    required SyncActionType action,
    required Map<String, Object?> payload,
    required DateTime createdAt,
    int retryCount = 0,
    DateTime? failedAt,
    String? userId,
    String? lastErrorMessage,
    int? schemaVersion = 2,
  }) => SyncEntry(
    id: id,
    actionType: action.value,
    payload: payload,
    createdAt: createdAt,
    retryCount: retryCount,
    failedAt: failedAt,
    userId: userId,
    lastErrorMessage: lastErrorMessage,
    schemaVersion: schemaVersion,
  );

  /// Deterministic key for deduplication.
  /// By default, overwriting the same `id` in Hive will update the entry.
  Map<String, Object?> toJson() => {
    'id': id,
    'actionType': actionType,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
    'failedAt': failedAt?.toIso8601String(),
    'userId': userId,
    'lastErrorMessage': lastErrorMessage,
    'schemaVersion': schemaVersion,
  };
}
