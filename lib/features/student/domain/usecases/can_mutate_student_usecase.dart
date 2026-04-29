import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';

/// Checks whether the given [actor] has permission to
/// create, update, or delete the given [student].
class CanMutateStudentUseCase {
  const CanMutateStudentUseCase();

  /// Checks if [actor] can CREATE the [student].
  bool canCreate(AuthUser actor, StudentModel student) {
    return actor.role == UserRole.admin;
  }

  /// Checks if [actor] can UPDATE [existing] to [updated].
  bool canUpdate(AuthUser actor, StudentModel existing, StudentModel updated) {
    if (actor.role == UserRole.admin) return true;
    if (actor.role == UserRole.servant) {
      final inScope =
          actor.effectiveAssignedTeamIds.contains(existing.classId) ||
          actor.effectiveAssignedTeamIds.contains(existing.teamName) ||
          actor.groupId == existing.group.name;
      if (!inScope) return false;

      // STRICT ALLOWLIST: Servants can only mutate basic contact/profile info.
      // Any attempt to change role, team, group, or system aggregates will fail.
      final allowedMutation = existing.copyWith(
        name: updated.name,
        mobile: updated.mobile,
        motherPhone: updated.motherPhone,
        fatherPhone: updated.fatherPhone,
        school: updated.school,
        address: updated.address,
        birthdate: updated.birthdate,
        fatherOfConfession: updated.fatherOfConfession,
        notes: updated.notes,
        imageUrl: updated.imageUrl,
      );

      return updated == allowedMutation;
    }
    return false;
  }

  /// Checks if [actor] can DELETE the [student].
  bool canDelete(AuthUser actor, StudentModel student) {
    return actor.role == UserRole.admin;
  }

  /// Checks if [actor] can READ the [student].
  bool canRead(AuthUser actor, StudentModel student) {
    return actor.role == UserRole.admin || actor.role == UserRole.servant;
  }

  /// Legacy method: checks if actor can perform ANY mutation on student.
  /// Prefer the specific canCreate/canUpdate/canDelete methods.
  @Deprecated(
    'Use specific canCreate, canUpdate, or canDelete methods instead.',
  )
  bool call(AuthUser actor, StudentModel student) {
    return canUpdate(actor, student, student);
  }
}
