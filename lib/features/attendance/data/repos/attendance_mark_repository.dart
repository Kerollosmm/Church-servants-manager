import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_mark.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Repository responsible for attendance mark CRUD operations.
/// Handles creating, updating, and deleting individual student marks within a session.
class AttendanceMarkRepository {
  AttendanceMarkRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
  /// Uses transaction to prevent double-counting on retry.
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
    final markRef = _markDoc(teamId, sessionId, normalizedStudentId);
    final sessionRef = _sessionDoc(teamId, sessionId);
    final effectiveStudentName = studentNameSnapshot.trim().isNotEmpty
        ? studentNameSnapshot.trim()
        : 'مخدوم';
    final normalizedNote = note?.trim();

    // Use normal get and batch to support offline writes.
    final markDoc = await markRef.get();
    if (markDoc.exists) {
      return;
    }

    final data = <String, dynamic>{
      'studentNameSnapshot': effectiveStudentName,
      'status': status.name,
      'markedByUserId': markedBy.uid,
      'markedByName': markedBy.name,
      'markedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (normalizedNote != null && normalizedNote.isNotEmpty) {
      data['note'] = normalizedNote;
    }

    final batch = _firestore.batch();
    batch.set(markRef, data, SetOptions(merge: true));
    batch.set(sessionRef, {
      '${status.name}Count': FieldValue.increment(1),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  /// Updates an existing attendance mark.
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
    final markRef = _markDoc(teamId, sessionId, normalizedStudentId);
    final sessionRef = _sessionDoc(teamId, sessionId);
    final normalizedNote = note?.trim();

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
  }

  /// Deletes an attendance mark (toggle-off behavior per FR-08.7).
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
  }

  /// Gets all marks for a session.
  Future<Map<String, AttendanceMark>> getMarksForSession({
    required String teamId,
    required String sessionId,
  }) async {
    final snapshot = await _marksCol(teamId, sessionId).get();
    final marks = <String, AttendanceMark>{};
    for (final doc in snapshot.docs) {
      try {
        marks[doc.id] = AttendanceMark.fromMap(doc.data(), doc.id);
      } catch (error) {
        if (kDebugMode) {
          debugPrint(
            'AttendanceMarkRepository: skipped malformed mark '
            '${doc.reference.path} (${error.runtimeType})',
          );
        }
      }
    }
    return marks;
  }

  /// Watches all marks for a session in real-time.
  Stream<Map<String, AttendanceMark>> watchMarksForSession({
    required String teamId,
    required String sessionId,
  }) {
    return _marksCol(teamId, sessionId).snapshots().map((snapshot) {
      final marks = <String, AttendanceMark>{};
      for (final doc in snapshot.docs) {
        try {
          marks[doc.id] = AttendanceMark.fromMap(doc.data(), doc.id);
        } catch (error) {
          if (kDebugMode) {
            debugPrint(
              'AttendanceMarkRepository: skipped malformed mark '
              '${doc.reference.path} (${error.runtimeType})',
            );
          }
        }
      }
      return marks;
    });
  }

  /// Gets a single mark for a student in a session.
  Future<AttendanceMark?> getMarkForStudent({
    required String teamId,
    required String sessionId,
    required String studentId,
  }) async {
    final normalizedStudentId = studentId.trim();
    final doc = await _markDoc(teamId, sessionId, normalizedStudentId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    try {
      return AttendanceMark.fromMap(data, doc.id);
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          'AttendanceMarkRepository: skipped malformed mark '
          '${doc.reference.path} (${error.runtimeType})',
        );
      }
      return null;
    }
  }

  /// Watches a single mark for a student in real-time.
  Stream<AttendanceMark?> watchMarkForStudent({
    required String teamId,
    required String sessionId,
    required String studentId,
  }) {
    final normalizedStudentId = studentId.trim();
    return _markDoc(teamId, sessionId, normalizedStudentId).snapshots().map((
      doc,
    ) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      try {
        return AttendanceMark.fromMap(data, doc.id);
      } catch (error) {
        if (kDebugMode) {
          debugPrint(
            'AttendanceMarkRepository: skipped malformed mark '
            '${doc.reference.path} (${error.runtimeType})',
          );
        }
        return null;
      }
    });
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
    if (!await canManage()) {
      throw const AttendancePermissionDeniedFailure();
    }

    final session = await getSession();
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
