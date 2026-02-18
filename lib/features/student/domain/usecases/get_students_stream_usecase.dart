import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/domain/repos/i_student_repository.dart';

/// Returns a real-time [Stream] of students filtered by the
/// actor's role and optional team filter.
class GetStudentsStreamUseCase {
  final IStudentRepository _repository;

  const GetStudentsStreamUseCase(this._repository);

  /// Returns a stream or `null` if the actor has no access.
  Stream<List<StudentModel>>? call({required AuthUser actor, String? teamId}) {
    switch (actor.role) {
      case UserRole.admin:
        if (teamId != null && teamId.isNotEmpty) {
          return _repository.watchStudentsByClass(teamId);
        }
        return _repository.watchAllStudents();

      case UserRole.servant:
        final assignedTeamIds = actor.effectiveAssignedTeamIds;
        if (assignedTeamIds.isNotEmpty) {
          if (teamId != null && teamId.isNotEmpty) {
            if (!assignedTeamIds.contains(teamId)) return null;
            return _repository.watchStudentsByClass(teamId);
          }
          if (assignedTeamIds.length == 1) {
            return _repository.watchStudentsByClass(assignedTeamIds.first);
          }
          return _repository.watchStudentsByClasses(assignedTeamIds);
        }
        final groupId = actor.groupId;
        if (groupId == null || groupId.isEmpty) return null;
        return _repository.watchStudentsByGroup(groupId);

      case UserRole.student:
        return null;
    }
  }
}
