import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/sync_service.dart'
    hide SyncStatus;
import 'package:church_management_system/core/utils/pagination_cursor.dart';
import 'package:church_management_system/features/student/data/datasources/student_local_datasource.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/services/student_linked_user_sync_service.dart';
import 'package:church_management_system/features/student/data/services/student_query_service.dart';
import 'package:church_management_system/features/student/domain/failures/student_failures.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Repository for student data operations.
///
/// Delegates to [StudentQueryService] for queries and
/// [StudentLinkedUserSyncService] for auth user sync.
class StudentDataRepository implements IStudentRepository {
  final FirebaseFirestore _firestore;
  final StudentQueryService _queryService;
  final StudentLinkedUserSyncService _linkedUserSyncService;
  final StudentLocalDatasource _localDatasource;
  final SyncService _syncService;
  final Connectivity _connectivity;

  StudentDataRepository({
    required FirebaseFirestore firestore,
    StudentQueryService? queryService,
    StudentLinkedUserSyncService? linkedUserSyncService,
    StudentLocalDatasource? localDatasource,
    required SyncService syncService,
    Connectivity? connectivity,
  }) : _firestore = firestore,
       _queryService =
           queryService ?? StudentQueryService(firestore: firestore),
       _linkedUserSyncService =
           linkedUserSyncService ??
           StudentLinkedUserSyncService(firestore: firestore),
       _localDatasource = localDatasource ?? StudentLocalDatasource(),
       _syncService = syncService,
       _connectivity = connectivity ?? Connectivity();

