import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/utils/pagination_cursor.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';

/// Domain interface for student repository.
/// Enables dependency inversion: presentation and domain layers
/// depend on this abstraction, not concrete Firebase implementations.
abstract class IStudentRepository {
  Future<StudentModel?> getStudentById(String docId, {bool includeArchived});

  Future<StudentModel?> getStudentByUid(String uid, {bool includeArchived});

  Future<List<StudentModel>> getAllStudents({
    int limit,
    PaginationCursor? cursor,
    bool includeArchived,
  });

  Future<List<StudentModel>> getStudentsByClass(
    String classId, {
    bool includeArchived,
  });

  Future<List<StudentModel>> getStudentsByGrade(
    int grade, {
    bool includeArchived,
  });

  Future<List<StudentModel>> getStudentsByGroup(
    String groupName, {
    bool includeArchived,
  });

  Future<({List<StudentModel> students, bool isFromCache})>
  getStudentsByGroupWithFallback(String groupName, {bool includeArchived});

  Future<List<StudentModel>> searchStudents(
    String query, {
    int limit,
    String? groupId,
    String? classId,
    bool includeArchived,
  });

  Future<String> createStudent(StudentModel student);

  Future<void> updateStudent(StudentModel student);

  Future<void> upsertStudent(StudentModel student);

  Future<void> archiveStudent(String docId, {required String performedByUid});

  Future<void> restoreStudent(String docId, {required String performedByUid});

  Future<List<String>> getStudentIdsByClasses(List<String> classIds);

  Future<List<StudentModel>> getStudentsByClasses(
    List<String> classIds, {
    bool includeArchived,
  });

  Future<void> syncLinkedUserRoleFromStudent({
    required StudentModel updatedStudent,
    required UserRole previousRole,
    String? updatedEmail,
  });

  Future<void> updateStudentAndSyncLinkedUserRole({
    required StudentModel updatedStudent,
    required UserRole previousRole,
    String? updatedEmail,
  });

  Future<void> syncOfflineUpdate(Map<String, dynamic> payload);
  Future<void> syncOfflineUpsert(Map<String, dynamic> payload);
  Future<void> syncOfflineArchive(Map<String, dynamic> payload);
  Future<void> syncOfflineRestore(Map<String, dynamic> payload);
}
