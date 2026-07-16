import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/sync_service.dart';
import 'package:church_management_system/core/utils/bulk_operation_result.dart';
import 'package:church_management_system/core/utils/list_extensions.dart';
import 'package:church_management_system/features/attendance/data/local/attendance_session_local_datasource.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_enums.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/services/student_query_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AttendanceCommandService {
  AttendanceCommandService({
    required FirebaseFirestore firestore,
    required SyncService Function() syncServiceGetter,
    StudentQueryService? studentQueryService,
    DateTime Function()? nowProvider,
    AttendanceSessionLocalDatasource? localDatasource,
    Connectivity? connectivity,
  }) : _firestore = firestore,
       _syncServiceGetter = syncServiceGetter,
       _studentQueryService =
           studentQueryService ?? StudentQueryService(firestore: firestore),
       _nowProvider = nowProvider ?? DateTime.now,
       _localDatasource = localDatasource ?? AttendanceSessionLocalDatasource(),
       _connectivity = connectivity ?? Connectivity();

  final FirebaseFirestore _firestore;
  final SyncService Function() _syncServiceGetter;
  final StudentQueryService _studentQueryService;
  final DateTime Function() _nowProvider;
  final AttendanceSessionLocalDatasource _localDatasource;
  final Connectivity _connectivity;

  CollectionReference<Map<String, dynamic>> get _classesCollection =>
      _firestore.collection(FirestoreCollections.classes);

  DocumentReference<Map<String, dynamic>> _teamDoc(String teamId) =>
      _classesCollection.doc(teamId);

  CollectionReference<Map<String, dynamic>> get _sessionsCol =>
      _firestore.collection(FirestoreCollections.attendance);

  DocumentReference<Map<String, dynamic>> _sessionDoc(
    String teamId,
    String sessionId,
  ) => _sessionsCol.doc(sessionId);

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
  ) => _marksCol(teamId, sessionId).doc('${studentId}_$sessionId');

  Future<DocumentSnapshot<Map<String, dynamic>>> _cachedGet(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      return await ref.get(const GetOptions());
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        return await ref.get(const GetOptions(source: Source.cache));
      }
      rethrow;
    }
  }

  Future<AttendanceSession> createSession({
    required String teamId,
    required String teamNameSnapshot,
    required DateTime startsAt,
    required int durationMinutes,
    required AuthUser createdBy,
    String? title,
  }) async {
    try {
      final connectivity = await _connectivity.checkConnectivity();
      final isOffline = connectivity.contains(ConnectivityResult.none);

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

      await _assertTeamIsActive(normalizedTeamId);

      final normalizedTitle = title?.trim();
      final now = _nowProvider();
      final List<StudentModel> rosterStudents = await _studentQueryService
          .getStudentsByClass(normalizedTeamId);
      rosterStudents.sort((a, b) => a.name.compareTo(b.name));

      final candidate = AttendanceSession(
        id: _buildSessionId(startsAt, normalizedTitle),
        teamId: normalizedTeamId,
        teamNameSnapshot: teamNameSnapshot.trim().isEmpty
            ? null
            : teamNameSnapshot.trim(),
        title: normalizedTitle == null || normalizedTitle.isEmpty
            ? null
            : normalizedTitle,
        dateKey: AttendanceSession.buildDateKey(startsAt),
        startsAt: startsAt,
        endsAt: startsAt.add(Duration(minutes: durationMinutes)),
        durationMinutes: durationMinutes,
        createdByUserId: createdBy.uid,
        createdByName: createdBy.name,
        createdAt: now,
        updatedAt: now,
        studentIdsSnapshot: rosterStudents
            .map((student) => student.docID)
            .toList(growable: false),
        studentNameSnapshots: {
          for (final student in rosterStudents) student.docID: student.name,
        },
      );

      if (isOffline) {
        final syncEntry = SyncEntry(
          id: 'create_session_${candidate.id}',
          actionType: 'CREATE_SESSION',
          payload: AttendanceSessionModel.fromDomain(candidate).toMap(),
          createdAt: DateTime.now(),
        );
        await _syncServiceGetter().enqueue(syncEntry);
        await _localDatasource.cacheSession(candidate);
        return candidate;
      }

      final activeSessionsSnapshot = await _sessionsCol
          .where('teamId', isEqualTo: normalizedTeamId)
          .where('isClosed', isEqualTo: false)
          .get();
      final existingSessions = _mapSessionsSnapshot(activeSessionsSnapshot);

      for (final existing in existingSessions) {
        final isActiveConflict =
            !existing.isEffectivelyClosedAt(now) &&
            _sessionsOverlap(candidate, existing);
        if (isActiveConflict ||
            _isDuplicateSessionCandidate(candidate, existing)) {
          throw const AttendanceSessionConflictFailure();
        }
      }

      final docRef = _sessionDoc(normalizedTeamId, candidate.id);
      await _firestore.runTransaction((transaction) async {
        final existingDoc = await transaction.get(docRef);
        if (existingDoc.exists) {
          throw const AttendanceSessionConflictFailure(
            'تم إنشاء جلسة حضور مطابقة بالفعل.',
          );
        }

        transaction.set(docRef, {
          ...AttendanceSessionModel.fromDomain(candidate).toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!isOffline) {
        await _localDatasource.cacheSession(candidate);
      }
      return candidate;
    } catch (error) {
      if (error is AttendanceFailure) rethrow;
      throw mapExceptionToAttendanceFailure(error);
    }
  }

  Future<BulkOperationResult<String>> createSessionsBulk({
    required Map<String, String> teamIdsAndNames,
    required DateTime startsAt,
    required int durationMinutes,
    required AuthUser createdBy,
    String? title,
  }) async {
    final connectivity = await _connectivity.checkConnectivity();
    final isOffline = connectivity.contains(ConnectivityResult.none);
    if (isOffline) {
      throw const AttendanceValidationFailure(
        'لا يمكن إنشاء جلسات متعددة بدون اتصال بالإنترنت.',
      );
    }

    final successfulItems = <String>[];
    final failedItems = <String>[];

    final futures = teamIdsAndNames.entries.map((entry) async {
      try {
        await createSession(
          teamId: entry.key,
          teamNameSnapshot: entry.value,
          startsAt: startsAt,
          durationMinutes: durationMinutes,
          createdBy: createdBy,
          title: title,
        );
        successfulItems.add(entry.key);
      } catch (error) {
        developer.log(
          'Bulk session creation failed for team ${entry.key}',
          error: error,
          name: 'AttendanceRepository',
        );
        failedItems.add(entry.key);
      }
    });

    await Future.wait(futures);

    return BulkOperationResult(
      successfulItems: successfulItems,
      failedItems: failedItems,
    );
  }

  Future<void> closeSession({
    required String teamId,
    required String sessionId,
    required AuthUser closedBy,
  }) async {
    try {
      final connectivity = await _connectivity.checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        throw const AttendanceValidationFailure(
          'لا يمكن إغلاق جلسة الحضور بدون اتصال بالإنترنت.',
        );
      }

      final sessionRef = _sessionDoc(teamId, sessionId);
      final sessionDoc = await _cachedGet(sessionRef);
      if (!sessionDoc.exists || sessionDoc.data() == null) {
        throw const AttendanceSessionNotFoundFailure();
      }
      final session = AttendanceSessionModel.fromMap(
        sessionDoc.data()!,
        sessionDoc.id,
      ).toDomain();

      if (session.isClosed) {
        return;
      }

      final marksSnapshot = await _marksCol(teamId, sessionId).get();
      final markedStudentIds = <String>{};
      final presentStudentIds = <String>{};
      final lateStudentIds = <String>{};
      final studentMarks = <String, ({String status, Timestamp? markedAt})>{};

      for (final doc in marksSnapshot.docs) {
        final data = doc.data();
        final studentId =
            data['studentId'] as String? ?? doc.id.split('_').first;
        markedStudentIds.add(studentId);
        final status = data['status'] as String? ?? 'absent';
        if (status == 'present') {
          presentStudentIds.add(studentId);
        } else if (status == 'late') {
          lateStudentIds.add(studentId);
        }
        final dbTimestamp = data['markedAt'] ?? data['updatedAt'];
        final markedAt = dbTimestamp is Timestamp ? dbTimestamp : null;
        studentMarks[studentId] = (status: status, markedAt: markedAt);
      }

      final unmarkedStudents = session.studentIdsSnapshot
          .where((id) => !markedStudentIds.contains(id))
          .toList(growable: false);

      final presentAndLateStudentIds = {
        ...presentStudentIds,
        ...lateStudentIds,
      }.toList(growable: false);

      final totalOperations =
          unmarkedStudents.length +
          presentAndLateStudentIds.length +
          session.studentIdsSnapshot.length +
          2; // +1 for session, +1 for group

      if (totalOperations <= 500) {
        // Atomic update for everything via transaction (Idempotent)
        await _firestore.runTransaction((transaction) async {
          final sRef = _sessionDoc(teamId, sessionId);
          final sDoc = await transaction.get(sRef);

          if (sDoc.exists && sDoc.data()?['isClosed'] == true) {
            return;
          }

          // 1. Mark unmarked students as absent
          for (final studentId in unmarkedStudents) {
            final markRef = _markDoc(teamId, sessionId, studentId);
            transaction.set(markRef, {
              'studentId': studentId,
              'teamId': teamId,
              'sessionId': sessionId,
              'studentNameSnapshot':
                  session.studentNameSnapshots[studentId] ?? 'مخدوم',
              'status': AttendanceMarkStatus.absent.name,
              'markedByUserId': 'system',
              'markedByName': 'النظام',
              'markedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          // 2. Update Student Aggregates
          for (final studentId in presentAndLateStudentIds) {
            final studentRef = _firestore
                .collection(FirestoreCollections.students)
                .doc(studentId);
            transaction.set(studentRef, {
              'attendanceSummary': {
                'totalPresent': FieldValue.increment(1),
                'lastAttendanceDate': FieldValue.serverTimestamp(),
              },
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }

          // 3. Write per-student subcollection docs (Phase F)
          for (final studentId in session.studentIdsSnapshot) {
            final markData = studentMarks[studentId];
            final status = markData?.status ?? 'absent';
            final markedAt = markData?.markedAt;
            final studentSessionRef = _firestore
                .collection(FirestoreCollections.students)
                .doc(studentId)
                .collection(FirestoreCollections.attendanceSessions)
                .doc(sessionId);
            transaction.set(studentSessionRef, {
              'sessionId': sessionId,
              'teamId': teamId,
              'teamNameSnapshot': session.teamNameSnapshot,
              'studentId': studentId,
              'studentName': session.studentNameSnapshots[studentId] ?? 'مخدوم',
              'status': status,
              'markedAt': markedAt,
              'startsAt': Timestamp.fromDate(session.startsAt),
              'closedAt': FieldValue.serverTimestamp(),
              'durationMinutes': session.durationMinutes,
            });
          }

          // 4. Update Group Aggregate
          final absentCount =
              session.studentIdsSnapshot.length -
              presentAndLateStudentIds.length;
          final statsRef = _teamDoc(
            teamId,
          ).collection('stats').doc('attendance');
          transaction.set(statsRef, {
              'totalSessions': FieldValue.increment(1),
              'totalRosterEntries': FieldValue.increment(
                session.studentIdsSnapshot.length,
              ),
              'presentCount': FieldValue.increment(presentStudentIds.length),
              'lateCount': FieldValue.increment(lateStudentIds.length),
              'absentCount': FieldValue.increment(
                absentCount > 0 ? absentCount : 0,
              ),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            ..set(_teamDoc(teamId), {
              'groupAttendanceSummary': {
                'lastSessionDate': FieldValue.serverTimestamp(),
                'lastSessionAttendanceCount': presentAndLateStudentIds.length,
                'updatedAt': FieldValue.serverTimestamp(),
              },
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            ..update(sRef, {
              'isClosed': true,
              'closeSessionStatus': FieldValue.delete(),
              'updatedAt': FieldValue.serverTimestamp(),
              'presentCount': presentStudentIds.length,
              'lateCount': lateStudentIds.length,
              'absentCount': absentCount > 0 ? absentCount : 0,
            });
        });
      } else {
        // Fallback for very large groups: multi-batch (Not fully atomic, but idempotent)
        // Set in-progress flag
        await sessionRef.update({
          'closeSessionStatus': 'in_progress',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 1. Mark unmarked as absent in chunks
        for (final chunk in unmarkedStudents.chunk(450)) {
          final batch = _firestore.batch();
          for (final studentId in chunk) {
            final markRef = _markDoc(teamId, sessionId, studentId);
            batch.set(markRef, {
              'studentId': studentId,
              'teamId': teamId,
              'sessionId': sessionId,
              'studentNameSnapshot':
                  session.studentNameSnapshots[studentId] ?? 'مخدوم',
              'status': AttendanceMarkStatus.absent.name,
              'markedByUserId': 'system',
              'markedByName': 'النظام',
              'markedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          await batch.commit();
        }

        // 2. Student Aggregates (Batched)
        for (final chunk in presentAndLateStudentIds.chunk(450)) {
          final batch = _firestore.batch();
          for (final studentId in chunk) {
            final studentRef = _firestore
                .collection(FirestoreCollections.students)
                .doc(studentId);
            batch.set(studentRef, {
              'attendanceSummary': {
                'totalPresent': FieldValue.increment(1),
                'lastAttendanceDate': FieldValue.serverTimestamp(),
              },
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
          await batch.commit();
        }

        // 3. Write per-student subcollection docs (Batched) (Phase F)
        final rosterStudents = session.studentIdsSnapshot;
        for (final chunk in rosterStudents.chunk(450)) {
          final batch = _firestore.batch();
          for (final studentId in chunk) {
            final markData = studentMarks[studentId];
            final status = markData?.status ?? 'absent';
            final markedAt = markData?.markedAt;
            final studentSessionRef = _firestore
                .collection(FirestoreCollections.students)
                .doc(studentId)
                .collection(FirestoreCollections.attendanceSessions)
                .doc(sessionId);
            batch.set(studentSessionRef, {
              'sessionId': sessionId,
              'teamId': teamId,
              'teamNameSnapshot': session.teamNameSnapshot,
              'studentId': studentId,
              'studentName': session.studentNameSnapshots[studentId] ?? 'مخدوم',
              'status': status,
              'markedAt': markedAt,
              'startsAt': Timestamp.fromDate(session.startsAt),
              'closedAt': FieldValue.serverTimestamp(),
              'durationMinutes': session.durationMinutes,
            });
          }
          await batch.commit();
        }

        // 4. Final IDEMPOTENT step for group aggregate and session status
        await _firestore.runTransaction((transaction) async {
          final sRef = _sessionDoc(teamId, sessionId);
          final sDoc = await transaction.get(sRef);

          if (sDoc.exists && sDoc.data()?['isClosed'] == true) {
            return;
          }

          final absentCount =
              session.studentIdsSnapshot.length -
              presentAndLateStudentIds.length;
          final statsRef = _teamDoc(
            teamId,
          ).collection('stats').doc('attendance');
          transaction.set(statsRef, {
              'totalSessions': FieldValue.increment(1),
              'totalRosterEntries': FieldValue.increment(
                session.studentIdsSnapshot.length,
              ),
              'presentCount': FieldValue.increment(presentStudentIds.length),
              'lateCount': FieldValue.increment(lateStudentIds.length),
              'absentCount': FieldValue.increment(
                absentCount > 0 ? absentCount : 0,
              ),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            ..set(_teamDoc(teamId), {
              'groupAttendanceSummary': {
                'lastSessionDate': FieldValue.serverTimestamp(),
                'lastSessionAttendanceCount': presentAndLateStudentIds.length,
                'updatedAt': FieldValue.serverTimestamp(),
              },
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            ..update(sRef, {
              'isClosed': true,
              'closeSessionStatus': FieldValue.delete(),
              'updatedAt': FieldValue.serverTimestamp(),
              'presentCount': presentStudentIds.length,
              'lateCount': lateStudentIds.length,
              'absentCount': absentCount > 0 ? absentCount : 0,
            });
        });
      }
    } catch (error) {
      if (error is AttendanceFailure) rethrow;
      throw mapExceptionToAttendanceFailure(error);
    }
  }

  Future<void> markStudentPresent({
    required String teamId,
    required String sessionId,
    required String studentId,
    required String studentNameSnapshot,
    required AuthUser markedBy,
    String? note,
  }) => _writeMark(
    teamId: teamId,
    sessionId: sessionId,
    studentId: studentId,
    studentNameSnapshot: studentNameSnapshot,
    markedBy: markedBy,
    status: AttendanceMarkStatus.present,
    note: note,
  );

  Future<void> markStudentLate({
    required String teamId,
    required String sessionId,
    required String studentId,
    required String studentNameSnapshot,
    required AuthUser markedBy,
    String? note,
  }) => _writeMark(
    teamId: teamId,
    sessionId: sessionId,
    studentId: studentId,
    studentNameSnapshot: studentNameSnapshot,
    markedBy: markedBy,
    status: AttendanceMarkStatus.late,
    note: note,
  );

  Future<void> clearStudentMark({
    required String teamId,
    required String sessionId,
    required String studentId,
    required AuthUser requestedBy,
  }) async {
    try {
      await _markDoc(teamId, sessionId, studentId).delete();
    } catch (error) {
      if (error is AttendanceFailure) rethrow;
      throw mapExceptionToAttendanceFailure(error);
    }
  }

  Future<void> syncOfflineMark(Map<String, dynamic> payload) async {
    try {
      final teamId = payload['teamId'] as String;
      final sessionId = payload['sessionId'] as String;
      final studentId = payload['studentId'] as String;
      final statusString = payload['status'] as String;
      final markedByUid = payload['markedByUid'] as String;
      final markedByName = payload['markedByName'] as String;
      final createdAt = DateTime.parse(payload['createdAt'] as String);

      final sessionRef = _sessionDoc(teamId, sessionId);
      final markRef = _markDoc(teamId, sessionId, studentId);

      await _firestore.runTransaction((transaction) async {
        final sessionDoc = await transaction.get(sessionRef);
        if (!sessionDoc.exists) {
          return;
        }

        final sessionData = sessionDoc.data() ?? {};
        final sessionTeamId = sessionData['teamId'] as String?;
        if (sessionTeamId != teamId) {
          throw const AttendancePermissionDeniedFailure(
            'Session teamId does not match the requested teamId.',
          );
        }

        final markDoc = await transaction.get(markRef);
        String? oldStatus;

        if (markDoc.exists) {
          final data = markDoc.data();
          if (data != null) {
            oldStatus = data['status'] as String?;
            final dbTimestamp = data['updatedAt'] ?? data['markedAt'];
            if (dbTimestamp is Timestamp) {
              if (dbTimestamp.toDate().isAfter(createdAt)) {
                return; // Database is newer, abort write (LWW)
              }
            }
          }
        }

        final sessionData2 = sessionDoc.data() ?? {};
        final studentNameSnapshots =
            sessionData2['studentNameSnapshots'] as Map<String, dynamic>?;
        final studentName = studentNameSnapshots?[studentId] ?? 'مخدوم';

        final markData = <String, dynamic>{
          'studentId': studentId,
          'teamId': teamId,
          'sessionId': sessionId,
          'studentNameSnapshot': studentName,
          'status': statusString,
          'markedByUserId': markedByUid,
          'markedByName': markedByName,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (!markDoc.exists) {
          markData['markedAt'] = Timestamp.fromDate(createdAt);
        }

        transaction.set(markRef, markData, SetOptions(merge: true));

        // Aggregation Support
        if (oldStatus != statusString) {
          if (statusString == 'present' && oldStatus != 'present') {
            transaction.update(sessionRef, {
              'presentCount': FieldValue.increment(1),
            });
          } else if (statusString == 'absent' && oldStatus == 'present') {
            transaction.update(sessionRef, {
              'presentCount': FieldValue.increment(-1),
            });
          }
        }
      });
    } catch (error) {
      if (error is AttendanceFailure) rethrow;
      throw mapExceptionToAttendanceFailure(error);
    }
  }

  Future<void> syncBatchedMarks({
    required String teamId,
    required String sessionId,
    required List<Map<String, dynamic>> payloads,
  }) async {
    if (payloads.isEmpty) return;
    try {
      final sessionRef = _sessionDoc(teamId, sessionId);
      final sessionDoc = await _cachedGet(sessionRef);
      if (!sessionDoc.exists || sessionDoc.data() == null) {
        throw const AttendanceSessionNotFoundFailure();
      }
      final sessionData = sessionDoc.data()!;
      if (sessionData['teamId'] != teamId) {
        throw const AttendancePermissionDeniedFailure(
          'Session teamId does not match the requested teamId.',
        );
      }

      const int chunkSize = 400; // stay safely under Firestore's 500-op limit
      for (int offset = 0; offset < payloads.length; offset += chunkSize) {
        final chunk = payloads.sublist(
          offset,
          (offset + chunkSize).clamp(0, payloads.length),
        );

        await _firestore.runTransaction((transaction) async {
          int chunkPresentDelta = 0;

          // 1. Gather all documents
          final markRefsAndPayloads =
              <DocumentReference<Map<String, dynamic>>, Map<String, dynamic>>{};
          final existingDocs =
              <
                DocumentReference<Map<String, dynamic>>,
                DocumentSnapshot<Map<String, dynamic>>
              >{};

          for (final payload in chunk) {
            final studentId = payload['studentId'] as String? ?? '';
            if (studentId.isEmpty) continue;
            final markRef = _markDoc(teamId, sessionId, studentId);
            markRefsAndPayloads[markRef] = payload;
            existingDocs[markRef] = await transaction.get(markRef);
          }

          // 2. Perform transactional updates
          for (final entry in markRefsAndPayloads.entries) {
            final markRef = entry.key;
            final payload = entry.value;
            final studentId = payload['studentId'] as String;
            final statusString = payload['status'] as String? ?? 'absent';
            final markedByUid = payload['markedByUid'] as String? ?? 'system';
            final markedByName = payload['markedByName'] as String? ?? 'النظام';
            final rawCreatedAt = payload['createdAt'] as String?;
            final createdAt = rawCreatedAt != null
                ? DateTime.tryParse(rawCreatedAt) ?? DateTime.now()
                : DateTime.now();

            final existingDoc = existingDocs[markRef]!;
            String? oldStatus;

            if (existingDoc.exists) {
              final data = existingDoc.data();
              if (data != null) {
                oldStatus = data['status'] as String?;
                final dbTimestamp = data['updatedAt'] ?? data['markedAt'];
                if (dbTimestamp is Timestamp &&
                    dbTimestamp.toDate().isAfter(createdAt)) {
                  // Server is newer — skip this mark (LWW).
                  continue;
                }
              }
            }

            final markData = <String, dynamic>{
              'studentId': studentId,
              'teamId': teamId,
              'sessionId': sessionId,
              'status': statusString,
              'markedByUserId': markedByUid,
              'markedByName': markedByName,
              'updatedAt': FieldValue.serverTimestamp(),
            };

            if (!existingDoc.exists) {
              markData['markedAt'] = Timestamp.fromDate(createdAt);
              final snapshotName = payload['studentNameSnapshot'] as String?;
              markData['studentNameSnapshot'] =
                  (snapshotName?.isNotEmpty == true) ? snapshotName! : 'مخدوم';
            }

            transaction.set(markRef, markData, SetOptions(merge: true));

            if (statusString == 'present' && oldStatus != 'present') {
              chunkPresentDelta++;
            } else if (oldStatus == 'present' && statusString != 'present') {
              chunkPresentDelta--;
            }
          }

          if (chunkPresentDelta != 0) {
            transaction.update(sessionRef, {
              'presentCount': FieldValue.increment(chunkPresentDelta),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        });
      }
    } catch (error) {
      if (error is AttendanceFailure) rethrow;
      throw mapExceptionToAttendanceFailure(error);
    }
  }

  Future<void> _writeMark({
    required String teamId,
    required String sessionId,
    required String studentId,
    required String studentNameSnapshot,
    required AuthUser markedBy,
    required AttendanceMarkStatus status,
    String? note,
  }) async {
    try {
      final markRef = _markDoc(teamId, sessionId, studentId);
      final effectiveStudentName = studentNameSnapshot.trim();
      final normalizedNote = note?.trim();

      await _firestore.runTransaction((transaction) async {
        final sessionRef = _sessionDoc(teamId, sessionId);
        final sessionDoc = await transaction.get(sessionRef);
        if (!sessionDoc.exists || sessionDoc.data() == null) {
          throw const AttendanceSessionNotFoundFailure();
        }
        final session = AttendanceSessionModel.fromMap(
          sessionDoc.data()!,
          sessionDoc.id,
        ).toDomain();

        if (session.teamId != teamId) {
          throw const AttendancePermissionDeniedFailure(
            'Session teamId does not match the requested teamId.',
          );
        }

        final now = _nowProvider();
        final canMark = !session.isClosed || session.isOpenAt(now);

        if (!canMark) {
          throw const AttendanceSessionClosedFailure();
        }

        final existingDoc = await transaction.get(markRef);
        final existingMarkedAt = existingDoc.data()?['markedAt'];

        final data = <String, dynamic>{
          'studentId': studentId,
          'teamId': teamId,
          'sessionId': sessionId,
          'status': status.name,
          'markedByUserId': markedBy.uid,
          'markedByName': markedBy.name,
          'updatedAt': FieldValue.serverTimestamp(),
          'note': normalizedNote == null || normalizedNote.isEmpty
              ? FieldValue.delete()
              : normalizedNote,
        };

        if (existingMarkedAt == null) {
          data['studentNameSnapshot'] = effectiveStudentName;
          data['markedAt'] = FieldValue.serverTimestamp();
        } else {
          data['markedAt'] = existingMarkedAt;
        }

        transaction.set(markRef, data, SetOptions(merge: true));
      });
    } catch (error) {
      if (error is AttendanceFailure) rethrow;
      throw mapExceptionToAttendanceFailure(error);
    }
  }

  Future<void> _assertTeamIsActive(String teamId) async {
    final teamDoc = await _cachedGet(_teamDoc(teamId));
    if (!teamDoc.exists || teamDoc.data()?['isArchived'] == true) {
      throw const AttendanceValidationFailure('الفريق غير نشط.');
    }
  }

  String _normalizeTitle(String? title) {
    return title?.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase() ?? '';
  }

  String _slugifyTitle(String? title) {
    if (title == null || title.trim().isEmpty) return 'session';
    final normalized = _normalizeTitle(title);
    final slug = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final cleaned = slug.replaceAll(RegExp(r'^-+|-+$'), '');
    if (cleaned.isEmpty) {
      final hashStr = title.hashCode.abs().toString();
      final hash = hashStr.length >= 6
          ? hashStr.substring(0, 6)
          : hashStr.padRight(6, '0');
      return 'session-$hash';
    }
    if (cleaned.length <= 40) return cleaned;
    return cleaned.substring(0, 40);
  }

  String _buildSessionId(DateTime startsAt, String? title) {
    final dateKey = AttendanceSession.buildDateKey(startsAt);
    final timeKey = startsAt.toUtc().millisecondsSinceEpoch;
    return '${dateKey}_${timeKey}_${_slugifyTitle(title)}';
  }

  Future<void> batchWriteMarks({
    required String teamId,
    required String sessionId,
    required Map<String, ({AttendanceMarkStatus status, DateTime markedAt})>
    marks,
    required AuthUser markedBy,
    bool cachedPermission = false,
  }) async {
    try {
      final sessionRef = _sessionDoc(teamId, sessionId);
      final sessionDoc = await _cachedGet(sessionRef);
      if (!sessionDoc.exists || sessionDoc.data() == null) {
        throw const AttendanceSessionNotFoundFailure();
      }
      final session = AttendanceSessionModel.fromMap(
        sessionDoc.data()!,
        sessionDoc.id,
      ).toDomain();

      if (session.teamId != teamId) {
        throw const AttendancePermissionDeniedFailure(
          'Session teamId does not match the requested teamId.',
        );
      }

      if (marks.isEmpty) return;

      final entries = marks.entries.toList(growable: false);
      for (final chunk in entries.chunk(400)) {
        await _firestore.runTransaction((transaction) async {
          int chunkPresentDelta = 0;

          // 1. Gather all documents
          final markRefsAndEntries =
              <
                DocumentReference<Map<String, dynamic>>,
                MapEntry<
                  String,
                  ({AttendanceMarkStatus status, DateTime markedAt})
                >
              >{};
          final existingDocs =
              <
                DocumentReference<Map<String, dynamic>>,
                DocumentSnapshot<Map<String, dynamic>>
              >{};

          for (final entry in chunk) {
            final studentId = entry.key;
            final markRef = _markDoc(teamId, sessionId, studentId);
            markRefsAndEntries[markRef] = entry;
            existingDocs[markRef] = await transaction.get(markRef);
          }

          // 2. Perform transactional updates
          for (final entry in markRefsAndEntries.entries) {
            final markRef = entry.key;
            final studentId = entry.value.key;
            final targetStatus = entry.value.value.status;
            final payloadMarkedAt = entry.value.value.markedAt;

            final existingDoc = existingDocs[markRef]!;
            String? oldStatus;

            if (existingDoc.exists) {
              final data = existingDoc.data();
              if (data != null) {
                oldStatus = data['status'] as String?;
                final dbTimestamp = data['updatedAt'] ?? data['markedAt'];
                if (dbTimestamp is Timestamp &&
                    dbTimestamp.toDate().isAfter(payloadMarkedAt)) {
                  // Server is newer — skip (LWW)
                  continue;
                }
              }
            }

            final studentName =
                session.studentNameSnapshots[studentId] ?? 'مخدوم';
            final markData = <String, dynamic>{
              'studentId': studentId,
              'teamId': teamId,
              'sessionId': sessionId,
              'studentNameSnapshot': studentName,
              'status': targetStatus.name,
              'markedByUserId': markedBy.uid,
              'markedByName': markedBy.name,
              'updatedAt': FieldValue.serverTimestamp(),
            };

            if (!existingDoc.exists) {
              markData['markedAt'] = Timestamp.fromDate(payloadMarkedAt);
            }

            transaction.set(markRef, markData, SetOptions(merge: true));

            if (targetStatus == AttendanceMarkStatus.present &&
                oldStatus != 'present') {
              chunkPresentDelta++;
            } else if (oldStatus == 'present' &&
                targetStatus != AttendanceMarkStatus.present) {
              chunkPresentDelta--;
            }
          }

          if (chunkPresentDelta != 0) {
            transaction.update(sessionRef, {
              'presentCount': FieldValue.increment(chunkPresentDelta),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        });
      }
    } catch (error) {
      if (error is AttendanceFailure) rethrow;
      throw mapExceptionToAttendanceFailure(error);
    }
  }

  Future<void> markAllPresentForRemainingStudents({
    required String teamId,
    required String sessionId,
    required AuthUser markedBy,
  }) async {
    try {
      final sessionRef = _sessionDoc(teamId, sessionId);
      final sessionDoc = await _cachedGet(sessionRef);
      if (!sessionDoc.exists || sessionDoc.data() == null) {
        throw const AttendanceSessionNotFoundFailure();
      }
      final session = AttendanceSessionModel.fromMap(
        sessionDoc.data()!,
        sessionDoc.id,
      ).toDomain();

      final existingMarksSnapshot = await _marksCol(
        teamId,
        sessionId,
      ).get(const GetOptions());
      final existingMarkedStudentIds = existingMarksSnapshot.docs
          .map(
            (doc) =>
                doc.data()['studentId'] as String? ?? doc.id.split('_').first,
          )
          .toSet();

      final unmarkedStudents = session.studentIdsSnapshot
          .where((id) => !existingMarkedStudentIds.contains(id))
          .toList(growable: false);

      for (final chunk in unmarkedStudents.chunk(400)) {
        final batch = _firestore.batch();
        for (final studentId in chunk) {
          final markRef = _markDoc(teamId, sessionId, studentId);
          final studentName =
              session.studentNameSnapshots[studentId] ?? 'مخدوم';

          batch.set(markRef, {
            'studentId': studentId,
            'teamId': teamId,
            'sessionId': sessionId,
            'studentNameSnapshot': studentName,
            'status': AttendanceMarkStatus.present.name,
            'markedByUserId': markedBy.uid,
            'markedByName': markedBy.name,
            'markedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        batch.set(_sessionDoc(teamId, sessionId), {
          'presentCount': FieldValue.increment(chunk.length),
        }, SetOptions(merge: true));
        await batch.commit();
      }
    } catch (error) {
      if (error is AttendanceFailure) rethrow;
      throw mapExceptionToAttendanceFailure(error);
    }
  }

  bool _sessionsOverlap(AttendanceSession first, AttendanceSession second) {
    return first.startsAt.isBefore(second.endsAt) &&
        second.startsAt.isBefore(first.endsAt);
  }

  bool _isDuplicateSessionCandidate(
    AttendanceSession candidate,
    AttendanceSession existing,
  ) {
    return candidate.dateKey == existing.dateKey &&
        candidate.startsAt.millisecondsSinceEpoch ==
            existing.startsAt.millisecondsSinceEpoch &&
        candidate.durationMinutes == existing.durationMinutes &&
        _normalizeTitle(candidate.title) == _normalizeTitle(existing.title);
  }

  AttendanceSession _mapSessionDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return AttendanceSessionModel.fromMap(doc.data(), doc.id).toDomain();
  }

  List<AttendanceSession> _mapSessionsSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final sessions = <AttendanceSession>[];
    for (final doc in snapshot.docs) {
      try {
        sessions.add(_mapSessionDoc(doc));
      } catch (error) {
        developer.log(
          'skipped malformed attendance session ${doc.reference.path}',
          error: error,
          name: 'AttendanceCommandService',
        );
      }
    }
    sessions.sort((first, second) => second.startsAt.compareTo(first.startsAt));
    return sessions;
  }
}