  CollectionReference<Map<String, dynamic>> get _studentsCollection =>
      _firestore.collection(FirestoreCollections.students);
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestoreCollections.servants);

  @override
  Future<void> syncLinkedUserRoleFromStudent({
    required StudentModel updatedStudent,
    required UserRole previousRole,
    String? updatedEmail,
  }) async {
    return _linkedUserSyncService.syncLinkedUserRoleFromStudent(
      updatedStudent: updatedStudent,
      previousRole: previousRole,
      updatedEmail: updatedEmail,
    );
  }

  @override
  Future<void> updateStudentAndSyncLinkedUserRole({
    required StudentModel updatedStudent,
    required UserRole previousRole,
    String? updatedEmail,
  }) async {
    return _linkedUserSyncService.updateStudentAndSyncLinkedUserRole(
      updatedStudent: updatedStudent,
      previousRole: previousRole,
      updatedEmail: updatedEmail,
    );
  }

  @override
  Future<StudentModel?> getStudentById(
    String docId, {
    bool includeArchived = false,
  }) async {
    return _queryService.getStudentById(
      docId,
      includeArchived: includeArchived,
    );
  }

  @override
  Future<StudentModel?> getStudentByUid(
    String uid, {
    bool includeArchived = false,
  }) async {
    return _queryService.getStudentByUid(uid, includeArchived: includeArchived);
  }

  @override
  Future<List<StudentModel>> getAllStudents({
    int limit = 10,
    PaginationCursor? cursor,
    bool includeArchived = false,
  }) async {
    final token = cursor?.token;
    final lastDoc = token is DocumentSnapshot ? token : null;
    return _queryService.getAllStudents(
      limit: limit,
      lastDocument: lastDoc,
      includeArchived: includeArchived,
    );
  }

  @override
  Future<List<StudentModel>> getStudentsByClass(
    String classId, {
    bool includeArchived = false,
  }) async {
    return _queryService.getStudentsByClass(
      classId,
      includeArchived: includeArchived,
    );
  }

  @override
  Future<List<StudentModel>> getStudentsByClasses(
    List<String> classIds, {
    bool includeArchived = false,
  }) async {
    return _queryService.getStudentsByClasses(
      classIds,
      includeArchived: includeArchived,
    );
  }

  @override
  Future<List<StudentModel>> getStudentsByGrade(
    int grade, {
    bool includeArchived = false,
  }) async {
    return _queryService.getStudentsByGrade(
      grade,
      includeArchived: includeArchived,
    );
  }

  @override
  Future<List<StudentModel>> getStudentsByGroup(
    String groupName, {
    bool includeArchived = false,
  }) async {
    return _queryService.getStudentsByGroup(
      groupName,
      includeArchived: includeArchived,
    );
  }

  @override
  Future<({List<StudentModel> students, bool isFromCache})>
  getStudentsByGroupWithFallback(
    String groupName, {
    bool includeArchived = false,
  }) async {
    return _queryService.getStudentsByGroupWithFallback(
      groupName,
      includeArchived: includeArchived,
    );
  }

  @override
  Future<List<StudentModel>> searchStudents(
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

      return _queryService
          .mapStudentDocs(snapshot.docs)
          .students
          .take(limit)
          .toList();
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<String> createStudent(StudentModel student) async {
    try {
      final docRef = student.docID.isNotEmpty
          ? _studentsCollection.doc(student.docID)
          : _studentsCollection.doc();
      final finalStudent = student.copyWith(
        docID: docRef.id,
        syncStatus: SyncStatus.pending,
      );

      await _localDatasource.saveStudent(finalStudent);
      await _localDatasource.queueForSync(finalStudent);

      try {
        final batch = _firestore.batch()
          ..set(docRef, {
            ...finalStudent.toMap(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        await batch.commit();

        final syncedStudent = finalStudent.copyWith(
          syncStatus: SyncStatus.synced,
        );
        await _localDatasource.saveStudent(syncedStudent);
        await _localDatasource.removeFromSyncQueue(docRef.id);
      } catch (networkError) {
        // Retain pending status locally.
        // We don't throw a fatal error that crashes the UI.
      }

      return docRef.id;
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<void> updateStudent(StudentModel student) async {
    try {
      final pendingStudent = student.copyWith(syncStatus: SyncStatus.pending);
      await _localDatasource.saveStudent(pendingStudent);
      await _localDatasource.queueForSync(pendingStudent);

      try {
        final docRef = _studentsCollection.doc(student.docID);
        await docRef.update({
          ...student.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        final syncedStudent = pendingStudent.copyWith(
          syncStatus: SyncStatus.synced,
        );
        await _localDatasource.saveStudent(syncedStudent);
        await _localDatasource.removeFromSyncQueue(student.docID);
      } catch (networkError) {
        // Retain pending status locally on network failure.
      }
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<void> upsertStudent(StudentModel student) async {
    try {
      final pendingStudent = student.copyWith(syncStatus: SyncStatus.pending);
      await _localDatasource.saveStudent(pendingStudent);

      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        await _syncService.enqueue(
          SyncEntry(
            id: 'upsert_student_${student.docID}_${DateTime.now().millisecondsSinceEpoch}',
            actionType: 'UPSERT_STUDENT',
            payload: {'student': student.toMap()},
            createdAt: DateTime.now(),
          ),
        );
        return;
      }

      try {
        final docRef = _studentsCollection.doc(student.docID);
        await docRef.set({
          ...student.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final syncedStudent = pendingStudent.copyWith(
          syncStatus: SyncStatus.synced,
        );
        await _localDatasource.saveStudent(syncedStudent);
      } catch (networkError) {
        await _syncService.enqueue(
          SyncEntry(
            id: 'upsert_student_${student.docID}_${DateTime.now().millisecondsSinceEpoch}',
            actionType: 'UPSERT_STUDENT',
            payload: {'student': student.toMap()},
            createdAt: DateTime.now(),
          ),
        );
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

      // Update local cache
      final archivedStudent = student.copyWith(isArchived: true);
      await _localDatasource.saveStudent(archivedStudent);

      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        await _syncService.enqueue(
          SyncEntry(
            id: 'archive_student_${docId}_${DateTime.now().millisecondsSinceEpoch}',
            actionType: 'ARCHIVE_STUDENT',
            payload: {'docId': docId, 'performedByUid': performedByUid},
            createdAt: DateTime.now(),
          ),
        );
        return;
      }

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
      } catch (networkError) {
        await _syncService.enqueue(
          SyncEntry(
            id: 'archive_student_${docId}_${DateTime.now().millisecondsSinceEpoch}',
            actionType: 'ARCHIVE_STUDENT',
            payload: {'docId': docId, 'performedByUid': performedByUid},
            createdAt: DateTime.now(),
          ),
        );
      }
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

      // Update local cache
      final restoredStudent = student.copyWith(isArchived: false);
      await _localDatasource.saveStudent(restoredStudent);

      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        await _syncService.enqueue(
          SyncEntry(
            id: 'restore_student_${docId}_${DateTime.now().millisecondsSinceEpoch}',
            actionType: 'RESTORE_STUDENT',
            payload: {'docId': docId, 'performedByUid': performedByUid},
            createdAt: DateTime.now(),
          ),
        );
        return;
      }

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
      } catch (networkError) {
        await _syncService.enqueue(
          SyncEntry(
            id: 'restore_student_${docId}_${DateTime.now().millisecondsSinceEpoch}',
            actionType: 'RESTORE_STUDENT',
            payload: {'docId': docId, 'performedByUid': performedByUid},
            createdAt: DateTime.now(),
          ),
        );
      }
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
    final studentData = payload['student'] as Map<String, dynamic>;
    final student = StudentModel.fromMap(
      studentData,
      studentData['docID'] as String,
    );
    await updateStudent(student);
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
      await docRef.set({
        ...student.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final syncedStudent = student.copyWith(syncStatus: SyncStatus.synced);
      await _localDatasource.saveStudent(syncedStudent);
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<void> syncOfflineArchive(Map<String, dynamic> payload) async {
    final docId = payload['docId'] as String;
    final performedByUid = payload['performedByUid'] as String;

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
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<void> syncOfflineRestore(Map<String, dynamic> payload) async {
    final docId = payload['docId'] as String;
    final performedByUid = payload['performedByUid'] as String;

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
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }
}
