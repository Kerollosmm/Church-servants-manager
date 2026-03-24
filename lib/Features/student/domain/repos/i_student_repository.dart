import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Interface for Student Repository.
/// Defines the contract for interacting with student data.
abstract class IStudentRepository {
  /// Get a single student by document ID
  Future<StudentModel?> getStudentById(
    String docId, {
    bool includeArchived = false,
  });

  /// Get a student by Firebase Auth UID (or app UID).
  Future<StudentModel?> getStudentByUid(
    String uid, {
    bool includeArchived = false,
  });

  /// Get all students with pagination support.
  Future<List<StudentModel>> getAllStudents({
    int limit = 10,
    DocumentSnapshot? lastDocument,
    bool includeArchived = false,
  });

  /// Get students by class ID.
  Future<List<StudentModel>> getStudentsByClass(
    String classId, {
    bool includeArchived = false,
  });

  /// Get students by grade.
  Future<List<StudentModel>> getStudentsByGrade(int grade);

  /// Get students by group (Server-side filtering).
  Future<List<StudentModel>> getStudentsByGroup(
    String groupName, {
    bool includeArchived = false,
  });

  /// Search students by name.
  Future<List<StudentModel>> searchStudents(String query, {int limit = 20});

  /// Create a new student.
  /// Throws [StudentFailure] on error.
  Future<String> createStudent(StudentModel student);

  /// Update an existing student.
  /// Throws [StudentFailure] on error.
  Future<void> updateStudent(StudentModel student);

  /// Archive a student by document ID.
  /// Throws [StudentFailure] on error.
  // FIX [004-C2]: added performedByUid so the actor's identity is recorded.
  Future<void> deleteStudent(String docId, {required String performedByUid});

  /// Restore an archived student by document ID.
  /// Throws [StudentFailure] on error.
  // FIX [004-C2]: added performedByUid so the actor's identity is recorded.
  Future<void> restoreStudent(String docId, {required String performedByUid});

  /// Upsert a student (create or update).
  Future<void> upsertStudent(StudentModel student);

  //Stream-based queries (for-real-time-update)

  /// Watch all students ordered by name.
  Stream<List<StudentModel>> watchAllStudents({bool includeArchived = false});

  /// Watch students by class ID (real-time).
  Stream<List<StudentModel>> watchStudentsByClass(
    String classId, {
    bool includeArchived = false,
  });

  /// Watch students by multiple class IDs (real-time).
  Stream<List<StudentModel>> watchStudentsByClasses(
    List<String> classIds, {
    bool includeArchived = false,
  });

  /// Watch students by group name (real-time).
  Stream<List<StudentModel>> watchStudentsByGroup(
    String groupName, {
    bool includeArchived = false,
  });
}
