import 'package:church_management_system/core/security/permission_matrix.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';

/// Checks whether the given [actor] has permission to
/// create, update, or delete the given [student].
///
/// This use case derives its logic from the canonical [PermissionMatrix]
/// to ensure consistency between app-level checks and Firestore security rules.
class CanMutateStudentUseCase {
  const CanMutateStudentUseCase();

  /// Checks if [actor] can CREATE the [student].
  bool canCreate(AuthUser actor, StudentModel student) {
    return PermissionMatrix.canCreateStudent(actor, student);
  }

  /// Checks if [actor] can UPDATE [existing] to [updated].
  bool canUpdate(AuthUser actor, StudentModel existing, StudentModel updated) {
    return PermissionMatrix.canUpdateStudent(actor, existing, updated);
  }

  /// Checks if [actor] can DELETE the [student].
  bool canDelete(AuthUser actor, StudentModel student) {
    return PermissionMatrix.canDeleteStudent(actor, student);
  }

  /// Checks if [actor] can READ the [student].
  bool canRead(AuthUser actor, StudentModel student) {
    return PermissionMatrix.canReadStudent(actor, student);
  }

  /// Legacy method: checks if actor can perform ANY mutation on student.
  /// Prefer the specific canCreate/canUpdate/canDelete methods.
  bool call(AuthUser actor, StudentModel student) {
    // For backward compatibility, this checks if actor can update the student
    return PermissionMatrix.canUpdateStudent(actor, student, student);
  }
}
