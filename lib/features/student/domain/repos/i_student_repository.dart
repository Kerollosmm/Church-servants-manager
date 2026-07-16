import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/utils/pagination_cursor.dart';
import 'package:church_management_system/features/student/domain/entities/student.dart';

/// Domain interface for student repository.
/// Enables dependency inversion: presentation and domain layers
/// depend on this abstraction, not concrete Firebase implementations.
abstract class IStudentRepository {
  Future<Student?> getStudentById(String docId, {bool includeArchived});

  Future<Student?> getStudentByUid(String uid, {bool includeArchived});

  Future<List<Student>> getAllStudents({
    int limit,
    PaginationCursor? cursor,
    bool includeArchived,
  });

  Future<List<Student>> getStudentsByClass(
    String classId, {
    bool includeArchived,
  });

  Future<List<Student>> getStudentsByGrade(int grade, {bool includeArchived});

  Future<List<Student>> getStudentsByGroup(
    String groupName, {
    bool includeArchived,
  });

  Future<({List<Student> students, bool isFromCache})>
  getStudentsByGroupWithFallback(String groupName, {bool includeArchived});

  Future<List<Student>> searchStudents(
    String query, {
    int limit,
    String? groupId,
    String? classId,
    bool includeArchived,
  });

  Future<String> createStudent(Student student, {String? email});

  Future<void> updateStudent(Student student);

  Future<void> upsertStudent(Student student);

  Future<void> archiveStudent(String docId, {required String performedByUid});

  Future<void> restoreStudent(String docId, {required String performedByUid});

  Future<List<String>> getStudentIdsByClasses(List<String> classIds);

  Future<List<Student>> getStudentsByClasses(
    List<String> classIds, {
    bool includeArchived,
  });

  Future<void> syncLinkedUserRoleFromStudent({
    required Student updatedStudent,
    required UserRole previousRole,
    String? updatedEmail,
  });

  Future<void> updateStudentAndSyncLinkedUserRole({
    required Student updatedStudent,
    required UserRole previousRole,
    String? updatedEmail,
  });

  Future<void> syncOfflineUpdate(Map<String, dynamic> payload);
  Future<void> syncOfflineUpsert(Map<String, dynamic> payload);
  Future<void> syncOfflineArchive(Map<String, dynamic> payload);
  Future<void> syncOfflineRestore(Map<String, dynamic> payload);
  Future<void> syncOfflineCreateWithAuth(Map<String, dynamic> payload);
  Future<void> syncBatchedStudents(List<SyncEntry> entries);
}
