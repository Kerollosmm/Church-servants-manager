import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/core/constants/sync_action_type.dart';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/firestore_batch_util.dart';
import 'package:church_management_system/core/services/sync_service.dart';
import 'package:church_management_system/core/utils/pagination_cursor.dart';
import 'package:church_management_system/core/utils/sync_error_classifier.dart';
import 'package:church_management_system/features/student/data/datasources/student_local_datasource.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/services/student_linked_user_sync_service.dart';
import 'package:church_management_system/features/student/data/services/student_query_service.dart';
import 'package:church_management_system/features/student/domain/entities/student.dart';
import 'package:church_management_system/features/student/domain/failures/student_failures.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Repository for student data operations.
///
/// Delegates to [StudentQueryService] for queries and
/// [StudentLinkedUserSyncService] for auth user sync.
class StudentDataRepository implements IStudentRepository {
  final FirebaseFirestore _firestore;
  final StudentQueryService _queryService;
  final StudentLinkedUserSyncService _linkedUserSyncService;
  final StudentLocalDatasource _localDatasource;
  final SyncService Function() _syncServiceGetter;

  StudentDataRepository({
    required FirebaseFirestore firestore,
    StudentQueryService? queryService,
    StudentLinkedUserSyncService? linkedUserSyncService,
    StudentLocalDatasource? localDatasource,
    required SyncService Function() syncServiceGetter,
  }) : _firestore = firestore,
       _queryService =
           queryService ?? StudentQueryService(firestore: firestore),
       _linkedUserSyncService =
           linkedUserSyncService ??
           StudentLinkedUserSyncService(firestore: firestore),
       _localDatasource = localDatasource ?? StudentLocalDatasource(),
       _syncServiceGetter = syncServiceGetter;

