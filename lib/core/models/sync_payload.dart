/// Sealed hierarchy of typed payloads for [SyncEntry].
///
/// Each subclass corresponds to a known [SyncEntry.actionType] and provides
/// type-safe access to the payload fields that the sync handler expects.
sealed class SyncPayload {
  const SyncPayload();

  Map<String, Object?> toPayloadMap();
}

/// Payload for student upsert mutations (actionType: 'UPSERT_STUDENT').
final class UpsertStudentPayload extends SyncPayload {
  final Map<String, dynamic> student;
  final bool syncLinkedUser;
  final String? previousRole;
  final String? updatedEmail;

  const UpsertStudentPayload({
    required this.student,
    required this.syncLinkedUser,
    this.previousRole,
    this.updatedEmail,
  });

  factory UpsertStudentPayload.fromMap(Map<String, Object?> map) {
    return UpsertStudentPayload(
      student: Map<String, dynamic>.from(map['student'] as Map? ?? const {}),
      syncLinkedUser: map['syncLinkedUser'] as bool? ?? false,
      previousRole: map['previousRole'] as String?,
      updatedEmail: map['updatedEmail'] as String?,
    );
  }

  @override
  Map<String, Object?> toPayloadMap() => {
    'student': student,
    'syncLinkedUser': syncLinkedUser,
    'previousRole': previousRole,
    'updatedEmail': updatedEmail,
  };
}

/// Payload for student archive mutations (actionType: 'ARCHIVE_STUDENT').
final class ArchiveStudentPayload extends SyncPayload {
  final String docId;
  final String performedByUid;

  const ArchiveStudentPayload({
    required this.docId,
    required this.performedByUid,
  });

  factory ArchiveStudentPayload.fromMap(Map<String, Object?> map) {
    return ArchiveStudentPayload(
      docId: map['docId'] as String? ?? '',
      performedByUid: map['performedByUid'] as String? ?? '',
    );
  }

  @override
  Map<String, Object?> toPayloadMap() => {
    'docId': docId,
    'performedByUid': performedByUid,
  };
}

/// Payload for student restore mutations (actionType: 'RESTORE_STUDENT').
final class RestoreStudentPayload extends SyncPayload {
  final String docId;
  final String performedByUid;

  const RestoreStudentPayload({
    required this.docId,
    required this.performedByUid,
  });

  factory RestoreStudentPayload.fromMap(Map<String, Object?> map) {
    return RestoreStudentPayload(
      docId: map['docId'] as String? ?? '',
      performedByUid: map['performedByUid'] as String? ?? '',
    );
  }

  @override
  Map<String, Object?> toPayloadMap() => {
    'docId': docId,
    'performedByUid': performedByUid,
  };
}
