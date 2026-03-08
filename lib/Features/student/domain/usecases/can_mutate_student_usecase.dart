import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';

/// Checks whether the given [actor] has permission to
/// create, update, or delete the given [student].
class CanMutateStudentUseCase {
  const CanMutateStudentUseCase();

  bool call(AuthUser actor, StudentModel student) {
    if (actor.role == UserRole.admin) return true;
    if (actor.role == UserRole.servant) {
      final assignedTeamIds = actor.effectiveAssignedTeamIds;
      if (assignedTeamIds.isNotEmpty) {
        return assignedTeamIds.contains(student.classId);
      }
      return actor.groupId != null && student.group.name == actor.groupId;
    }
    return false;
  }
}