  CollectionReference<Map<String, dynamic>> get _studentsCollection =>
      _firestore.collection(FirestoreCollections.students);
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestoreCollections.servants);

  @override
  Future<void> syncLinkedUserRoleFromStudent({
    required Student updatedStudent,
    required UserRole previousRole,
    String? updatedEmail,
  }) async {
    return _linkedUserSyncService.syncLinkedUserRoleFromStudent(
      updatedStudent: StudentModel.fromDomain(updatedStudent),
      previousRole: previousRole,
      updatedEmail: updatedEmail,
    );
  }

  @override
  Future<void> updateStudentAndSyncLinkedUserRole({
    required Student updatedStudent,
    required UserRole previousRole,
    String? updatedEmail,
  }) async {
    try {
      final model = StudentModel.fromDomain(updatedStudent);
      final pendingStudent = model.copyWith(
        syncStatus: SyncStatus.pending,
        clientUpdatedAt: DateTime.now(),
      );

      // Save to local cache first
      await _localDatasource.saveStudent(pendingStudent);

      // SyncEntry.id is the Hive box key — Stable per logical operation is
      // REQUIRED for dedup: box.put() overwrites by id, so re-enqueuing the
      // same upsert must collapse onto the prior queued (unsent) entry rather
      // than append a second one. A timestamp/UUID suffix would defeat this.
      final syncEntry = SyncEntry.create(
        id: 'upsert_student_${updatedStudent.docID}',
        action: SyncActionType.upsertStudent,
        payload: {
          'student': pendingStudent.toMap(),
          'syncLinkedUser': true,
          'previousRole': previousRole.name,
          'updatedEmail': updatedEmail,
        },
        createdAt: DateTime.now(),
      );

      // Enqueue to offline sync queue immediately
      await _syncServiceGetter().enqueue(syncEntry);

      // Trigger background processing asynchronously
      unawaited(
        _syncServiceGetter().processQueue().catchError((e, st) {
          developer.log(
            'Failed to process sync queue after student creation',
            error: e,
            stackTrace: st,
            name: 'StudentDataRepository',
          );
        }),
      );
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<Student?> getStudentById(
    String docId, {
    bool includeArchived = false,
  }) async {
    final model = await _queryService.getStudentById(
      docId,
      includeArchived: includeArchived,
    );
    return model?.toDomain();
  }

  @override
  Future<Student?> getStudentByUid(
    String uid, {
    bool includeArchived = false,
  }) async {
    final model = await _queryService.getStudentByUid(
      uid,
      includeArchived: includeArchived,
    );
    return model?.toDomain();
  }

  @override
  Future<List<Student>> getAllStudents({
    int limit = 10,
    PaginationCursor? cursor,
    bool includeArchived = false,
  }) async {
    final token = cursor?.token;
    final lastDoc = token is DocumentSnapshot ? token : null;
    final models = await _queryService.getAllStudents(
      limit: limit,
      lastDocument: lastDoc,
      includeArchived: includeArchived,
    );
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  Future<List<Student>> getStudentsByClass(
    String classId, {
    bool includeArchived = false,
  }) async {
    final models = await _queryService.getStudentsByClass(
      classId,
      includeArchived: includeArchived,
    );
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  Future<List<Student>> getStudentsByClasses(
    List<String> classIds, {
    bool includeArchived = false,
  }) async {
    final models = await _queryService.getStudentsByClasses(
      classIds,
      includeArchived: includeArchived,
    );
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  Future<List<Student>> getStudentsByGrade(
    int grade, {
    bool includeArchived = false,
  }) async {
    final models = await _queryService.getStudentsByGrade(
      grade,
      includeArchived: includeArchived,
    );
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  Future<List<Student>> getStudentsByGroup(
    String groupName, {
    bool includeArchived = false,
  }) async {
    final models = await _queryService.getStudentsByGroup(
      groupName,
      includeArchived: includeArchived,
    );
    return models.map((m) => m.toDomain()).toList();
  }

  @override
  Future<({List<Student> students, bool isFromCache})>
  getStudentsByGroupWithFallback(
    String groupName, {
    bool includeArchived = false,
  }) async {
    final result = await _queryService.getStudentsByGroupWithFallback(
      groupName,
      includeArchived: includeArchived,
    );
    return (
      students: result.students.map((m) => m.toDomain()).toList(),
      isFromCache: result.isFromCache,
    );
  }

  @override
  Future<List<Student>> searchStudents(
    String query, {
    int limit = 20,
    String? groupId,
    String? classId,
    bool includeArchived = false,
  }) async {
    try {
      if (query.isEmpty) {
        if (classId != null && classId.isNotEmpty) {
          return getStudentsByClass(classId, includeArchived: includeArchived);
        }
        if (groupId != null && groupId.isNotEmpty) {
          return getStudentsByGroup(groupId, includeArchived: includeArchived);
        }
        return getAllStudents(limit: limit, includeArchived: includeArchived);
      }

      Query<Map<String, dynamic>> firestoreQuery = _studentsCollection.orderBy(
        'name',
      );

      if (classId != null && classId.isNotEmpty) {
        firestoreQuery = firestoreQuery.where('classId', isEqualTo: classId);
      } else if (groupId != null && groupId.isNotEmpty) {
        firestoreQuery = firestoreQuery.where('group', isEqualTo: groupId);
      }

      if (!includeArchived) {
        firestoreQuery = firestoreQuery.where('isArchived', isEqualTo: false);
      }

      final snapshot = await firestoreQuery
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(limit)
          .get(const GetOptions());

      final models = _queryService
          .mapStudentDocs(snapshot.docs)
          .students
          .take(limit)
          .toList();

      return models.map((m) => m.toDomain()).toList();
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<String> createStudent(Student student, {String? email}) async {
    try {
      final docId = student.docID.isNotEmpty
          ? student.docID
          : const Uuid().v4();

      if (email != null && docId == email.trim().toLowerCase()) {
        throw const ArgumentFailure('Student docID must not be email');
      }

      final studentUid = student.uid.isNotEmpty ? student.uid : '';

      final finalStudent = StudentModel.fromDomain(student).copyWith(
        docID: docId,
        uid: studentUid,
        syncStatus: SyncStatus.pending,
        clientUpdatedAt: DateTime.now(),
      );

      // Save to local cache first
      await _localDatasource.saveStudent(finalStudent);

      final hasEmail = email != null && email.trim().isNotEmpty;

      final syncEntry = SyncEntry.create(
        id: 'upsert_student_$docId',
        action: hasEmail
            ? SyncActionType.createStudentInvitation
            : SyncActionType.upsertStudent,
        payload: {
          'student': finalStudent.toMap(),
          if (hasEmail) ...{'email': email.trim().toLowerCase()},
        },
        createdAt: DateTime.now(),
      );

      // Enqueue to offline sync queue immediately
      await _syncServiceGetter().enqueue(syncEntry);

      // Trigger background processing asynchronously
      unawaited(
        _syncServiceGetter().processQueue().catchError((e, st) {
          developer.log(
            'Failed to process sync queue after student update',
            error: e,
            stackTrace: st,
            name: 'StudentDataRepository',
          );
        }),
      );

      return docId;
    } catch (e) {
      if (e is StudentFailure) rethrow;
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<void> updateStudent(Student student) async {
    try {
      final previousStudent = await _localDatasource.getStudent(student.docID);
      final previousRole = previousStudent?.role ?? student.role;

      final pendingStudent = StudentModel.fromDomain(student).copyWith(
        syncStatus: SyncStatus.pending,
        clientUpdatedAt: DateTime.now(),
      );

      // Save to local cache first
      await _localDatasource.saveStudent(pendingStudent);

      final hasLinkedUser = student.uid.trim().isNotEmpty;
      final syncEntry = SyncEntry.create(
        id: 'upsert_student_${student.docID}',
        action: SyncActionType.upsertStudent,
        payload: {
          'student': pendingStudent.toMap(),
          if (hasLinkedUser) ...{
            'syncLinkedUser': true,
            'previousRole': previousRole.name,
          },
        },
        createdAt: DateTime.now(),
      );

      // Enqueue to offline sync queue immediately
      await _syncServiceGetter().enqueue(syncEntry);

      // Trigger background processing asynchronously
      unawaited(
        _syncServiceGetter().processQueue().catchError((e, st) {
          developer.log(
            'Failed to process sync queue after student upsert',
            error: e,
            stackTrace: st,
            name: 'StudentDataRepository',
          );
        }),
      );
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<void> upsertStudent(Student student) async {
    try {
      final previousStudent = await _localDatasource.getStudent(student.docID);
      final previousRole = previousStudent?.role ?? student.role;

      final pendingStudent = StudentModel.fromDomain(student).copyWith(
        syncStatus: SyncStatus.pending,
        clientUpdatedAt: DateTime.now(),
      );

      // Save to local cache first
      await _localDatasource.saveStudent(pendingStudent);

      final hasLinkedUser = student.uid.trim().isNotEmpty;
      final syncEntry = SyncEntry.create(
        id: 'upsert_student_${student.docID}',
        action: SyncActionType.upsertStudent,
        payload: {
          'student': pendingStudent.toMap(),
          if (hasLinkedUser) ...{
            'syncLinkedUser': true,
            'previousRole': previousRole.name,
          },
        },
        createdAt: DateTime.now(),
      );

      try {
        if (hasLinkedUser) {
          await _linkedUserSyncService.updateStudentAndSyncLinkedUserRole(
            updatedStudent: pendingStudent,
            previousRole: previousRole,
          );
        } else {
          await _studentsCollection.doc(student.docID).set({
            ...pendingStudent.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        final syncedStudent = pendingStudent.copyWith(
          syncStatus: SyncStatus.synced,
        );
        await _localDatasource.saveStudent(syncedStudent);
      } catch (e) {
        if (!SyncErrorClassifier.isRetriable(e)) {
          rethrow;
        }
        developer.log(
          'Failed to upsert student online, enqueuing for offline sync',
          error: e,
          name: 'StudentDataRepository',
        );
        // Fallback to queue on failure
        await _syncServiceGetter().enqueue(syncEntry);
      }
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<void> archiveStudent(
    String docId, {
    required String performedByUid,
  }) async {
    try {
      final student = await getStudentById(docId);
      if (student == null) {
        return;
      }

      // Update local cache first
      final archivedStudent = StudentModel.fromDomain(student).copyWith(
        isArchived: true,
        archivedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
        clientUpdatedAt: DateTime.now(),
      );
      await _localDatasource.saveStudent(archivedStudent);

      final syncEntry = SyncEntry.create(
        id: 'archive_student_${docId}_${DateTime.now().millisecondsSinceEpoch}',
        action: SyncActionType.archiveStudent,
        payload: {
          'docId': docId,
          'performedByUid': performedByUid,
          'clientUpdatedAt': archivedStudent.clientUpdatedAt?.toIso8601String(),
        },
        createdAt: DateTime.now(),
      );

      // Enqueue to offline sync queue immediately
      await _syncServiceGetter().enqueue(syncEntry);

      // Trigger background processing asynchronously
      unawaited(
        _syncServiceGetter().processQueue().catchError((e, st) {
          developer.log(
            'Failed to process sync queue after student archiving',
            error: e,
            stackTrace: st,
            name: 'StudentDataRepository',
          );
        }),
      );
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<void> restoreStudent(
    String docId, {
    required String performedByUid,
  }) async {
    try {
      final student = await getStudentById(docId, includeArchived: true);
      if (student == null) {
        return;
      }

      // Update local cache first
      final restoredStudent = StudentModel.fromDomain(student).copyWith(
        isArchived: false,
        restoredAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
        clientUpdatedAt: DateTime.now(),
      );
      await _localDatasource.saveStudent(restoredStudent);

      final syncEntry = SyncEntry.create(
        id: 'restore_student_${docId}_${DateTime.now().millisecondsSinceEpoch}',
        action: SyncActionType.restoreStudent,
        payload: {
          'docId': docId,
          'performedByUid': performedByUid,
          'clientUpdatedAt': restoredStudent.clientUpdatedAt?.toIso8601String(),
        },
        createdAt: DateTime.now(),
      );

      // Enqueue to offline sync queue immediately
      await _syncServiceGetter().enqueue(syncEntry);

      // Trigger background processing asynchronously
      unawaited(
        _syncServiceGetter().processQueue().catchError((e, st) {
          developer.log(
            'Failed to process sync queue after student restoration',
            error: e,
            stackTrace: st,
            name: 'StudentDataRepository',
          );
        }),
      );
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  /// Helper to get student IDs for given class IDs (batch query)
  @override
  Future<List<String>> getStudentIdsByClasses(List<String> classIds) async {
    return _queryService.getStudentIdsByClasses(classIds);
  }

  @override
  Future<void> syncOfflineUpdate(Map<String, dynamic> payload) async {
    // Redirect to upsert to execute direct Firestore write instead of enqueuing loop
    await syncOfflineUpsert(payload);
  }

  @override
  Future<void> syncOfflineUpsert(Map<String, dynamic> payload) async {
    final studentData = payload['student'] as Map<String, dynamic>;
    final student = StudentModel.fromMap(
      studentData,
      studentData['docID'] as String,
    );

    try {
      final docRef = _studentsCollection.doc(student.docID);
      final syncLinkedUser = payload['syncLinkedUser'] as bool? ?? false;
      final uid = student.uid.trim();

      if (syncLinkedUser && uid.isNotEmpty) {
        final previousRoleName = payload['previousRole'] as String;
        final previousRole = UserRole.values.byName(previousRoleName);
        final updatedEmail = payload['updatedEmail'] as String?;
        final linkedUserPatch = _linkedUserSyncService.buildLinkedUserRolePatch(
          updatedStudent: student,
          previousRole: previousRole,
          updatedEmail: updatedEmail,
        );

        final batch = _firestore.batch()
          ..set(docRef, {
            ...student.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          ..set(
            _usersCollection.doc(uid),
            linkedUserPatch,
            SetOptions(merge: true),
          );
        await batch.commit();
      } else {
        await docRef.set({
          ...student.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Last-Write-Wins (LWW) Cache Overwrite Protection
      final localStudent = await _localDatasource.getStudent(student.docID);
      if (localStudent != null) {
        final localTime = localStudent.clientUpdatedAt;
        final syncTime = student.clientUpdatedAt;
        if (localTime == null ||
            syncTime == null ||
            !localTime.isAfter(syncTime)) {
          final syncedStudent = student.copyWith(syncStatus: SyncStatus.synced);
          await _localDatasource.saveStudent(syncedStudent);
        }
      } else {
        final syncedStudent = student.copyWith(syncStatus: SyncStatus.synced);
        await _localDatasource.saveStudent(syncedStudent);
      }
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<void> syncOfflineCreateWithAuth(Map<String, dynamic> payload) async {
    final studentData = payload['student'] as Map<String, dynamic>;
    final student = StudentModel.fromMap(
      studentData,
      studentData['docID'] as String,
    );
    final email = payload['email'] as String;

    try {
      // 1. Create invitation
      final invitationId = email.trim().toLowerCase();
      await _firestore
          .collection(FirestoreCollections.invitations)
          .doc(invitationId)
          .set({
            'email': email.trim().toLowerCase(),
            'role': student.role.name,
            'name': student.name.trim(),
            'invitedAt': FieldValue.serverTimestamp(),
            'status': 'pending',
          });

      // 2. Set student doc in transaction to prevent duplicates
      await _firestore.runTransaction((transaction) async {
        final docRef = _studentsCollection.doc(student.docID);
        final existingDoc = await transaction.get(docRef);
        if (existingDoc.exists) {
          throw const StudentCreateFailure('المخدوم موجود مسبقاً.');
        }
        transaction.set(docRef, {
          ...student.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      // Last-Write-Wins (LWW) Cache Overwrite Protection
      final localStudent = await _localDatasource.getStudent(student.docID);
      if (localStudent != null) {
        final localTime = localStudent.clientUpdatedAt;
        final syncTime = student.clientUpdatedAt;
        if (localTime == null ||
            syncTime == null ||
            !localTime.isAfter(syncTime)) {
          final syncedStudent = student.copyWith(syncStatus: SyncStatus.synced);
          await _localDatasource.saveStudent(syncedStudent);
        }
      } else {
        final syncedStudent = student.copyWith(syncStatus: SyncStatus.synced);
        await _localDatasource.saveStudent(syncedStudent);
      }
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<void> syncOfflineArchive(Map<String, dynamic> payload) async {
    final docId = payload['docId'] as String;
    final performedByUid = payload['performedByUid'] as String;
    final payloadTimeStr = payload['clientUpdatedAt'] as String?;
    final payloadTime = payloadTimeStr != null
        ? DateTime.parse(payloadTimeStr)
        : null;

    final student = await getStudentById(docId, includeArchived: true);
    if (student == null) return;

    try {
      final doc = _studentsCollection.doc(docId);
      final batch = _firestore.batch()
        ..set(doc, {
          'isArchived': true,
          'archivedAt': FieldValue.serverTimestamp(),
          'archivedByUserId': performedByUid,
          'restoredAt': FieldValue.delete(),
          'restoredByUserId': FieldValue.delete(),
        }, SetOptions(merge: true));

      final normalizedUid = student.uid.trim();
      if (normalizedUid.isNotEmpty) {
        batch.set(_usersCollection.doc(normalizedUid), {
          'isArchived': true,
          'archivedAt': FieldValue.serverTimestamp(),
          'restorePendingPasswordReset': false,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();

      // Last-Write-Wins (LWW) Cache Overwrite Protection
      final localStudent = await _localDatasource.getStudent(docId);
      if (localStudent != null) {
        final localTime = localStudent.clientUpdatedAt;
        if (localTime == null ||
            payloadTime == null ||
            !localTime.isAfter(payloadTime)) {
          final syncedStudent = localStudent.copyWith(
            syncStatus: SyncStatus.synced,
          );
          await _localDatasource.saveStudent(syncedStudent);
        }
      }
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<void> syncOfflineRestore(Map<String, dynamic> payload) async {
    final docId = payload['docId'] as String;
    final performedByUid = payload['performedByUid'] as String;
    final payloadTimeStr = payload['clientUpdatedAt'] as String?;
    final payloadTime = payloadTimeStr != null
        ? DateTime.parse(payloadTimeStr)
        : null;

    final student = await getStudentById(docId, includeArchived: true);
    if (student == null) return;

    try {
      final doc = _studentsCollection.doc(docId);
      final batch = _firestore.batch()
        ..set(doc, {
          'isArchived': false,
          'restoredAt': FieldValue.serverTimestamp(),
          'restoredByUserId': performedByUid,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

      final normalizedUid = student.uid.trim();
      if (normalizedUid.isNotEmpty) {
        batch.set(_usersCollection.doc(normalizedUid), {
          'isArchived': false,
          'restoredAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();

      // Last-Write-Wins (LWW) Cache Overwrite Protection
      final localStudent = await _localDatasource.getStudent(docId);
      if (localStudent != null) {
        final localTime = localStudent.clientUpdatedAt;
        if (localTime == null ||
            payloadTime == null ||
            !localTime.isAfter(payloadTime)) {
          final syncedStudent = localStudent.copyWith(
            syncStatus: SyncStatus.synced,
          );
          await _localDatasource.saveStudent(syncedStudent);
        }
      }
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<void> syncBatchedStudents(List<SyncEntry> entries) async {
    if (entries.isEmpty) return;

    final List<void Function(WriteBatch)> ops = [];
    final List<StudentModel> studentsToLocalCache = [];
    final List<
      ({
        String docId,
        bool archive,
        String performedByUid,
        DateTime? clientTime,
      })
    >
    archiveRestoreCacheOps = [];

    for (final entry in entries) {
      if (entry.actionType == 'UPSERT_STUDENT' ||
          entry.actionType == 'UPDATE_STUDENT') {
        final studentData = entry.payload['student'] as Map<String, dynamic>;
        final student = StudentModel.fromMap(
          studentData,
          studentData['docID'] as String,
        );
        final docRef = _studentsCollection.doc(student.docID);
        final syncLinkedUser =
            entry.payload['syncLinkedUser'] as bool? ?? false;
        final uid = student.uid.trim();

        if (syncLinkedUser && uid.isNotEmpty) {
          final previousRoleName = entry.payload['previousRole'] as String;
          final previousRole = UserRole.values.byName(previousRoleName);
          final updatedEmail = entry.payload['updatedEmail'] as String?;
          final linkedUserPatch = _linkedUserSyncService
              .buildLinkedUserRolePatch(
                updatedStudent: student,
                previousRole: previousRole,
                updatedEmail: updatedEmail,
              );
          ops.add((batch) {
            batch
              ..set(docRef, {
                ...student.toMap(),
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true))
              ..set(
                _usersCollection.doc(uid),
                linkedUserPatch,
                SetOptions(merge: true),
              );
          });
        } else {
          ops.add((batch) {
            batch.set(docRef, {
              ...student.toMap(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          });
        }
        studentsToLocalCache.add(student);
      } else if (entry.actionType == 'CREATE_STUDENT_INVITATION' ||
          entry.actionType == 'CREATE_STUDENT_WITH_AUTH') {
        final studentData = entry.payload['student'] as Map<String, dynamic>;
        final student = StudentModel.fromMap(
          studentData,
          studentData['docID'] as String,
        );
        final email = entry.payload['email'] as String? ?? '';
        final docRef = _studentsCollection.doc(student.docID);

        if (email.trim().isNotEmpty) {
          final invitationId = email.trim().toLowerCase();
          ops.add((batch) {
            batch.set(
              _firestore
                  .collection(FirestoreCollections.invitations)
                  .doc(invitationId),
              {
                'email': email.trim().toLowerCase(),
                'role': student.role.name,
                'name': student.name.trim(),
                'invitedAt': FieldValue.serverTimestamp(),
                'status': 'pending',
              },
              SetOptions(merge: true),
            );
          });
        }

        ops.add((batch) {
          batch.set(docRef, {
            ...student.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        });
        studentsToLocalCache.add(student);
      } else if (entry.actionType == 'ARCHIVE_STUDENT') {
        final docId = entry.payload['docId'] as String;
        final performedByUid = entry.payload['performedByUid'] as String;
        final payloadTimeStr = entry.payload['clientUpdatedAt'] as String?;
        final payloadTime = payloadTimeStr != null
            ? DateTime.parse(payloadTimeStr)
            : null;
        final doc = _studentsCollection.doc(docId);

        ops.add((batch) {
          batch.set(doc, {
            'isArchived': true,
            'archivedAt': FieldValue.serverTimestamp(),
            'archivedByUserId': performedByUid,
            'restoredAt': FieldValue.delete(),
            'restoredByUserId': FieldValue.delete(),
          }, SetOptions(merge: true));
        });

        archiveRestoreCacheOps.add((
          docId: docId,
          archive: true,
          performedByUid: performedByUid,
          clientTime: payloadTime,
        ));
      } else if (entry.actionType == 'RESTORE_STUDENT') {
        final docId = entry.payload['docId'] as String;
        final performedByUid = entry.payload['performedByUid'] as String;
        final payloadTimeStr = entry.payload['clientUpdatedAt'] as String?;
        final payloadTime = payloadTimeStr != null
            ? DateTime.parse(payloadTimeStr)
            : null;
        final doc = _studentsCollection.doc(docId);

        ops.add((batch) {
          batch.set(doc, {
            'isArchived': false,
            'restoredAt': FieldValue.serverTimestamp(),
            'restoredByUserId': performedByUid,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        });

        archiveRestoreCacheOps.add((
          docId: docId,
          archive: false,
          performedByUid: performedByUid,
          clientTime: payloadTime,
        ));
      }
    }

    final studentFutures = archiveRestoreCacheOps.map(
      (op) => getStudentById(op.docId, includeArchived: true),
    );
    final fetchedStudents = await Future.wait(studentFutures);

    for (var i = 0; i < archiveRestoreCacheOps.length; i++) {
      final op = archiveRestoreCacheOps[i];
      final student = fetchedStudents[i];
      if (student == null) continue;

      final normalizedUid = student.uid.trim();
      if (normalizedUid.isNotEmpty) {
        if (op.archive) {
          ops.add((batch) {
            batch.set(_usersCollection.doc(normalizedUid), {
              'isArchived': true,
              'archivedAt': FieldValue.serverTimestamp(),
              'restorePendingPasswordReset': false,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          });
        } else {
          ops.add((batch) {
            batch.set(_usersCollection.doc(normalizedUid), {
              'isArchived': false,
              'restoredAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          });
        }
      }
    }

    try {
      await chunkedBatch(firestore: _firestore, ops: ops);

      if (studentsToLocalCache.isNotEmpty) {
        final docIds = studentsToLocalCache.map((s) => s.docID).toList();
        final localStudents = await _localDatasource.getStudentsByIds(
          docIds,
          includeArchived: true,
        );
        final localMap = {for (final s in localStudents) s.docID: s};
        final toSave = <StudentModel>[];

        for (final student in studentsToLocalCache) {
          final localStudent = localMap[student.docID];
          if (localStudent != null) {
            final localTime = localStudent.clientUpdatedAt;
            final syncTime = student.clientUpdatedAt;
            if (localTime == null ||
                syncTime == null ||
                !localTime.isAfter(syncTime)) {
              toSave.add(student.copyWith(syncStatus: SyncStatus.synced));
            }
          } else {
            toSave.add(student.copyWith(syncStatus: SyncStatus.synced));
          }
        }
        if (toSave.isNotEmpty) {
          await _localDatasource.saveStudents(toSave);
        }
      }

      if (archiveRestoreCacheOps.isNotEmpty) {
        final docIds = archiveRestoreCacheOps.map((op) => op.docId).toList();
        final localStudents = await _localDatasource.getStudentsByIds(
          docIds,
          includeArchived: true,
        );
        final localMap = {for (final s in localStudents) s.docID: s};
        final toSave = <StudentModel>[];

        for (final op in archiveRestoreCacheOps) {
          final localStudent = localMap[op.docId];
          if (localStudent != null) {
            final localTime = localStudent.clientUpdatedAt;
            if (localTime == null ||
                op.clientTime == null ||
                !localTime.isAfter(op.clientTime!)) {
              toSave.add(
                localStudent.copyWith(
                  isArchived: op.archive,
                  syncStatus: SyncStatus.synced,
                ),
              );
            }
          }
        }
        if (toSave.isNotEmpty) {
          await _localDatasource.saveStudents(toSave);
        }
      }
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }
}
