import 'dart:developer' as developer;
import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/attendance/data/local/attendance_local_datasource.dart';
import 'package:church_management_system/features/attendance/data/local/mark_sync_entry.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_mark.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Repository responsible for attendance mark CRUD operations.
/// Handles creating, updating, and deleting individual student marks within a session.
///
/// Implements write-behind pattern: mutations are persisted to [AttendanceLocalDatasource]
/// first (Hive cache + sync queue), then attempted against Firestore. Network failures
/// are caught silently — entries remain in the queue for the sync engine to retry.
class AttendanceMarkRepository {
  AttendanceMarkRepository({
    FirebaseFirestore? firestore,
    required AttendanceLocalDatasource localDatasource,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _localDatasource = localDatasource;

  final FirebaseFirestore _firestore;
  final AttendanceLocalDatasource _localDatasource;

  CollectionReference<Map<String, dynamic>> get _classesCollection =>
      _firestore.collection(FirestoreCollections.classes);

  CollectionReference<Map<String, dynamic>> _sessionsCol(String teamId) =>
      _classesCollection
          .doc(teamId)
          .collection(FirestoreCollections.attendanceSessions);

  DocumentReference<Map<String, dynamic>> _sessionDoc(
    String teamId,
    String sessionId,
  ) => _sessionsCol(teamId).doc(sessionId);

  CollectionReference<Map<String, dynamic>> _marksCol(
    String teamId,
    String sessionId,
  ) => _sessionDoc(
    teamId,
    sessionId,
  ).collection(FirestoreCollections.attendanceMarks);

  DocumentReference<Map<String, dynamic>> _markDoc(
    String teamId,
    String sessionId,
    String studentId,
  ) => _marksCol(teamId, sessionId).doc(studentId);

  Future<void> _assertCanWriteMark({
    required String teamId,
    required String sessionId,
    required String studentId,
    required AuthUser user,
    required DateTime now,
  }) async {
    await assertCanWriteMark(
      teamId: teamId,
      sessionId: sessionId,
      studentId: studentId,
      user: user,
      now: now,
      getSession: () => _getSession(teamId, sessionId),
      canManage: () => _canUserManageAttendance(user, teamId),
    );
  }

  Future<AttendanceSession?> _getSession(
    String teamId,
    String sessionId,
  ) async {
    final doc = await _sessionDoc(teamId, sessionId).get();
    if (!doc.exists || doc.data() == null) return null;
    return AttendanceSession.fromMap(doc.data()!, doc.id);
  }

  Future<bool> _canUserManageAttendance(AuthUser user, String teamId) async {
    if (user.isArchived) return false;
    if (user.role == UserRole.admin) return true;
    if (user.role != UserRole.servant) return false;
    return user.effectiveAssignedTeamIds.contains(teamId.trim());
  }

  /// Creates a new attendance mark for a student.
  ///
  /// **Write-behind**: Hive cache + sync queue first, then Firestore.
  /// Network failures are caught — mark stays queued for retry.
  Future<void> createMark({
    required String teamId,
    required String sessionId,
    required String studentId,
    required String studentNameSnapshot,
    required AuthUser markedBy,
    required AttendanceMarkStatus status,
    String? note,
  }) async {
    await _assertCanWriteMark(
      teamId: teamId,
      sessionId: sessionId,
      studentId: studentId,
      user: markedBy,
      now: DateTime.now(),
    );
    final normalizedStudentId = studentId.trim();
    final effectiveStudentName = studentNameSnapshot.trim().isNotEmpty
        ? studentNameSnapshot.trim()
        : 'مخدوم';
    final normalizedNote = note?.trim();
    final now = DateTime.now();

    final markData = <String, dynamic>{
      'studentNameSnapshot': effectiveStudentName,
      'status': status.name,
      'markedByUserId': markedBy.uid,
      'markedByName': markedBy.name,
      'markedAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      if (normalizedNote != null && normalizedNote.isNotEmpty)
        'note': normalizedNote,
    };

    // 1. Write to Hive cache immediately.
    await _localDatasource.cacheMark(
      teamId: teamId,
      sessionId: sessionId,
      studentId: normalizedStudentId,
      markData: markData,
    );

    // 2. Enqueue for Firestore sync.
    await _localDatasource.enqueue(
      MarkSyncEntry(
        id: normalizedStudentId,
        teamId: teamId,
        sessionId: sessionId,
        studentId: normalizedStudentId,
        operation: MarkSyncOperation.create,
        markData: markData,
        queuedAt: now,
      ),
    );

    // 3. Attempt Firestore write; silently catch network errors.
    try {
      final markRef = _markDoc(teamId, sessionId, normalizedStudentId);
      final sessionRef = _sessionDoc(teamId, sessionId);

      final markDoc = await markRef.get();
      if (markDoc.exists) {
        // Already exists — remove from sync queue and return.
        await _localDatasource.removeFromQueue(
          '${teamId}_${sessionId}_$normalizedStudentId',
        );
        return;
      }

      final firestoreData = <String, dynamic>{
        'studentNameSnapshot': effectiveStudentName,
        'status': status.name,
        'markedByUserId': markedBy.uid,
        'markedByName': markedBy.name,
        'markedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (normalizedNote != null && normalizedNote.isNotEmpty) {
        firestoreData['note'] = normalizedNote;
      }

      final batch = _firestore.batch()
        ..set(markRef, firestoreData, SetOptions(merge: true))
        ..set(sessionRef, {
          '${status.name}Count': FieldValue.increment(1),
        }, SetOptions(merge: true));
      await batch.commit();

      // Synced — remove from queue.
      await _localDatasource.removeFromQueue(
        '${teamId}_${sessionId}_$normalizedStudentId',
      );
    } catch (error) {
      developer.log(
        'createMark queued for retry: $teamId/$sessionId/$normalizedStudentId',
        error: error,
        name: 'AttendanceMarkRepository',
      );
    }
  }

  /// Updates an existing attendance mark.
  ///
  /// **Write-behind**: Hive cache + sync queue first, then Firestore.
  Future<void> updateMark({
    required String teamId,
    required String sessionId,
    required String studentId,
    required AttendanceMarkStatus status,
    required AuthUser markedBy,
    String? note,
  }) async {
    await _assertCanWriteMark(
      teamId: teamId,
      sessionId: sessionId,
      studentId: studentId,
      user: markedBy,
      now: DateTime.now(),
    );
    final normalizedStudentId = studentId.trim();
    final normalizedNote = note?.trim();
    final now = DateTime.now();

    final markData = <String, dynamic>{
      'status': status.name,
      'markedByUserId': markedBy.uid,
      'markedByName': markedBy.name,
      'updatedAt': now.toIso8601String(),
      if (normalizedNote != null && normalizedNote.isNotEmpty)
        'note': normalizedNote,
    };

    // 1. Update Hive cache.
    await _localDatasource.cacheMark(
      teamId: teamId,
      sessionId: sessionId,
      studentId: normalizedStudentId,
      markData: markData,
    );

    // 2. Enqueue for sync.
    await _localDatasource.enqueue(
      MarkSyncEntry(
        id: normalizedStudentId,
        teamId: teamId,
        sessionId: sessionId,
        studentId: normalizedStudentId,
        operation: MarkSyncOperation.update,
        markData: markData,
        queuedAt: now,
      ),
    );

    // 3. Attempt Firestore write.
    try {
      final markRef = _markDoc(teamId, sessionId, normalizedStudentId);
      final sessionRef = _sessionDoc(teamId, sessionId);

      final markDoc = await markRef.get();
      if (!markDoc.exists) return;

      final oldStatusStr = markDoc.data()?['status'] as String?;
      final oldStatus = AttendanceMarkStatus.values.firstWhere(
        (e) => e.name == oldStatusStr,
        orElse: () => AttendanceMarkStatus.present,
      );

      final batch = _firestore.batch();
      if (oldStatus != status) {
        batch.set(sessionRef, {
          '${oldStatus.name}Count': FieldValue.increment(-1),
          '${status.name}Count': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }

      batch.set(markRef, {
        'status': status.name,
        'markedByUserId': markedBy.uid,
        'markedByName': markedBy.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'note': normalizedNote == null || normalizedNote.isEmpty
            ? FieldValue.delete()
            : normalizedNote,
      }, SetOptions(merge: true));
      await batch.commit();

      // Synced — remove from queue.
      await _localDatasource.removeFromQueue(
        '${teamId}_${sessionId}_$normalizedStudentId',
      );
    } catch (error) {
      developer.log(
        'updateMark queued for retry: $teamId/$sessionId/$normalizedStudentId',
        error: error,
        name: 'AttendanceMarkRepository',
      );
    }
  }

  /// Deletes an attendance mark (toggle-off behavior per FR-08.7).
  ///
  /// **Write-behind**: removes from Hive cache, enqueues delete, then attempts
  /// Firestore transaction. Session counts may temporarily drift while offline.
  Future<void> deleteMark({
    required String teamId,
    required String sessionId,
    required String studentId,
    required AuthUser requestedBy,
  }) async {
    await _assertCanWriteMark(
      teamId: teamId,
      sessionId: sessionId,
      studentId: studentId,
      user: requestedBy,
      now: DateTime.now(),
    );
    final normalizedStudentId = studentId.trim();

    // 1. Remove from Hive cache.
    await _localDatasource.removeCachedMark(
      teamId: teamId,
      sessionId: sessionId,
      studentId: normalizedStudentId,
    );

    // 2. Enqueue delete for sync.
    await _localDatasource.enqueue(
      MarkSyncEntry(
        id: normalizedStudentId,
        teamId: teamId,
        sessionId: sessionId,
        studentId: normalizedStudentId,
        operation: MarkSyncOperation.delete,
        queuedAt: DateTime.now(),
      ),
    );

    // 3. Attempt Firestore transaction.
    try {
      final markRef = _markDoc(teamId, sessionId, normalizedStudentId);
      final sessionRef = _sessionDoc(teamId, sessionId);

      await _firestore.runTransaction((transaction) async {
        final markDoc = await transaction.get(markRef);
        if (!markDoc.exists) return;

        final oldStatusStr = markDoc.data()?['status'] as String?;
        final oldStatus = AttendanceMarkStatus.values.firstWhere(
          (e) => e.name == oldStatusStr,
          orElse: () => AttendanceMarkStatus.present,
        );

        transaction
          ..update(sessionRef, {
            '${oldStatus.name}Count': FieldValue.increment(-1),
          })
          ..delete(markRef);
      });

      // Synced — remove from queue.
      await _localDatasource.removeFromQueue(
        '${teamId}_${sessionId}_$normalizedStudentId',
      );
    } catch (error) {
      developer.log(
        'deleteMark queued for retry: $teamId/$sessionId/$normalizedStudentId',
        error: error,
        name: 'AttendanceMarkRepository',
      );
    }
  }

  /// Gets all marks for a session.
  Future<Map<String, AttendanceMark>> getMarksForSession({
    required String teamId,
    required String sessionId,
  }) async {
    final snapshot = await _marksCol(
      teamId,
      sessionId,
    ).get(const GetOptions());
    final marks = <String, AttendanceMark>{};
    for (final doc in snapshot.docs) {
      try {
        marks[doc.id] = AttendanceMark.fromMap(doc.data(), doc.id);
      } catch (error) {
        developer.log(
          'skipped malformed mark ${doc.reference.path}',
          error: error,
          name: 'AttendanceMarkRepository',
        );
      }
    }
    return marks;
  }

  /// Gets a single mark for a student in a session.
  Future<AttendanceMark?> getMarkForStudent({
    required String teamId,
    required String sessionId,
    required String studentId,
  }) async {
    final normalizedStudentId = studentId.trim();
    final doc = await _markDoc(
      teamId,
      sessionId,
      normalizedStudentId,
    ).get(const GetOptions());
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    try {
      return AttendanceMark.fromMap(data, doc.id);
    } catch (error) {
      developer.log(
        'skipped malformed mark ${doc.reference.path}',
        error: error,
        name: 'AttendanceMarkRepository',
      );
      return null;
    }
  }

  /// Validates that a mark can be written (session is writable, student is in roster).
  Future<void> assertCanWriteMark({
    required String teamId,
    required String sessionId,
    required String studentId,
    required AuthUser user,
    required DateTime now,
    required Future<AttendanceSession?> Function() getSession,
    required Future<bool> Function() canManage,
  }) async {
    final normalizedStudentId = studentId.trim();

    final results = await Future.wait([canManage(), getSession()]);

    final hasPermission = results[0] as bool;
    final session = results[1] as AttendanceSession?;

    if (!hasPermission) {
      throw const AttendancePermissionDeniedFailure();
    }

    if (session == null) {
      throw const AttendanceSessionNotFoundFailure();
    }

    if (!session.studentIdsSnapshot.contains(normalizedStudentId)) {
      throw const AttendanceStudentNotInSessionFailure();
    }

    if (!session.isOpenAt(now)) {
      throw const AttendanceSessionClosedFailure();
    }
  }
}
