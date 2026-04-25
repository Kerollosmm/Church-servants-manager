import 'dart:developer' as developer;
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';

/// Orchestrates the two-phase commit for creating a student with an optional
/// linked Firebase Auth account. Handles rollback automatically.
class ProvisionStudentWithAuthUseCase {
  const ProvisionStudentWithAuthUseCase({
    required IStudentRepository studentRepository,
    required AdminUserProvisioningService provisioningService,
  }) : _studentRepository = studentRepository,
       _provisioningService = provisioningService;

  final IStudentRepository _studentRepository;
  final AdminUserProvisioningService _provisioningService;

  bool _hasCredentials(String? email, String? password) {
    return email != null &&
        email.isNotEmpty &&
        password != null &&
        password.isNotEmpty;
  }

  /// Creates the student, optionally creating a linked Auth account first.
  /// Returns the created student's document ID.
  Future<String> call({
    required StudentModel student,
    String? email,
    String? password,
  }) async {
    AuthUser? createdAuthUser;
    try {
      if (_hasCredentials(email, password)) {
        createdAuthUser = await _provisioningService.createUser(
          email: email!,
          password: password!,
          name: student.name,
          role: student.role,
        );
      }

      final studentToCreate = createdAuthUser == null
          ? student
          : student.copyWith(
              uid: createdAuthUser.uid,
              docID: createdAuthUser.uid,
            );

      return await _studentRepository.createStudent(studentToCreate);
    } catch (e) {
      // Rollback: if student create failed but auth user was already created
      if (createdAuthUser != null) {
        try {
          await _provisioningService.rollbackCreatedUser(
            uid: createdAuthUser.uid,
            email: email!,
            password: password!,
          );
        } catch (rollbackError) {
          developer.log(
            'CRITICAL: Auth user created but Firestore create failed, '
            'AND rollback also failed. UID: ${createdAuthUser.uid}',
            error: rollbackError,
            name: 'ProvisionStudentWithAuthUseCase',
          );
          // Rethrow rollback failure so BLoC shows critical error
          rethrow;
        }
      }
      rethrow;
    }
  }

  /// Archives a student and optionally archives the linked Auth account.
  Future<void> archive({
    required String docId,
    required String performedByUid,
    String? linkedUid,
  }) async {
    await _studentRepository.archiveStudent(
      docId,
      performedByUid: performedByUid,
    );

    if (linkedUid == null || linkedUid.trim().isEmpty) return;

    try {
      await _provisioningService.archiveUser(uid: linkedUid.trim());
    } catch (authError) {
      // Rollback Firestore archive
      try {
        await _studentRepository.restoreStudent(
          docId,
          performedByUid: performedByUid,
        );
      } catch (rollbackError) {
        developer.log(
          'CRITICAL: Archive failed AND rollback failed. DocId: $docId, UID: $linkedUid',
          error: rollbackError,
          name: 'ProvisionStudentWithAuthUseCase',
        );
        rethrow;
      }
      rethrow;
    }
  }

  /// Restores a student and optionally restores the linked Auth account.
  Future<void> restore({
    required String docId,
    required String performedByUid,
    String? linkedUid,
  }) async {
    await _studentRepository.restoreStudent(
      docId,
      performedByUid: performedByUid,
    );

    if (linkedUid == null || linkedUid.trim().isEmpty) return;

    try {
      await _provisioningService.restoreUser(uid: linkedUid.trim());
    } catch (authError) {
      // Rollback Firestore restore
      try {
        await _studentRepository.archiveStudent(
          docId,
          performedByUid: performedByUid,
        );
      } catch (rollbackError) {
        developer.log(
          'CRITICAL: Restore failed AND rollback failed. DocId: $docId, UID: $linkedUid',
          error: rollbackError,
          name: 'ProvisionStudentWithAuthUseCase',
        );
        rethrow;
      }
      rethrow;
    }
  }
}
