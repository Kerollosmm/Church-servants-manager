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
import 'package:church_management_system/features/student/domain/entities/student.dart';
import 'package:church_management_system/features/student/domain/failures/student_failures.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    return _linkedUserSyncService.updateStudentAndSyncLinkedUserRole(
      updatedStudent: StudentModel.fromDomain(updatedStudent),
      previousRole: previousRole,
      updatedEmail: updatedEmail,
    );
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
  Future<String> createStudent(Student student) async {
    try {
      final docRef = student.docID.isNotEmpty
          ? _studentsCollection.doc(student.docID)
          : _studentsCollection.doc();
      final finalStudent = StudentModel.fromDomain(
        student,
      ).copyWith(docID: docRef.id, syncStatus: SyncStatus.pending);

      await _localDatasource.saveStudent(finalStudent);
      await _syncServiceGetter().enqueue(
        SyncEntry(
          id: 'upsert_student_${docRef.id}',
          actionType: 'UPSERT_STUDENT',
          payload: {'student': finalStudent.toMap()},
          createdAt: DateTime.now(),
        ),
      );

      return docRef.id;
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<void> updateStudent(Student student) async {
    try {
      final pendingStudent = StudentModel.fromDomain(
        student,
      ).copyWith(syncStatus: SyncStatus.pending);
      await _localDatasource.saveStudent(pendingStudent);

      await _syncServiceGetter().enqueue(
        SyncEntry(
          id: 'upsert_student_${student.docID}',
          actionType: 'UPSERT_STUDENT',
          payload: {'student': pendingStudent.toMap()},
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<void> upsertStudent(Student student) async {
    try {
      final pendingStudent = StudentModel.fromDomain(
        student,
      ).copyWith(syncStatus: SyncStatus.pending);
      await _localDatasource.saveStudent(pendingStudent);

      await _syncServiceGetter().enqueue(
        SyncEntry(
          id: 'upsert_student_${student.docID}',
          actionType: 'UPSERT_STUDENT',
          payload: {'student': pendingStudent.toMap()},
          createdAt: DateTime.now(),
        ),
      );
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
      final archivedStudent = StudentModel.fromDomain(
        student,
      ).copyWith(isArchived: true);
      await _localDatasource.saveStudent(archivedStudent);

      await _syncServiceGetter().enqueue(
        SyncEntry(
          id: 'archive_student_${docId}_${DateTime.now().millisecondsSinceEpoch}',
          actionType: 'ARCHIVE_STUDENT',
          payload: {'docId': docId, 'performedByUid': performedByUid},
          createdAt: DateTime.now(),
        ),
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

      // Update local cache
      final restoredStudent = StudentModel.fromDomain(
        student,
      ).copyWith(isArchived: false);
      await _localDatasource.saveStudent(restoredStudent);

      await _syncServiceGetter().enqueue(
        SyncEntry(
          id: 'restore_student_${docId}_${DateTime.now().millisecondsSinceEpoch}',
          actionType: 'RESTORE_STUDENT',
          payload: {'docId': docId, 'performedByUid': performedByUid},
          createdAt: DateTime.now(),
        ),
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
    final studentData = payload['student'] as Map<String, dynamic>;
    final student = StudentModel.fromMap(
      studentData,
      studentData['docID'] as String,
    );
    await updateStudent(student.toDomain());
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
