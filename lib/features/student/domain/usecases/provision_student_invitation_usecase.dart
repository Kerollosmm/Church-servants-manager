import 'package:church_management_system/features/student/domain/entities/student.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';

/// Orchestrates the creation of a student with an optional invitation.
class ProvisionStudentInvitationUseCase {
  const ProvisionStudentInvitationUseCase({
    required IStudentRepository studentRepository,
  }) : _studentRepository = studentRepository;

  final IStudentRepository _studentRepository;

  /// Creates the student, optionally sending an invitation.
  /// Returns the created student's document ID.
  Future<String> call({required Student student, String? email}) async {
    try {
      return await _studentRepository.createStudent(student, email: email);
    } catch (e) {
      rethrow;
    }
  }

  /// Archives a student.
  Future<void> archive({
    required String docId,
    required String performedByUid,
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

  /// Restores a student.
  Future<void> restore({
    required String docId,
    required String performedByUid,
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
