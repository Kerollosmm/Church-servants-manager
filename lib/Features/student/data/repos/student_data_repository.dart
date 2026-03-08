import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/student/data/services/student_linked_user_sync_service.dart';
import 'package:church_management_system/features/student/data/services/student_query_service.dart';
import 'package:church_management_system/features/student/domain/failures/student_failures.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import '../models/student_model.dart';

class StudentDataRepository implements IStudentRepository {
  final FirebaseFirestore _firestore;
  final StudentQueryService _queryService;
  final StudentLinkedUserSyncService _linkedUserSyncService;

  StudentDataRepository({
    FirebaseFirestore? firestore,
    StudentQueryService? queryService,
    StudentLinkedUserSyncService? linkedUserSyncService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _queryService =
           queryService ?? StudentQueryService(firestore: firestore),
       _linkedUserSyncService =
           linkedUserSyncService ??
           StudentLinkedUserSyncService(firestore: firestore);

  CollectionReference<Map<String, dynamic>> get _studentsCollection =>
      _firestore.collection(FirestoreCollections.students);

  Future<void> syncLinkedUserRoleFromStudent({
    required StudentModel updatedStudent,
    required UserRole previousRole,
  }) async {
    return _linkedUserSyncService.syncLinkedUserRoleFromStudent(
      updatedStudent: updatedStudent,
      previousRole: previousRole,
    );
  }

  Future<void> updateStudentAndSyncLinkedUserRole({
    required StudentModel updatedStudent,
    required UserRole previousRole,
  }) async {
    return _linkedUserSyncService.updateStudentAndSyncLinkedUserRole(
      updatedStudent: updatedStudent,
      previousRole: previousRole,
    );
  }

  @override
  Future<StudentModel?> getStudentById(String docId) async {
    return _queryService.getStudentById(docId);
  }

  @override
  Future<StudentModel?> getStudentByUid(String uid) async {
    return _queryService.getStudentByUid(uid);
  }

  @override
  Future<List<StudentModel>> getAllStudents({
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    return _queryService.getAllStudents(
      limit: limit,
      lastDocument: lastDocument,
    );
  }

  @override
  Future<List<StudentModel>> getStudentsByClass(String classId) async {
    return _queryService.getStudentsByClass(classId);
  }

  @override
  Future<List<StudentModel>> getStudentsByGrade(int grade) async {
    return _queryService.getStudentsByGrade(grade);
  }

  @override
  Future<List<StudentModel>> getStudentsByGroup(String groupName) async {
    return _queryService.getStudentsByGroup(groupName);
  }

  Future<({List<StudentModel> students, bool isFromCache})>
  getStudentsByGroupWithFallback(String groupName) async {
    return _queryService.getStudentsByGroupWithFallback(groupName);
  }

  @override
  Future<List<StudentModel>> searchStudents(
    String query, {
    int limit = 20,
  }) async {
    // In-memory, case-insensitive search is handled by StudentDataBloc.
    // This repo method now simply fetches all students for the BLoC to filter.
    return getAllStudents(limit: limit);
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
  Future<void> deleteStudent(String docId) async {
    try {
      // Note: We are not deleting the associated User record here automatically
      // as that might delete a valid user account. We just delete the student profile.
      await _studentsCollection.doc(docId).delete();
    } catch (e) {
      throw mapExceptionToStudentFailure(e);
    }
  }

  /// Helper to get student IDs for given class IDs (batch query)
  Future<List<String>> getStudentIdsByClasses(List<String> classIds) async {
    return _queryService.getStudentIdsByClasses(classIds);
  }

  // Stream-based queries (real-time)

  @override
  Stream<List<StudentModel>> watchAllStudents() {
    return _queryService.watchAllStudents();
  }

  @override
  Stream<List<StudentModel>> watchStudentsByClass(String classId) {
    return _queryService.watchStudentsByClass(classId);
  }

  @override
  Stream<List<StudentModel>> watchStudentsByClasses(List<String> classIds) {
    return _queryService.watchStudentsByClasses(classIds);
  }

  @override
  Stream<List<StudentModel>> watchStudentsByGroup(String groupName) {
    return _queryService.watchStudentsByGroup(groupName);
  }
}
