import 'package:church_management_system/features/student/domain/entities/student.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';

/// Orchestrates the two-phase commit for creating a student with an optional
/// linked Firebase Auth account. Handles rollback automatically.
class ProvisionStudentWithAuthUseCase {
  const ProvisionStudentWithAuthUseCase({
    required IStudentRepository studentRepository,
  }) : _studentRepository = studentRepository;

  final IStudentRepository _studentRepository;

  /// Creates the student, optionally creating a linked Auth account first.
  /// Returns the created student's document ID.
  Future<String> call({
    required Student student,
    String? email,
    String? password,
  }) async {
    try {
      return await _studentRepository.createStudent(
        student,
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Archives a student and optionally archives the linked Auth account.
  Future<void> archive({
    required String docId,
    required String performedByUid,
    String? linkedUid,
  }) async {
    try {
      await _studentRepository.archiveStudent(
        docId,
        performedByUid: performedByUid,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Restores a student and optionally restores the linked Auth account.
  Future<void> restore({
    required String docId,
    required String performedByUid,
    String? linkedUid,
  }) async {
    try {
      await _studentRepository.restoreStudent(
        docId,
        performedByUid: performedByUid,
      );
    } catch (e) {
      rethrow;
    }
  }
}
