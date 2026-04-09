import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Repository responsible for attendance session CRUD operations.
/// Handles session creation, closing, reopening, and querying within a team.
class AttendanceSessionRepository {
  AttendanceSessionRepository({FirebaseFirestore? firestore})
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

  List<AttendanceSession> _mapSessionsSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final sessions = <AttendanceSession>[];
    for (final doc in snapshot.docs) {
      try {
        sessions.add(AttendanceSession.fromMap(doc.data(), doc.id));
      } catch (error) {
        if (kDebugMode) {
          debugPrint(
            'AttendanceSessionRepository: skipped malformed session '
            '${doc.reference.path} (${error.runtimeType})',
          );
        }
      }
    }
    sessions.sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return sessions;
  }

  bool _sessionsOverlap(AttendanceSession a, AttendanceSession b) {
    return a.startsAt.isBefore(b.endsAt) && b.startsAt.isBefore(a.endsAt);
  }

  String _slugifyTitle(String? title) {
    final normalized = title?.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
    if (normalized.isEmpty) return 'session';
    // Preserve Unicode word characters (Arabic, Latin, digits) for slug uniqueness.
    final slug = normalized
        .replaceAll(RegExp(r'[^\w\u0600-\u06FF\u0750-\u077F]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.isEmpty) return 'session';
    if (slug.length <= 60) return slug;
    return slug.substring(0, 60);
  }

  /// Creates a new attendance session with overlap validation.
  Future<AttendanceSession> createSession({
    required String teamId,
    required String teamNameSnapshot,
    required DateTime startsAt,
    required int durationMinutes,
    required AuthUser createdBy,
    required List<String> studentIdsSnapshot,
    required Map<String, String> studentNameSnapshots,
    String? title,
  }) async {
    final normalizedTeamId = teamId.trim();
    if (normalizedTeamId.isEmpty) {
      throw const AttendanceValidationFailure(
        'يجب اختيار الفريق قبل إنشاء الجلسة.',
      );
    }
    if (durationMinutes <= 0) {
      throw const AttendanceValidationFailure(
        'مدة الجلسة يجب أن تكون أكبر من صفر.',
      );
    }

    final normalizedTitle = title?.trim();
    if (normalizedTitle == null || normalizedTitle.isEmpty) {
      throw const AttendanceValidationFailure('عنوان الجلسة مطلوب.');
    }
    final dateKey = AttendanceSession.buildDateKey(startsAt);
    final timeKey = startsAt.toUtc().millisecondsSinceEpoch;
    final slug = _slugifyTitle(normalizedTitle);
    final sessionId = '${dateKey}_${timeKey}_$slug';

    final session = AttendanceSession(
      id: sessionId,
      teamId: normalizedTeamId,
      teamNameSnapshot: teamNameSnapshot.trim().isEmpty
          ? null
          : teamNameSnapshot.trim(),
      title: normalizedTitle,
      dateKey: dateKey,
      startsAt: startsAt,
      endsAt: startsAt.add(Duration(minutes: durationMinutes)),
      durationMinutes: durationMinutes,
      createdByUserId: createdBy.uid,
      createdByName: createdBy.name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      studentIdsSnapshot: studentIdsSnapshot,
      studentNameSnapshots: studentNameSnapshots,
    );

    final docRef = _sessionDoc(normalizedTeamId, sessionId);

    await _firestore.runTransaction((transaction) async {
      // 1. Lock the team document and get active sessions index.
      final teamDoc = await transaction.get(
        _classesCollection.doc(normalizedTeamId),
      );
      if (!teamDoc.exists) {
        throw const AttendanceValidationFailure('الفريق غير موجود.');
      }

      final openSessionIds = List<String>.from(
        teamDoc.data()?['openSessionIds'] ?? [],
      );

      // 2. Validate session uniqueness and overlap inside transaction.
      final existingDoc = await transaction.get(docRef);
      if (existingDoc.exists) {
        throw const AttendanceSessionConflictFailure(
          'تم إنشاء جلسة حضور مطابقة بالفعل.',
        );
      }

      final now = DateTime.now();
      final activeSessions = <AttendanceSession>[];
      final clashingIds = <String>[];

      for (final id in openSessionIds) {
        final sDoc = await transaction.get(_sessionDoc(normalizedTeamId, id));
        if (sDoc.exists && sDoc.data() != null) {
          final existing = AttendanceSession.fromMap(sDoc.data()!, sDoc.id);
          if (!existing.isEffectivelyClosedAt(now)) {
            activeSessions.add(existing);
            if (_sessionsOverlap(session, existing)) {
              throw const AttendanceSessionConflictFailure(
                'تتعارض هذه الجلسة مع جلسة أخرى موجودة.',
              );
            }
          } else {
            clashingIds.add(id);
          }
        } else {
          clashingIds.add(id);
        }
      }

      // 3. Perform atomic creation and index update.
      transaction.set(docRef, {
        ...session.toMap(),
        'teamIsActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final updatedOpenIds = openSessionIds
          .where((id) => !clashingIds.contains(id))
          .toList();
      updatedOpenIds.add(sessionId);

      transaction.update(teamDoc.reference, {
        'openSessionIds': updatedOpenIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    // Read back the written document to return server timestamps.
    final writtenDoc = await docRef.get();
    final writtenData = writtenDoc.data();
    if (!writtenDoc.exists || writtenData == null) {
      throw const AttendanceServerFailure('فشل في قراءة الجلسة بعد الإنشاء.');
    }
    return AttendanceSession.fromMap(writtenData, writtenDoc.id);
  }

  /// Closes an attendance session.
  Future<void> closeSession({
    required String teamId,
    required String sessionId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final sessionRef = _sessionDoc(teamId, sessionId);
      final teamRef = _classesCollection.doc(teamId);

      transaction.update(sessionRef, {
        'isClosed': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(teamRef, {
        'openSessionIds': FieldValue.arrayRemove([sessionId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Reopens a closed session for admin editing.
  /// Validates no overlapping open sessions before reopening.
  Future<void> reopenSession({
    required String teamId,
    required String sessionId,
    required String reopenedByUserId,
    required String reopenedByName,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final teamRef = _classesCollection.doc(teamId);
      final sessionRef = _sessionDoc(teamId, sessionId);

      final teamDoc = await transaction.get(teamRef);
      final sessionDoc = await transaction.get(sessionRef);

      if (!teamDoc.exists) {
        throw const AttendanceValidationFailure('الفريق غير موجود.');
      }
      if (!sessionDoc.exists || sessionDoc.data() == null) {
        throw const AttendanceSessionNotFoundFailure();
      }

      final session = AttendanceSession.fromMap(
        sessionDoc.data()!,
        sessionDoc.id,
      );
      final openSessionIds = List<String>.from(
        teamDoc.data()?['openSessionIds'] ?? [],
      );

      final now = DateTime.now();
      final clashingIds = <String>[];

      for (final id in openSessionIds) {
        if (id == sessionId) continue;
        final sDoc = await transaction.get(_sessionDoc(teamId, id));
        if (sDoc.exists && sDoc.data() != null) {
          final existing = AttendanceSession.fromMap(sDoc.data()!, sDoc.id);
          if (!existing.isEffectivelyClosedAt(now)) {
            if (_sessionsOverlap(session, existing)) {
              throw const AttendanceSessionConflictFailure(
                'لا يمكن إعادة فتح الجلسة لأنها تتعارض مع جلسة أخرى مفتوحة.',
              );
            }
          } else {
            clashingIds.add(id);
          }
        } else {
          clashingIds.add(id);
        }
      }

      transaction.update(sessionRef, {
        'isClosed': false,
        'reopenedAt': FieldValue.serverTimestamp(),
        'reopenedByUserId': reopenedByUserId,
        'reopenedByName': reopenedByName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final updatedOpenIds = openSessionIds
          .where((id) => !clashingIds.contains(id))
          .toList();
      if (!updatedOpenIds.contains(sessionId)) {
        updatedOpenIds.add(sessionId);
      }

      transaction.update(teamRef, {
        'openSessionIds': updatedOpenIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Watches all sessions for a team, ordered by startsAt descending.
  Stream<List<AttendanceSession>> watchSessionsForTeam(String teamId) {
    return _sessionsCol(teamId)
        .orderBy('startsAt', descending: true)
        .snapshots()
        .map(_mapSessionsSnapshot);
  }

  /// Watches a specific session by ID.
  Stream<AttendanceSession?> watchSessionById({
    required String teamId,
    required String sessionId,
  }) {
    return _sessionDoc(teamId, sessionId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return AttendanceSession.fromMap(data, doc.id);
    });
  }

  /// Gets a specific session by ID (one-time read).
  Future<AttendanceSession?> getSessionById({
    required String teamId,
    required String sessionId,
  }) async {
    try {
      final doc = await _sessionDoc(teamId, sessionId).get();
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return AttendanceSession.fromMap(data, doc.id);
    } catch (error) {
      throw mapExceptionToAttendanceFailure(error);
    }
  }

  /// Gets all sessions for a specific date.
  Future<List<AttendanceSession>> getSessionsForDate({
    required String teamId,
    required String dateKey,
  }) async {
    final snapshot = await _sessionsCol(
      teamId,
    ).where('dateKey', isEqualTo: dateKey).get();
    return _mapSessionsSnapshot(snapshot);
  }
}
