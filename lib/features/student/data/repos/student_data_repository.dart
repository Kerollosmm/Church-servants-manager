import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/core/utils/pagination_cursor.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/services/student_linked_user_sync_service.dart';
import 'package:church_management_system/features/student/data/services/student_query_service.dart';
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

  StudentDataRepository({
    required FirebaseFirestore firestore,
    StudentQueryService? queryService,
    StudentLinkedUserSyncService? linkedUserSyncService,
  }) : _firestore = firestore,
       _queryService =
           queryService ?? StudentQueryService(firestore: firestore),
       _linkedUserSyncService =
           linkedUserSyncService ??
           StudentLinkedUserSyncService(firestore: firestore);

  CollectionReference<Map<String, dynamic>> get _studentsCollection =>
      _firestore.collection(FirestoreCollections.students);
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestoreCollections.users);

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
    final lastDoc = cursor?.token as DocumentSnapshot?;
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
  }) async {
    if (query.isEmpty) return getAllStudents(limit: limit);
    final snapshot = await _studentsCollection
        .orderBy('name')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(limit * 2)
        .get();
    return _queryService
        .mapStudentDocs(snapshot.docs)
        .where((s) => !s.isArchived)
        .take(limit)
        .toList();
  }

  @override
  Future<String> createStudent(StudentModel student) async {
    try {
      final docRef = student.docID.isNotEmpty
          ? _studentsCollection.doc(student.docID)
          : _studentsCollection.doc();
      final finalStudent = student.copyWith(docID: docRef.id);
      await docRef.set(finalStudent.toMap());
      return docRef.id;
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<void> updateStudent(StudentModel student) async {
    try {
      final docRef = _studentsCollection.doc(student.docID);
      await docRef.update(student.toMap());
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  @override
  Future<void> upsertStudent(StudentModel student) async {
    try {
      final docRef = _studentsCollection.doc(student.docID);
      await docRef.set(student.toMap(), SetOptions(merge: true));
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
      final doc = await _studentsCollection.doc(docId).get();
      final data = doc.data();
      if (!doc.exists || data == null) {
        return;
      }

      final student = StudentModel.fromMap(data, doc.id);
      final batch = _firestore.batch();

      batch.set(doc.reference, {
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
  Future<void> restoreStudent(
    String docId, {
    required String performedByUid,
  }) async {
    try {
      final doc = await _studentsCollection.doc(docId).get();
      final data = doc.data();
      if (!doc.exists || data == null) {
        return;
      }

      final student = StudentModel.fromMap(data, doc.id);
      final batch = _firestore.batch();

      batch.set(doc.reference, {
        'isArchived': false,
        'restoredAt': FieldValue.serverTimestamp(),
        'restoredByUserId': performedByUid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final normalizedUid = student.uid.trim();
      if (normalizedUid.isNotEmpty) {
        batch.set(_usersCollection.doc(normalizedUid), {
          'isArchived': false,
          'restorePendingPasswordReset': true,
          'restoredAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  /// Helper to get student IDs for given class IDs (batch query)
  @override
  Future<List<String>> getStudentIdsByClasses(List<String> classIds) async {
    return _queryService.getStudentIdsByClasses(classIds);
  }

  // Stream-based queries (real-time)

  @override
  Stream<List<StudentModel>> watchAllStudents({bool includeArchived = false}) {
    return _queryService.watchAllStudents(includeArchived: includeArchived);
  }

  @override
  Stream<List<StudentModel>> watchStudentsByClass(
    String classId, {
    bool includeArchived = false,
  }) {
    return _queryService.watchStudentsByClass(
      classId,
      includeArchived: includeArchived,
    );
  }

  @override
  Stream<List<StudentModel>> watchStudentsByClasses(
    List<String> classIds, {
    bool includeArchived = false,
  }) {
    return _queryService.watchStudentsByClasses(
      classIds,
      includeArchived: includeArchived,
    );
  }

  @override
  Stream<List<StudentModel>> watchStudentsByGroup(
    String groupName, {
    bool includeArchived = false,
  }) {
    return _queryService.watchStudentsByGroup(
      groupName,
      includeArchived: includeArchived,
    );
  }
}
